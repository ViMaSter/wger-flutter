/*
 * This file is part of wger Workout Manager <https://github.com/wger-project>.
 * Copyright (c)  2026 wger Team
 *
 * wger Workout Manager is free software: you can redistribute it and/or modify
 * it under the terms of the GNU Affero General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU Affero General Public License for more details.
 *
 * You should have received a copy of the GNU Affero General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';
import 'package:wger/core/network/auth_notifier.dart';
import 'package:wger/core/network/auth_state.dart';
import 'package:wger/core/shared_preferences.dart';
import 'package:wger/features/routines/models/weight_profile.dart';
import 'package:wger/features/routines/providers/available_weights_notifier.dart';
import 'package:wger/features/routines/providers/weight_profiles_notifier.dart';
import 'package:wger/features/routines/providers/weight_profiles_repository.dart';

import '../../../helpers/fake_auth_notifier.dart';
import 'weight_profiles_notifier_test.mocks.dart';

@GenerateMocks([WeightProfilesRepository])
void main() {
  setUp(() {
    SharedPreferencesAsyncPlatform.instance = InMemorySharedPreferencesAsync.empty();
  });

  const cable = WeightProfile(
    id: 'cable',
    name: 'Cable',
    kind: WeightProfileKind.linear,
    base: 1.25,
    step: 2.5,
    max: 48.75,
    bonus: [0.625, 0.625],
  );

  test('the older per-exercise weights become an assigned fixed profile each', () async {
    const legacy = '{"7": [1.25, 2.5], "9": [20]}';
    await PreferenceHelper.asyncPref.setString(PREFS_AVAILABLE_WEIGHTS, legacy);

    final state = await ProviderContainer.test().read(weightProfilesProvider.future);

    expect(state.profiles, hasLength(2));
    final seven = state.profileFor(7)!;
    expect(seven.kind, WeightProfileKind.fixed);
    expect(seven.fixed, [1.25, 2.5]);
    expect(state.profileFor(9)!.fixed, [20]);
    expect(state.profileFor(8), isNull);
    // The old key stays, the migration is stored and not repeated
    expect(await PreferenceHelper.asyncPref.getString(PREFS_AVAILABLE_WEIGHTS), legacy);
    expect(await PreferenceHelper.asyncPref.getString(PREFS_WEIGHT_PROFILES), isNotNull);
  });

  test('a migration runs once, deleting every profile keeps them deleted', () async {
    await PreferenceHelper.asyncPref.setString(PREFS_AVAILABLE_WEIGHTS, '{"7": [5]}');
    final container = ProviderContainer.test();
    final notifier = container.read(weightProfilesProvider.notifier);
    final migrated = await container.read(weightProfilesProvider.future);

    await notifier.deleteProfile(migrated.profiles.single.id);

    expect((await ProviderContainer.test().read(weightProfilesProvider.future)).profiles, isEmpty);
  });

  test('without any stored weights there are no profiles', () async {
    final state = await ProviderContainer.test().read(weightProfilesProvider.future);

    expect(state.profiles, isEmpty);
    expect(state.assignments, isEmpty);
  });

  test('profiles and assignments are stored and read back', () async {
    final container = ProviderContainer.test();
    final notifier = container.read(weightProfilesProvider.notifier);

    await notifier.upsertProfile(cable);
    await notifier.assign(3, 'cable');
    await notifier.assign(4, 'cable');
    await notifier.upsertProfile(cable.copyWith(name: 'Left cable'));

    final reloaded = await ProviderContainer.test().read(weightProfilesProvider.future);
    expect(reloaded.profiles, [cable.copyWith(name: 'Left cable')]);
    expect(reloaded.assignments, {3: 'cable', 4: 'cable'});
    expect(await notifier.profileFor(3), cable.copyWith(name: 'Left cable'));
  });

  test('assigning null removes the assignment', () async {
    final container = ProviderContainer.test();
    final notifier = container.read(weightProfilesProvider.notifier);
    await notifier.upsertProfile(cable);
    await notifier.assign(3, 'cable');

    await notifier.assign(3, null);

    expect(await notifier.profileFor(3), isNull);
    expect((await ProviderContainer.test().read(weightProfilesProvider.future)).assignments, {});
  });

  test('deleting a profile drops its assignments, others stay', () async {
    final container = ProviderContainer.test();
    final notifier = container.read(weightProfilesProvider.notifier);
    final bar = WeightProfile.defaultPlates(id: 'bar', name: 'Bar');
    await notifier.upsertProfile(cable);
    await notifier.upsertProfile(bar);
    await notifier.assign(3, 'cable');
    await notifier.assign(5, 'bar');

    await notifier.deleteProfile('cable');

    final reloaded = await ProviderContainer.test().read(weightProfilesProvider.future);
    expect(reloaded.profiles, [bar]);
    expect(reloaded.assignments, {5: 'bar'});
  });

  test('unreadable stored data starts over empty', () async {
    await PreferenceHelper.asyncPref.setString(PREFS_WEIGHT_PROFILES, 'not json');

    expect((await ProviderContainer.test().read(weightProfilesProvider.future)).profiles, isEmpty);
  });

  group('on the server', () {
    late MockWeightProfilesRepository repository;
    final storedAt = DateTime.utc(2026, 11, 26, 3);
    const rack = WeightProfile(
      id: 'rack',
      name: 'Dumbbells',
      kind: WeightProfileKind.fixed,
      fixed: [20, 30],
      pair: true,
    );
    const remote = WeightProfilesState(profiles: [rack], assignments: {7: 'rack'});

    setUp(() {
      repository = MockWeightProfilesRepository();
      when(repository.available).thenReturn(true);
      when(repository.push(any)).thenAnswer((_) async => storedAt);
    });

    ProviderContainer loggedIn() => ProviderContainer.test(
      overrides: [
        weightProfilesRepositoryProvider.overrideWithValue(repository),
        authProvider.overrideWith(
          () => FakeAuthNotifier(
            const AuthState(status: AuthStatus.loggedIn, serverUrl: 'https://wger.example'),
          ),
        ),
      ],
    );

    /// Builds the profiles and lets the sync after the login run
    Future<WeightProfilesState> opened(ProviderContainer container) async {
      container.read(authProvider);
      await container.read(weightProfilesProvider.future);
      await container.read(authProvider.future);
      await pumpEventQueue();
      return container.read(weightProfilesProvider.future);
    }

    test('a fresh install takes over what the server has', () async {
      when(repository.fetch()).thenAnswer((_) async => (updatedAt: storedAt, state: remote));

      final state = await opened(loggedIn());

      expect(state, remote);
      verifyNever(repository.push(any));
      // Also there for the next start, offline
      final restarted = await ProviderContainer.test().read(weightProfilesProvider.future);
      expect(restarted.profileFor(7)!.pair, isTrue);
    });

    test('a change is sent as a whole', () async {
      when(repository.fetch()).thenAnswer((_) async => (updatedAt: null, state: null));
      final container = loggedIn();
      await opened(container);

      await container.read(weightProfilesProvider.notifier).upsertProfile(rack);
      await pumpEventQueue();

      final sent = verify(repository.push(captureAny)).captured.single as WeightProfilesState;
      expect(sent.profiles.single, rack);
      expect(await PreferenceHelper.asyncPref.getBool(PREFS_WEIGHT_PROFILES_UNSENT), isFalse);
    });

    test('a change the server did not get is sent on the next login, not overwritten', () async {
      when(repository.fetch()).thenAnswer((_) async => (updatedAt: null, state: null));
      when(repository.push(any)).thenThrow(Exception('offline'));
      final first = loggedIn();
      await opened(first);
      await first.read(weightProfilesProvider.notifier).upsertProfile(cable);
      await pumpEventQueue();
      expect(await PreferenceHelper.asyncPref.getBool(PREFS_WEIGHT_PROFILES_UNSENT), isTrue);

      // Meanwhile the server has an older version
      when(repository.fetch()).thenAnswer((_) async => (updatedAt: storedAt, state: remote));
      when(repository.push(any)).thenAnswer((_) async => storedAt);
      final state = await opened(loggedIn());

      expect(state.profiles.single, cable);
      final sent = verify(repository.push(captureAny)).captured.last as WeightProfilesState;
      expect(sent.profiles.single, cable);
    });

    test('the version in sync is not taken over again', () async {
      when(repository.fetch()).thenAnswer((_) async => (updatedAt: storedAt, state: remote));
      final first = loggedIn();
      await opened(first);
      await first.read(weightProfilesProvider.notifier).deleteProfile('rack');
      await pumpEventQueue();

      // The server answers the push with the same time in this test
      final state = await opened(loggedIn());

      expect(state.profiles, isEmpty);
    });

    test('a server without the endpoint changes nothing', () async {
      when(repository.fetch()).thenAnswer((_) async => null);
      await PreferenceHelper.asyncPref.setString(
        PREFS_WEIGHT_PROFILES,
        '{"profiles": [], "assignments": {}}',
      );

      final state = await opened(loggedIn());

      expect(state.profiles, isEmpty);
      verifyNever(repository.push(any));
    });

    test('nothing is fetched while logged out', () async {
      final state = await ProviderContainer.test(
        overrides: [
          weightProfilesRepositoryProvider.overrideWithValue(repository),
          authProvider.overrideWith(() => FakeAuthNotifier(const AuthState())),
        ],
      ).read(weightProfilesProvider.future);

      expect(state.profiles, isEmpty);
      verifyNever(repository.fetch());
    });
  });
}
