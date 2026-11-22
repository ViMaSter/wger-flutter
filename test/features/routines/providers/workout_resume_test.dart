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

import 'dart:convert';

import 'package:clock/clock.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';
import 'package:wger/core/shared_preferences.dart';
import 'package:wger/features/routines/models/workout_progress.dart';
import 'package:wger/features/routines/notifications/workout_notification_controller.dart';
import 'package:wger/features/routines/notifications/workout_notification_service.dart';
import 'package:wger/features/routines/providers/workout_resume.dart';
import 'package:wger/features/routines/screens/gym_mode.dart';

import 'workout_resume_test.mocks.dart';

@GenerateMocks([WorkoutNotificationService])
void main() {
  final now = DateTime.utc(2026, 11, 22, 10);

  setUp(() {
    SharedPreferencesAsyncPlatform.instance = InMemorySharedPreferencesAsync.empty();
  });

  Future<void> store({
    int doneSets = 1,
    int doneAddedSets = 0,
    int? totalSets = 3,
    int? routineId = 7,
    Duration validFor = const Duration(hours: 1),
  }) async {
    final progress = WorkoutProgress(
      dayId: 2,
      iteration: 4,
      currentPageKey: 'timer:1:1',
      workoutStart: now,
      validUntil: now.add(validFor),
      routineId: routineId,
      totalSets: totalSets,
      pages: {
        for (var i = 1; i <= doneSets; i++) 'log:1:$i': const StoredPageProgress(done: true),
        for (var i = 1; i <= doneAddedSets; i++)
          'added:1:log:$i': const StoredPageProgress(done: true),
        'timer:1:1': StoredPageProgress(timerStartedAt: now),
      },
    );
    await PreferenceHelper.asyncPref.setString(
      PREFS_WORKOUT_PROGRESS,
      json.encode(progress.toJson()),
    );
  }

  Future<ResumableWorkout?> resume() => withClock(Clock.fixed(now), workoutToResume);

  test('nothing to continue without stored progress', () async {
    expect(await resume(), isNull);
  });

  test('continues a running workout with sets left', () async {
    await store(doneSets: 2);

    expect(await resume(), (routineId: 7, dayId: 2, iteration: 4));
    expect(await PreferenceHelper.asyncPref.getString(PREFS_WORKOUT_PROGRESS), isNotNull);
  });

  test('a finished workout starts the app normally and is forgotten', () async {
    await store(doneSets: 3);

    expect(await resume(), isNull);
    expect(await PreferenceHelper.asyncPref.getString(PREFS_WORKOUT_PROGRESS), isNull);
  });

  test('sets of an added exercise do not make up for planned ones', () async {
    await store(doneSets: 2, doneAddedSets: 2);

    expect(await resume(), (routineId: 7, dayId: 2, iteration: 4));
  });

  test('a workout without a logged set is not continued', () async {
    await store(doneSets: 0);

    expect(await resume(), isNull);
  });

  test('an expired workout is not continued', () async {
    await store(validFor: const Duration(minutes: -1));

    expect(await resume(), isNull);
  });

  test('progress of an older version without the routine is not continued', () async {
    await store(routineId: null);
    expect(await resume(), isNull);

    await store(totalSets: null);
    expect(await resume(), isNull);
  });

  group('continueInterruptedWorkout', () {
    Future<List<GymModeArguments>> pumpHome(WidgetTester tester, {bool gymOpen = false}) async {
      final opened = <GymModeArguments>[];
      final service = MockWorkoutNotificationService();
      when(service.takeLaunchPayload()).thenAnswer((_) async => null);
      final container = ProviderContainer.test(
        overrides: [workoutNotificationServiceProvider.overrideWithValue(service)],
      );
      container.read(gymModeVisibleProvider.notifier).set(gymOpen);
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            onGenerateRoute: (settings) => MaterialPageRoute<void>(
              settings: settings,
              builder: (_) {
                if (settings.name == GymModeScreen.routeName) {
                  opened.add(settings.arguments! as GymModeArguments);
                  return const Text('gym mode');
                }
                return Consumer(
                  builder: (context, ref, _) => TextButton(
                    onPressed: () => continueInterruptedWorkout(context, ref),
                    child: const Text('home'),
                  ),
                );
              },
            ),
          ),
        ),
      );
      await tester.runAsync(() async {
        await tester.tap(find.text('home'));
        await Future<void>.delayed(const Duration(milliseconds: 50));
      });
      await tester.pumpAndSettle();
      return opened;
    }

    testWidgets('opens the gym mode on the interrupted workout', (tester) async {
      await tester.runAsync(() => store(validFor: const Duration(days: 3650)));

      final opened = await pumpHome(tester);

      expect(opened.map((a) => (a.routineId, a.dayId, a.iteration)), [(7, 2, 4)]);
      expect(find.text('gym mode'), findsOneWidget);
    });

    testWidgets('stays home without a workout to continue', (tester) async {
      final opened = await pumpHome(tester);

      expect(opened, isEmpty);
      expect(find.text('home'), findsOneWidget);
    });

    testWidgets('does not open the gym mode a second time', (tester) async {
      await tester.runAsync(() => store(validFor: const Duration(days: 3650)));

      final opened = await pumpHome(tester, gymOpen: true);

      expect(opened, isEmpty);
    });
  });
}
