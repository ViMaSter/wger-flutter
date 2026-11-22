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
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';
import 'package:wger/core/shared_preferences.dart';
import 'package:wger/features/routines/models/weight_profile.dart';
import 'package:wger/features/routines/providers/available_weights_notifier.dart';
import 'package:wger/features/routines/providers/weight_profiles_notifier.dart';

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
}
