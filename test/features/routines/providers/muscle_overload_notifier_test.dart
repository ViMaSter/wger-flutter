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
import 'package:wger/core/consts.dart';
import 'package:wger/features/exercises/models/category.dart';
import 'package:wger/features/exercises/models/exercise.dart';
import 'package:wger/features/exercises/models/muscle.dart';
import 'package:wger/features/exercises/providers/exercise_repository.dart';
import 'package:wger/features/exercises/providers/exercises_notifier.dart';
import 'package:wger/features/routines/models/log.dart';
import 'package:wger/features/routines/models/muscle_overload_plan.dart';
import 'package:wger/features/routines/models/overload_option.dart';
import 'package:wger/features/routines/models/set_config_data.dart';
import 'package:wger/features/routines/providers/muscle_overload_notifier.dart';
import 'package:wger/features/routines/providers/workout_logs_repository.dart';

import 'muscle_overload_notifier_test.mocks.dart';

const _category = ExerciseCategory(id: 1, name: 'Arms');

Exercise _exercise(int id, String muscle) => Exercise(
  id: id,
  uuid: 'uuid-$id',
  category: _category,
  muscles: [Muscle(id: id, name: muscle, nameEn: muscle, isFront: true)],
);

final _chestPress = _exercise(10, 'Chest');
final _lateralRaise = _exercise(11, 'Shoulders');
final _pulldown = _exercise(20, 'Lats');

@GenerateMocks([WorkoutLogRepository, ExerciseRepository])
void main() {
  // The new routine starts on a Sunday, the first workout is on Monday
  final routineStart = DateTime(2026, 11, 29);
  final before = DateTime(2026, 11, 30, 18);
  late MockWorkoutLogRepository repo;
  late ProviderContainer container;

  Log log(int exerciseId, num reps, num weight, DateTime date, {String? session, int? routine}) =>
      Log(
        exerciseId: exerciseId,
        repetitions: reps,
        weight: weight,
        weightUnitId: WEIGHT_UNIT_KG,
        repetitionsUnitId: REP_UNIT_REPETITIONS_ID,
        sessionId: session,
        routineId: routine,
        date: date,
      );

  // The sessions of the previous programme: the push day is older than the
  // pull day but is the one today's push day is compared with
  final pushDay = DateTime.utc(2026, 11, 21, 17);
  final pullDay = DateTime.utc(2026, 11, 22, 17);
  final previousSessions = [
    [for (var i = 0; i < 4; i++) log(20, 6, 60, pullDay, session: 'pull', routine: 2)],
    [
      for (var i = 0; i < 4; i++) log(10, 5, 45, pushDay, session: 'push', routine: 2),
      for (var i = 0; i < 4; i++) log(11, 8, 4, pushDay, session: 'push', routine: 2),
    ],
  ];

  SetConfigData config(Exercise exercise, int slotEntryId, {num reps = 12}) => SetConfigData(
    exerciseId: exercise.id,
    exercise: exercise,
    slotEntryId: slotEntryId,
    nrOfSets: 2,
    repetitions: reps,
  );

  final todaysPushDay = PlannedEntries([
    (config: config(_chestPress, 1), plannedSets: 2),
    (config: config(_lateralRaise, 2), plannedSets: 2),
    // A stretch, one "repetition", stays out
    (config: config(_lateralRaise, 3, reps: 1), plannedSets: 1),
  ]);

  setUp(() {
    SharedPreferencesAsyncPlatform.instance = InMemorySharedPreferencesAsync.empty();
    repo = MockWorkoutLogRepository();
    final exerciseRepo = MockExerciseRepository();
    when(exerciseRepo.watchAllDrift()).thenAnswer(
      (_) => Stream.value(ExerciseState([_chestPress, _lateralRaise, _pulldown])),
    );

    when(
      repo.hasLogsForSlotEntries(
        any,
        any,
        since: anyNamed('since'),
        before: anyNamed('before'),
      ),
    ).thenAnswer((_) async => false);
    when(
      repo.getSessionsBefore(
        before: anyNamed('before'),
        excludeRoutineId: anyNamed('excludeRoutineId'),
        excludeSince: anyNamed('excludeSince'),
      ),
    ).thenAnswer((_) async => previousSessions);

    // The chest press is in both programmes: last done heavy in the previous
    // one, before that with today's repetitions in the previous run of this
    // routine, which is where it starts
    final lastRun = DateTime.utc(2026, 7, 16, 17);
    when(repo.getLastSessionLogsByExercise(10, before: anyNamed('before'))).thenAnswer(
      (_) async => [log(10, 5, 60, pushDay), log(10, 5, 60, pushDay)],
    );
    when(
      repo.getLastSessionLogsByExercise(10, before: anyNamed('before'), routineId: 4),
    ).thenAnswer((_) async => [log(10, 12, 35, lastRun), log(10, 12, 35, lastRun)]);
    // The lateral raise was never done in this routine: its last time anywhere
    when(
      repo.getLastSessionLogsByExercise(11, before: anyNamed('before')),
    ).thenAnswer((_) async => [log(11, 12, 3, lastRun), log(11, 12, 3, lastRun)]);
    when(
      repo.getLastSessionLogsByExercise(11, before: anyNamed('before'), routineId: 4),
    ).thenAnswer((_) async => []);
    when(
      repo.getDistinctWeightsByExercise(10, weightUnitId: anyNamed('weightUnitId')),
    ).thenAnswer((_) async => [for (var w = 30.0; w <= 60; w += 2.5) w]);
    when(
      repo.getDistinctWeightsByExercise(11, weightUnitId: anyNamed('weightUnitId')),
    ).thenAnswer((_) async => [2, 3, 4, 5, 6]);

    container = ProviderContainer.test(
      overrides: [
        workoutLogRepositoryProvider.overrideWithValue(repo),
        exerciseRepositoryProvider.overrideWithValue(exerciseRepo),
      ],
    );
  });

  Future<MuscleOverloadPlan?> read() => container.read(
    muscleOverloadPlanProvider(
      routineId: 4,
      routineStart: routineStart,
      before: before,
      entries: todaysPushDay,
    ).future,
  );

  test('compares the first session of a day with the most similar one before it', () async {
    final plan = await read();

    expect(plan, isNotNull);
    expect(plan!.baselineDate, pushDay);
    expect(plan.baselineRoutineId, 2);
    // Chest 4 × 5 × 45 = 900 against 2 × 12 × 35 = 840, shoulders 128
    // against 72: every set of both exercises gets heavier, chest to 40 as
    // 37.5 is only as much
    expect({for (final t in plan.targets) t.muscle: t.baseline}, {'Chest': 900, 'Shoulders': 128});
    expect(plan.options.keys, unorderedEquals([1, 2]));
    expect(plan.options[1]!.type, OverloadType.muscleGroup);
    expect(plan.options[1]!.sets.map((s) => s.weight).toSet(), {40});
    expect(plan.options[2]!.sets.map((s) => s.weight).toSet(), {6});
    expect(plan.targets.map((t) => t.reached), everyElement(isTrue));
  });

  test('leaves out the current run of the routine from its start day on', () async {
    await read();

    final sessionsCall = verify(
      repo.getSessionsBefore(
        before: captureAnyNamed('before'),
        excludeRoutineId: captureAnyNamed('excludeRoutineId'),
        excludeSince: captureAnyNamed('excludeSince'),
      ),
    ).captured;
    expect(sessionsCall, [before, 4, DateTime(2026, 11, 29)]);
    final trainedCall = verify(
      repo.hasLogsForSlotEntries(
        4,
        captureAny,
        since: captureAnyNamed('since'),
        before: captureAnyNamed('before'),
      ),
    ).captured;
    expect(trainedCall, [
      [1, 2, 3],
      DateTime(2026, 11, 29),
      before,
    ]);
  });

  test('is null once the day was trained since the routine started', () async {
    when(
      repo.hasLogsForSlotEntries(
        any,
        any,
        since: anyNamed('since'),
        before: anyNamed('before'),
      ),
    ).thenAnswer((_) async => true);

    expect(await read(), isNull);
  });

  test('is null without anything trained before', () async {
    when(
      repo.getSessionsBefore(
        before: anyNamed('before'),
        excludeRoutineId: anyNamed('excludeRoutineId'),
        excludeSince: anyNamed('excludeSince'),
      ),
    ).thenAnswer((_) async => []);

    expect(await read(), isNull);
  });
}
