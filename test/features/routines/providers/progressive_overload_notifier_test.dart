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
import 'package:wger/features/routines/models/log.dart';
import 'package:wger/features/routines/models/overload_option.dart';
import 'package:wger/features/routines/models/weight_profile.dart';
import 'package:wger/features/routines/providers/progressive_overload_notifier.dart';
import 'package:wger/features/routines/providers/weight_profiles_notifier.dart';
import 'package:wger/features/routines/providers/workout_logs_repository.dart';

import 'progressive_overload_notifier_test.mocks.dart';

@GenerateMocks([WorkoutLogRepository])
void main() {
  final before = DateTime.utc(2026, 4, 15, 10);
  late MockWorkoutLogRepository repo;
  late ProviderContainer container;

  setUp(() {
    SharedPreferencesAsyncPlatform.instance = InMemorySharedPreferencesAsync.empty();
    repo = MockWorkoutLogRepository();
    when(
      repo.getDistinctWeightsByExercise(any, weightUnitId: anyNamed('weightUnitId')),
    ).thenAnswer((_) async => []);
    container = ProviderContainer.test(
      overrides: [workoutLogRepositoryProvider.overrideWithValue(repo)],
    );
  });

  Log log(num reps, num? weight, {int weightUnitId = WEIGHT_UNIT_KG, int? repUnitId}) => Log(
    exerciseId: 1,
    repetitions: reps,
    weight: weight,
    weightUnitId: weightUnitId,
    repetitionsUnitId: repUnitId ?? REP_UNIT_REPETITIONS_ID,
  );

  Future<OverloadSuggestions> read({num? minReps, num? maxReps, int? plannedSets}) =>
      container.read(
        overloadSuggestionsProvider(
          exerciseId: 1,
          before: before,
          minReps: minReps,
          maxReps: maxReps,
          plannedSets: plannedSets,
        ).future,
      );

  Future<void> assignFixed(List<num> weights) async {
    final notifier = container.read(weightProfilesProvider.notifier);
    await notifier.upsertProfile(
      WeightProfile(id: 'p', name: 'p', kind: WeightProfileKind.fixed, fixed: weights),
    );
    await notifier.assign(1, 'p');
  }

  test('suggests from the last session before the workout and the assigned profile', () async {
    when(
      repo.getLastSessionLogsByExercise(1, before: before),
    ).thenAnswer((_) async => [log(10, 20), log(10, 20)]);
    await assignFixed([25]);

    final suggestions = await read(minReps: 8, maxReps: 12);

    expect(suggestions.lastSession, hasLength(2));
    expect(suggestions.hasAvailableWeights, isTrue);
    expect(suggestions.options.map((o) => o.type), [
      OverloadType.moreReps,
      OverloadType.heavier,
      OverloadType.moreSets,
    ]);
    // 400 / 25 = 16 exactly, one more to beat it
    expect(suggestions.options[1].sets, [
      const OverloadSet(weight: 25, repetitions: 9),
      const OverloadSet(weight: 25, repetitions: 8),
    ]);
    expect(suggestions.profile?.id, 'p');
  });

  test('known weights are the profile and those logged in the unit of the last set', () async {
    when(repo.getLastSessionLogsByExercise(1, before: before)).thenAnswer(
      (_) async => [
        log(6, 17.5),
        log(6, 22.5),
        log(6, 22.5),
        log(6, 22.5),
        log(6, 17.5),
      ],
    );
    when(
      repo.getDistinctWeightsByExercise(1, weightUnitId: WEIGHT_UNIT_KG),
    ).thenAnswer((_) async => [1.88, 17.5, 22.5]);
    await assignFixed([1.875, 27.5]);

    final suggestions = await read(minReps: 4, maxReps: 6, plannedSets: 4);

    // 1.88 is the logged 1.875 of the profile
    expect(suggestions.knownWeights, [1.875, 17.5, 22.5, 27.5]);
    expect(suggestions.baselineVolume, 510);
    expect(suggestions.hasAvailableWeights, isTrue);
    final heavier = suggestions.options.where((o) => o.type == OverloadType.heavier).toList();
    expect(heavier.first.sets.map((s) => (s.weight, s.repetitions)), [
      (22.5, 6),
      (22.5, 6),
      (22.5, 6),
      (22.5, 5),
    ]);
  });

  test('without a profile the logged weights still give heavier options', () async {
    when(
      repo.getLastSessionLogsByExercise(1, before: before),
    ).thenAnswer((_) async => [log(8, 33), log(8, 33), log(8, 33), log(8, 33)]);
    when(
      repo.getDistinctWeightsByExercise(1, weightUnitId: WEIGHT_UNIT_KG),
    ).thenAnswer((_) async => [33, 40]);

    final suggestions = await read(minReps: 6, maxReps: 8);

    expect(suggestions.hasAvailableWeights, isFalse);
    expect(
      suggestions.options.where((o) => o.type == OverloadType.heavier).single.sets.first.weight,
      40,
    );
  });

  test('without history or weights there is nothing to suggest', () async {
    when(repo.getLastSessionLogsByExercise(1, before: before)).thenAnswer((_) async => []);

    final suggestions = await read();

    expect(suggestions.lastSession, isEmpty);
    expect(suggestions.options, isEmpty);
    expect(suggestions.hasAvailableWeights, isFalse);
  });

  group('comparableSets', () {
    test('drops sets in other units than repetitions and the last weight unit', () {
      final logs = [
        log(10, 45, weightUnitId: WEIGHT_UNIT_LB),
        log(30, null, repUnitId: 99),
        log(10, 20),
        log(12, null),
        log(8, 22.5),
      ];

      expect(comparableSets(logs).map((l) => (l.repetitions, l.weight)), [
        (10, 20),
        (12, null),
        (8, 22.5),
      ]);
    });

    test('drops sets without repetitions', () {
      expect(comparableSets([Log(exerciseId: 1, weight: 20), log(0, 20)]), isEmpty);
    });
  });
}
