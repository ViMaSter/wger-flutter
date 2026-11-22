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
import 'package:wger/features/routines/models/overload_option.dart';
import 'package:wger/features/routines/progressive_overload.dart';

List<OverloadSet> sets(num? weight, List<num> reps) => [
  for (final r in reps) OverloadSet(weight: weight, repetitions: r),
];

OverloadOption? optionOf(List<OverloadOption> options, OverloadType type) =>
    options.where((o) => o.type == type).firstOrNull;

void main() {
  group('calculateOverloadOptions', () {
    test('3×10 @ 20 in 8-12 with a ladder', () {
      final options = calculateOverloadOptions(
        lastSession: sets(20, [10, 10, 10]),
        availableWeights: [15, 20, 22.5, 25, 27.5, 30],
        minReps: 8,
        maxReps: 12,
      );

      expect(options.map((o) => o.type), [
        OverloadType.moreReps,
        OverloadType.heavier,
        OverloadType.heavier,
        OverloadType.heavier,
        OverloadType.moreSets,
      ]);
      expect(options[0].sets, sets(20, [11, 10, 10]));
      // 600 / 22.5 = 26.7 -> 27 repetitions
      expect(options[1].sets, sets(22.5, [9, 9, 9]));
      // 600 / 25 = 24 exactly, one more to beat it
      expect(options[2].sets, sets(25, [9, 8, 8]));
      // 600 / 27.5 = 21.8 -> 8/7/7, raised to the minimum of the range
      expect(options[3].sets, sets(27.5, [8, 8, 8]));
      expect(options[4].sets, sets(20, [10, 10, 10, 10]));
    });

    test('every option has more volume than last time', () {
      final last = sets(20, [10, 9, 8]);
      final options = calculateOverloadOptions(
        lastSession: last,
        availableWeights: [21, 22.5, 24, 25],
        minReps: 6,
        maxReps: 12,
      );

      const lastVolume = 20 * 27;
      expect(options, isNotEmpty);
      for (final option in options) {
        expect(option.volume, greaterThan(lastVolume), reason: '$option');
      }
    });

    test('more reps goes on the set with the fewest, the first one on a tie', () {
      final uneven = calculateOverloadOptions(lastSession: sets(20, [10, 9, 8]));
      expect(optionOf(uneven, OverloadType.moreReps)!.sets, sets(20, [10, 9, 9]));

      final tie = calculateOverloadOptions(lastSession: sets(20, [9, 10, 9]));
      expect(optionOf(tie, OverloadType.moreReps)!.sets, sets(20, [10, 10, 9]));
    });

    test('no more reps option when every set is at the top of the range', () {
      final options = calculateOverloadOptions(
        lastSession: sets(20, [12, 12, 12]),
        availableWeights: [22.5],
        minReps: 8,
        maxReps: 12,
      );

      expect(optionOf(options, OverloadType.moreReps), isNull);
      // 720 / 22.5 = 32 exactly, one more to beat it
      expect(optionOf(options, OverloadType.heavier)!.sets, sets(22.5, [11, 11, 11]));
    });

    test('only the sets below the top of the range get another repetition', () {
      final options = calculateOverloadOptions(lastSession: sets(20, [12, 11, 12]), maxReps: 12);

      expect(optionOf(options, OverloadType.moreReps)!.sets, sets(20, [12, 12, 12]));
    });

    test('a heavier weight needing more than the top of the range is left out', () {
      // Last time went past the range: 840 / 22.5 = 37.3 -> 13/13/12, too many,
      // 840 / 25 = 33.6 -> 12/11/11 fits
      final options = calculateOverloadOptions(
        lastSession: sets(20, [14, 14, 14]),
        availableWeights: [22.5, 25],
        minReps: 8,
        maxReps: 12,
      );

      final heavier = options.where((o) => o.type == OverloadType.heavier).toList();
      expect(heavier.map((o) => o.sets), [
        sets(25, [12, 11, 11]),
      ]);
    });

    test('a single heavier set does not hide the next weight up', () {
      // The session from the gym: 4 sets with 30, one with 35, in 3-5
      final options = calculateOverloadOptions(
        lastSession: [
          ...sets(30, [5, 5, 5]),
          const OverloadSet(weight: 35, repetitions: 5),
          const OverloadSet(weight: 30, repetitions: 5),
        ],
        availableWeights: [30, 32.5, 35],
        minReps: 3,
        maxReps: 5,
      );

      // 775 / 32.5 = 23.8 -> 24, 775 / 35 = 22.1 -> 23
      expect(options.where((o) => o.type == OverloadType.heavier).map((o) => o.sets), [
        sets(32.5, [5, 5, 5, 5, 4]),
        sets(35, [5, 5, 5, 4, 4]),
      ]);
    });

    test('the working weight is the one most sets used, the heavier one on a tie', () {
      expect(
        workingWeight([
          ...sets(20, [10]),
          ...sets(40, [5, 5, 5]),
        ]),
        40,
      );
      expect(
        workingWeight([
          ...sets(30, [5, 5]),
          ...sets(35, [5, 5]),
        ]),
        35,
      );
      expect(workingWeight(sets(null, [10, 10])), isNull);
    });

    test('only the next weights above the lowest weight, at most maxWeightSteps', () {
      final options = calculateOverloadOptions(
        lastSession: [
          const OverloadSet(weight: 20, repetitions: 10),
          const OverloadSet(weight: 22.5, repetitions: 8),
        ],
        availableWeights: [30, 10, 22.5, 25, 27.5, 25],
        maxWeightSteps: 2,
      );

      expect(
        options.where((o) => o.type == OverloadType.heavier).map((o) => o.sets.first.weight),
        [22.5, 25],
      );
    });

    test('a non-linear cable tower ladder', () {
      final options = calculateOverloadOptions(
        lastSession: sets(2.5, [12, 12, 12]),
        availableWeights: [1.25, 1.875, 2.5, 3.75, 4.375, 5, 6.25],
        minReps: 8,
        maxReps: 15,
      );

      final heavier = options.where((o) => o.type == OverloadType.heavier).toList();
      // 90 / 3.75 = 24 -> 25, 90 / 4.375 = 20.6 -> 21, raised to 8 each,
      // 90 / 5 = 18 -> raised to 8 each
      expect(heavier.map((o) => o.sets), [
        sets(3.75, [9, 8, 8]),
        sets(4.375, [8, 8, 8]),
        sets(5, [8, 8, 8]),
      ]);
    });

    test('a weight logged with two decimals is the same as its available weight', () {
      // 1.875 on the cable tower can only be logged as 1.87 or 1.88
      for (final logged in [1.87, 1.88]) {
        final options = calculateOverloadOptions(
          lastSession: sets(logged, [12, 12]),
          availableWeights: [1.25, 1.875, 2.5],
        );

        expect(
          options.where((o) => o.type == OverloadType.heavier).map((o) => o.sets.first.weight),
          [2.5],
          reason: 'logged as $logged',
        );
      }
    });

    test('without available weights there are no heavier options', () {
      final options = calculateOverloadOptions(lastSession: sets(20, [10, 10]));

      expect(options.map((o) => o.type), [OverloadType.moreReps, OverloadType.moreSets]);
    });

    test('without a maximum, repetitions are not capped', () {
      final options = calculateOverloadOptions(lastSession: sets(20, [30]));

      expect(optionOf(options, OverloadType.moreReps)!.sets, sets(20, [31]));
    });

    test('bodyweight: only more reps and more sets, volume are the repetitions', () {
      final options = calculateOverloadOptions(
        lastSession: sets(null, [15, 12]),
        availableWeights: [5, 10],
        maxReps: 20,
      );

      expect(options.map((o) => o.type), [OverloadType.moreReps, OverloadType.moreSets]);
      expect(options.first.sets, sets(null, [15, 13]));
      expect(options.first.volume, 28);
    });

    test('the smallest option is the one with the least volume, the first on a tie', () {
      final options = calculateOverloadOptions(
        lastSession: sets(20, [10, 10]),
        availableWeights: [21],
        maxReps: 12,
      );
      // more reps 420, 21 kg 11/10 = 441, one more set 600
      expect(smallestOverloadOption(options)!.type, OverloadType.moreReps);

      final atTop = calculateOverloadOptions(
        lastSession: sets(20, [12, 12]),
        availableWeights: [22.5],
        maxReps: 12,
      );
      expect(smallestOverloadOption(atTop)!.type, OverloadType.heavier);
      expect(smallestOverloadOption([]), isNull);
    });

    test('no previous session, no options', () {
      expect(calculateOverloadOptions(lastSession: [], availableWeights: [20]), isEmpty);
    });

    test('biceps: an extra set beyond the planned ones is not part of the baseline', () {
      final options = calculateOverloadOptions(
        lastSession: [
          ...sets(17.5, [6]),
          ...sets(22.5, [6, 6, 6]),
          ...sets(17.5, [6]),
        ],
        availableWeights: [17.5, 22.5],
        minReps: 4,
        maxReps: 6,
        plannedSets: 4,
      );

      // Baseline 17.5×6 + 3×22.5×6 = 510, 510 / 22.5 = 22.7 -> 23
      final heavier = optionOf(options, OverloadType.heavier)!;
      expect(heavier.sets, sets(22.5, [6, 6, 6, 5]));
      expect(heavier.volume, 517.5);
      expect(heavier.requiredRepetitions, 23);
      // More reps on the lighter first set, more sets copies the 4th set
      expect(optionOf(options, OverloadType.moreReps), isNull);
      expect(optionOf(options, OverloadType.moreSets)!.sets, [
        ...sets(17.5, [6]),
        ...sets(22.5, [6, 6, 6, 6]),
      ]);
    });

    test('without planned sets every set of last time is the baseline', () {
      final options = calculateOverloadOptions(
        lastSession: [
          ...sets(17.5, [6]),
          ...sets(22.5, [6, 6, 6]),
          ...sets(17.5, [6]),
        ],
        availableWeights: [22.5],
        minReps: 4,
        maxReps: 6,
      );

      // 615 / 22.5 = 27.3 -> 28 over 5 sets
      expect(optionOf(options, OverloadType.heavier)!.sets, sets(22.5, [6, 6, 6, 5, 5]));
    });

    test('pec deck: 4×8 @ 33 to 40, front-loaded', () {
      final options = calculateOverloadOptions(
        lastSession: sets(33, [8, 8, 8, 8]),
        availableWeights: [40],
        minReps: 6,
        maxReps: 8,
      );

      // 1056 / 40 = 26.4 -> 27
      expect(optionOf(options, OverloadType.heavier)!.sets, sets(40, [7, 7, 7, 6]));
    });

    test('more reps works on the baseline only', () {
      final options = calculateOverloadOptions(
        lastSession: sets(20, [10, 10, 5]),
        plannedSets: 2,
        maxReps: 12,
      );

      expect(optionOf(options, OverloadType.moreReps)!.sets, sets(20, [11, 10]));
    });
  });

  group('rebalanceRemaining', () {
    test('a better first set takes repetitions off the last sets', () {
      final result = rebalanceRemaining(
        baselineVolume: 1056,
        targets: sets(40, [7, 7, 7, 6]),
        logged: {0: const OverloadSet(weight: 40, repetitions: 8)},
        minReps: 6,
        maxReps: 8,
      );

      // 1056 - 320 = 736, 736 / 40 = 18.4 -> 19 = 7/6/6
      expect(result, RebalanceFeasible(sets(40, [8, 7, 6, 6])));
    });

    test('each remaining set keeps its own weight, reduced from the back', () {
      final result = rebalanceRemaining(
        baselineVolume: 300,
        targets: [
          const OverloadSet(weight: 10, repetitions: 10),
          const OverloadSet(weight: 20, repetitions: 5),
          const OverloadSet(weight: 10, repetitions: 5),
        ],
        logged: {0: const OverloadSet(weight: 10, repetitions: 12)},
        minReps: 1,
        maxReps: 10,
      );

      // Needs more than 180 from 20×a + 10×b
      expect(result, isA<RebalanceFeasible>());
      final rows = (result as RebalanceFeasible).sets;
      expect(rows.first, const OverloadSet(weight: 10, repetitions: 12));
      expect(rows.map((s) => s.weight), [10, 20, 10]);
      expect(overloadVolume(rows), greaterThan(300));
      // One repetition less on either remaining set would not beat it
      expect(overloadVolume(rows) - 10, lessThanOrEqualTo(300));
    });

    test('a weak first set nothing can make up is infeasible, with the deficit', () {
      final result = rebalanceRemaining(
        baselineVolume: 1056,
        targets: sets(40, [7, 7, 7, 6]),
        logged: {0: const OverloadSet(weight: 40, repetitions: 4)},
        minReps: 6,
        maxReps: 8,
      );

      // 160 + 3×8×40 = 1120 > 1056 is still feasible, so take a lower bar
      expect(result, isA<RebalanceFeasible>());

      final infeasible = rebalanceRemaining(
        baselineVolume: 1300,
        targets: sets(40, [7, 7, 7, 6]),
        logged: {0: const OverloadSet(weight: 40, repetitions: 4)},
        minReps: 6,
        maxReps: 8,
      );
      // 1300 - (160 + 960) = 180
      expect(infeasible, isA<RebalanceInfeasible>());
      expect((infeasible as RebalanceInfeasible).deficit, closeTo(180, 0.001));
      expect(infeasible.deficit, greaterThan(180));
    });

    test('everything logged and short of the baseline is infeasible', () {
      final result = rebalanceRemaining(
        baselineVolume: 100,
        targets: sets(10, [5, 5]),
        logged: {
          0: const OverloadSet(weight: 10, repetitions: 5),
          1: const OverloadSet(weight: 10, repetitions: 5),
        },
      );

      expect(result, isA<RebalanceInfeasible>());
      expect((result as RebalanceInfeasible).deficit, greaterThan(0));
    });
  });

  group('fillWithLowerWeight', () {
    test('an option per lower weight, nearest two only, sets within the range', () {
      final options = fillWithLowerWeight(
        deficit: 180,
        lowerWeights: [33, 26, 19],
        minReps: 6,
        maxReps: 8,
      );

      expect(options.map((o) => o.type), [OverloadType.fill, OverloadType.fill]);
      // 180 / 33 = 5.5 -> 6 reps in one set
      expect(options[0].sets, sets(33, [6]));
      // 180 / 26 = 6.9 -> 7
      expect(options[1].sets, sets(26, [7]));
      for (final option in options) {
        expect(option.volume, greaterThan(180));
      }
    });

    test('more than the top of the range spreads over sets, raised to the minimum', () {
      // 200 / 10 = 20 -> 21 reps, 3 sets of at most 8: 7/7/7
      expect(
        fillWithLowerWeight(deficit: 200, lowerWeights: [10], minReps: 6, maxReps: 8).single.sets,
        sets(10, [7, 7, 7]),
      );
      // 90 / 10 = 9 -> 10 reps, 2 sets of at least 6: 6/6
      expect(
        fillWithLowerWeight(deficit: 90, lowerWeights: [10], minReps: 6, maxReps: 8).single.sets,
        sets(10, [6, 6]),
      );
    });

    test('no deficit, nothing to fill', () {
      expect(fillWithLowerWeight(deficit: 0, lowerWeights: [10]), isEmpty);
    });
  });
}
