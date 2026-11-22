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
import 'package:wger/features/routines/models/weight_profile.dart';

void main() {
  const stack = WeightProfile(
    id: 'stack',
    name: 'Cable tower',
    kind: WeightProfileKind.linear,
    base: 1.25,
    step: 2.5,
    max: 48.75,
    bonus: [0.625, 0.625],
  );
  final barbell = WeightProfile.defaultPlates(id: 'bar', name: 'Bar');

  group('achievableWeights', () {
    test('a stack: every pin position plus any of the add-ons', () {
      final weights = achievableWeights(stack);

      expect(weights.first, 1.25);
      expect(weights.last, 48.75 + 1.25);
      expect(weights, containsAll([36.25, 36.875, 37.5, 38.75, 40]));
      expect(weights, isNot(contains(37)));
      // 20 pin positions × 3 add-on sums (0, 0.625, 1.25), none overlap
      expect(weights, hasLength(60));
    });

    test('plates: the bar plus the same plates on both sides, never unbalanced', () {
      final weights = achievableWeights(barbell);

      expect(weights.first, 10);
      expect(weights, containsAll([12.5, 15, 60, 300]));
      // 1.25 per side is the smallest step, 2.5 in total
      expect(weights, isNot(contains(11.25)));
      expect(weights, isNot(contains(61)));
      expect(weights.last, lessThanOrEqualTo(maxPlatesTotal));
    });

    test('plates: at most eight plates per side', () {
      const onlyFives = WeightProfile(
        id: 'p',
        name: 'p',
        kind: WeightProfileKind.plates,
        base: 0,
        plates: [5],
      );

      expect(achievableWeights(onlyFives), [for (var n = 1; n <= 8; n++) n * 10]);
    });

    test('fixed: the listed weights, ascending, without duplicates or zero', () {
      const rack = WeightProfile(
        id: 'r',
        name: 'Dumbbells',
        kind: WeightProfileKind.fixed,
        fixed: [12.5, 5, 0, 10, 5.0004],
      );

      expect(achievableWeights(rack), [5, 10, 12.5]);
    });
  });

  group('loadoutFor', () {
    test('a stack: the pin and the fewest add-ons', () {
      expect(
        loadoutFor(stack, 40),
        const Loadout(
          kind: WeightProfileKind.linear,
          base: 1.25,
          pin: 38.75,
          addOns: [0.625, 0.625],
        ),
      );
      expect(
        loadoutFor(stack, 36.875),
        const Loadout(kind: WeightProfileKind.linear, base: 1.25, pin: 36.25, addOns: [0.625]),
      );
      expect(loadoutFor(stack, 37), isNull);
      expect(loadoutFor(stack, 40)!.total, 40);
    });

    test('a stack: nothing above the maximum', () {
      expect(loadoutFor(stack, 51.25), isNull);
      expect(loadoutFor(stack, 50)!.pin, 48.75);
    });

    test('plates: the fewest plates per side, heaviest first', () {
      expect(
        loadoutFor(barbell, 60),
        const Loadout(kind: WeightProfileKind.plates, base: 10, perSide: [20, 5]),
      );
      expect(loadoutFor(barbell, 61), isNull);
      expect(loadoutFor(barbell, 10)!.perSide, isEmpty);
      expect(loadoutFor(barbell, 5), isNull);
      // 37.5 per side: 20 + 10 + 5 + 2.5
      expect(loadoutFor(barbell, 85)!.perSide, [20, 10, 5, 2.5]);
    });

    test('plates: fewest plates beats always taking the heaviest', () {
      const odd = WeightProfile(
        id: 'o',
        name: 'o',
        kind: WeightProfileKind.plates,
        base: 0,
        plates: [1, 3, 4],
      );

      // 6 per side: 3 + 3, greedy would take 4 + 1 + 1
      expect(loadoutFor(odd, 12)!.perSide, [3, 3]);
    });

    test('fixed: one of the weights, within the tolerance', () {
      const rack = WeightProfile(
        id: 'r',
        name: 'r',
        kind: WeightProfileKind.fixed,
        fixed: [1.875, 2.5],
      );

      expect(loadoutFor(rack, 1.8754)!.fixed, 1.875);
      expect(loadoutFor(rack, 1.87), isNull);
    });
  });
}
