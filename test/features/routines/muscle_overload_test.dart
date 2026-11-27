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

import 'package:flutter_test/flutter_test.dart';
import 'package:wger/features/routines/models/muscle_overload_plan.dart';
import 'package:wger/features/routines/models/overload_option.dart';
import 'package:wger/features/routines/muscle_overload.dart';

List<OverloadSet> sets(int count, num reps, num? weight) => [
  for (var i = 0; i < count; i++) OverloadSet(weight: weight, repetitions: reps),
];

List<num> steps(num from, num to, num step) => [for (var w = from; w <= to; w += step) w];

void main() {
  group('muscleVolumes', () {
    test('adds the whole volume of an exercise to each of its muscle groups', () {
      final volumes = muscleVolumes([
        (muscles: ['Chest', 'Triceps'], sets: sets(2, 10, 50)),
        (muscles: ['Triceps'], sets: sets(3, 12, 10)),
        (muscles: ['Abs'], sets: sets(2, 20, null)),
      ]);

      expect(volumes, {'Chest': 1000, 'Triceps': 1360, 'Abs': 40});
    });
  });

  group('matchSession', () {
    test('takes the session overlapping the most, the newest on a tie', () {
      final today = {'Chest', 'Shoulders', 'Triceps'};
      final candidates = [
        {'Lats', 'Biceps'},
        {'Chest', 'Shoulders'},
        {'Glutes', 'Quads'},
        {'Chest', 'Triceps'},
      ];

      expect(matchSession(today, candidates), 1);
    });

    test('is null when no session shares a muscle group', () {
      expect(
        matchSession(
          {'Chest'},
          [
            {'Lats'},
            {'Quads'},
          ],
        ),
        isNull,
      );
    });
  });

  group('planMuscleOverload', () {
    // Shaped like a high-volume phase after a heavy one: two sets of a fixed
    // number of repetitions, compared with a session of more, heavier sets
    test('spreads the increase over the exercises of a muscle group', () {
      final plan = planMuscleOverload(
        baseline: {'Chest': 1285},
        entries: [
          MuscleEntry(
            slotEntryId: 1,
            muscles: const ['Chest'],
            lastSession: sets(2, 12, 35),
            minReps: 12,
            plannedSets: 2,
            knownWeights: steps(30, 60, 2.5),
          ),
          MuscleEntry(
            slotEntryId: 2,
            muscles: const ['Chest'],
            lastSession: sets(2, 15, 10),
            minReps: 15,
            plannedSets: 2,
            knownWeights: steps(5, 30, 2.5),
          ),
        ],
      );

      // 35 → 37.5 (+60), 10 → 12.5 (+75), then 37.5 → 40, never one of them
      // twice in a row
      expect(plan.options[1]!.sets, sets(2, 12, 40));
      expect(plan.options[2]!.sets, sets(2, 15, 12.5));
      expect(plan.options[1]!.type, OverloadType.muscleGroup);
      final chest = plan.targets.single;
      expect(chest.start, 1140);
      expect(chest.planned, 1335);
      expect(chest.reached, isTrue);
    });

    test('needs strictly more than the compared session, not as much', () {
      final plan = planMuscleOverload(
        baseline: {'Lats': 500},
        entries: [
          MuscleEntry(
            slotEntryId: 1,
            muscles: const ['Lats'],
            lastSession: sets(4, 6, 20),
            minReps: 6,
            maxReps: 8,
            plannedSets: 4,
            maxSets: 6,
          ),
        ],
      );

      // 480 → 500 is only as much, one more repetition beats it
      expect(plan.options[1]!.volume, 520);
      expect(plan.targets.single.reached, isTrue);
      for (final set in plan.options[1]!.sets) {
        expect(set.repetitions, inInclusiveRange(6, 8));
        expect(set.weight, 20);
      }
    });

    test('stays within the ranges and reports what is still missing', () {
      final plan = planMuscleOverload(
        baseline: {'Quads': 2725},
        entries: [
          MuscleEntry(
            slotEntryId: 1,
            muscles: const ['Quads'],
            lastSession: sets(2, 8, 6),
            minReps: 8,
            plannedSets: 2,
            knownWeights: steps(2, 40, 2),
          ),
        ],
      );

      // A fixed 2 × 8, and at most three weights beyond the start: 6 → 12
      expect(plan.options[1]!.sets, sets(2, 8, 12));
      final quads = plan.targets.single;
      expect(quads.reached, isFalse);
      expect(quads.gap, 2725 - 192);
    });

    test('raises an exercise of several muscle groups for the one behind', () {
      final plan = planMuscleOverload(
        baseline: {'Glutes': 1000, 'Quads': 2400},
        entries: [
          MuscleEntry(
            slotEntryId: 1,
            muscles: const ['Glutes', 'Quads'],
            lastSession: sets(2, 20, 50),
            minReps: 20,
            plannedSets: 2,
            knownWeights: steps(40, 100, 10),
          ),
        ],
      );

      expect(plan.options[1]!.sets, sets(2, 20, 70));
      expect(plan.targets.every((t) => t.reached), isTrue);
      expect(plan.targets.map((t) => t.planned), everyElement(2800));
    });

    test('starts without a last session from the planned weight', () {
      final plan = planMuscleOverload(
        baseline: {'Shoulders': 100},
        entries: const [
          MuscleEntry(
            slotEntryId: 1,
            muscles: ['Shoulders'],
            plannedWeight: 5,
            minReps: 12,
            plannedSets: 2,
          ),
        ],
      );

      expect(plan.options[1]!.sets, sets(2, 12, 5));
    });

    test('only compares the muscle groups trained in both sessions', () {
      final plan = planMuscleOverload(
        baseline: {'Chest': 100, 'Lats': 5000},
        entries: [
          MuscleEntry(
            slotEntryId: 1,
            muscles: const ['Chest'],
            lastSession: sets(1, 10, 20),
            minReps: 10,
            plannedSets: 1,
          ),
          MuscleEntry(
            slotEntryId: 2,
            muscles: const ['Trapezius'],
            lastSession: sets(1, 10, 20),
            minReps: 10,
            plannedSets: 1,
          ),
        ],
      );

      expect(plan.targets.map((t) => t.muscle), ['Chest']);
    });
  });
}
