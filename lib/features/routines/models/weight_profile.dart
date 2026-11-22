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

import 'package:freezed_annotation/freezed_annotation.dart';

part 'weight_profile.freezed.dart';
part 'weight_profile.g.dart';

/// How the equipment of a [WeightProfile] makes up its weights
enum WeightProfileKind {
  /// A bar or handle ([WeightProfile.base]) with the same plates on both sides
  plates,

  /// A list of weights, e.g. a dumbbell rack ([WeightProfile.fixed])
  fixed,

  /// A stack: [WeightProfile.base] plus any number of [WeightProfile.step]s
  /// up to [WeightProfile.max], plus any of the [WeightProfile.bonus] add-ons
  linear,
}

/// The weights a piece of equipment offers, e.g. a barbell with plates or the
/// stack of a cable tower. Stored on this device only.
@freezed
sealed class WeightProfile with _$WeightProfile {
  const factory WeightProfile({
    required String id,
    required String name,
    required WeightProfileKind kind,

    /// The bar or handle for [WeightProfileKind.plates], the lightest weight
    /// of the stack for [WeightProfileKind.linear]
    @Default(0) num base,

    /// The increment of a [WeightProfileKind.linear] stack
    num? step,

    /// The heaviest weight of a [WeightProfileKind.linear] stack
    num? max,

    /// The plate sizes of [WeightProfileKind.plates], each usable many times
    @Default([]) List<num> plates,

    /// The weights of [WeightProfileKind.fixed]
    @Default([]) List<num> fixed,

    /// Add-ons of a [WeightProfileKind.linear] stack, each usable once. Repeat
    /// an entry for several of the same size, e.g. [0.625, 0.625].
    @Default([]) List<num> bonus,
  }) = _WeightProfile;

  const WeightProfile._();

  /// A 10 kg handle with the usual small plates
  factory WeightProfile.defaultPlates({required String id, required String name}) => WeightProfile(
    id: id,
    name: name,
    kind: WeightProfileKind.plates,
    base: 10,
    plates: const [1.25, 2.5, 5, 10, 20],
  );

  factory WeightProfile.fromJson(Map<String, dynamic> json) => _$WeightProfileFromJson(json);
}

/// How to load [WeightProfile] equipment for one weight, see [loadoutFor]
@freezed
class Loadout with _$Loadout {
  final WeightProfileKind kind;

  /// The bar or handle, 0 for [WeightProfileKind.fixed]
  final num base;

  /// The plates on each side, heaviest first
  final List<num> perSide;

  /// Where to put the pin of a [WeightProfileKind.linear] stack
  final num? pin;

  /// The add-ons on top of [pin]
  final List<num> addOns;

  /// The weight to pick for [WeightProfileKind.fixed]
  final num? fixed;

  const Loadout({
    required this.kind,
    this.base = 0,
    this.perSide = const [],
    this.pin,
    this.addOns = const [],
    this.fixed,
  });

  num get total =>
      fixed ??
      (pin ?? base) +
          2 * perSide.fold<num>(0, (sum, p) => sum + p) +
          addOns.fold<num>(0, (sum, a) => sum + a);
}

/// The profiles and which exercise uses which, as stored in the preferences
@freezed
sealed class WeightProfilesState with _$WeightProfilesState {
  const factory WeightProfilesState({
    @Default([]) List<WeightProfile> profiles,

    /// Profile ID by exercise ID
    @Default({}) Map<int, String> assignments,
  }) = _WeightProfilesState;

  const WeightProfilesState._();

  factory WeightProfilesState.fromJson(Map<String, dynamic> json) =>
      _$WeightProfilesStateFromJson(json);

  /// The profile assigned to [exerciseId], null without one
  WeightProfile? profileFor(int exerciseId) {
    final id = assignments[exerciseId];
    return id == null ? null : profiles.where((p) => p.id == id).firstOrNull;
  }
}

/// Weights closer than this are the same weight
const weightTolerance = 0.001;

/// Plates per side and the total [achievableWeights] considers for
/// [WeightProfileKind.plates], beyond that nobody loads a bar
const maxPlatesPerSide = 8;
const maxPlatesTotal = 300;

/// The most steps of a [WeightProfileKind.linear] stack without a maximum
const _maxLinearSteps = 200;

/// Weights are compared in thousandths, so float noise doesn't count
int _units(num weight) => (weight * 1000).round();

num _fromUnits(int units) => units / 1000;

/// Every weight [profile] can be loaded with, ascending, above zero and
/// without duplicates (within [weightTolerance])
List<num> achievableWeights(WeightProfile profile) {
  final units = <int>{};
  switch (profile.kind) {
    case WeightProfileKind.fixed:
      units.addAll(profile.fixed.map(_units));

    case WeightProfileKind.plates:
      final base = _units(profile.base);
      final plates = _positiveUnits(profile.plates).toSet().toList()..sort();
      final cap = _units(maxPlatesTotal);
      units.add(base);
      // Every multiset of plates per side, from plate index i upwards
      void loadSide(int from, int side, int count) {
        for (var i = from; i < plates.length; i++) {
          final next = side + plates[i];
          if (base + 2 * next > cap) {
            // Plates are ascending, the next ones are heavier still
            break;
          }
          units.add(base + 2 * next);
          if (count + 1 < maxPlatesPerSide) {
            loadSide(i, next, count + 1);
          }
        }
      }
      loadSide(0, 0, 0);

    case WeightProfileKind.linear:
      final addOns = _subsetSums(_positiveUnits(profile.bonus));
      for (final pin in _stack(profile)) {
        for (final addOn in addOns) {
          units.add(pin + addOn);
        }
      }
  }

  final sorted = units.where((u) => u > 0).toList()..sort();
  return [for (final u in sorted) _fromUnits(u)];
}

/// How to load [profile] for [weight], with the fewest plates or add-ons.
/// Null if [weight] isn't one of its weights within [weightTolerance].
Loadout? loadoutFor(WeightProfile profile, num weight) {
  final target = _units(weight);
  switch (profile.kind) {
    case WeightProfileKind.fixed:
      final match = profile.fixed.where((f) => (_units(f) - target).abs() <= 1).firstOrNull;
      return match == null ? null : Loadout(kind: WeightProfileKind.fixed, fixed: match);

    case WeightProfileKind.plates:
      final base = _units(profile.base);
      final rest = target - base;
      // Odd thousandths can't be split evenly, one more or less is within the
      // tolerance
      for (final both in [rest, rest - 1, rest + 1]) {
        if (both < 0 || both.isOdd) {
          continue;
        }
        final perSide = _fewestPlates(_positiveUnits(profile.plates).toSet().toList(), both ~/ 2);
        if (perSide != null) {
          return Loadout(
            kind: WeightProfileKind.plates,
            base: profile.base,
            perSide: [for (final p in perSide) _fromUnits(p)],
          );
        }
      }
      return null;

    case WeightProfileKind.linear:
      final stack = _stack(profile).toSet();
      final bonus = _positiveUnits(profile.bonus);
      // Subsets by the number of add-ons, so the first match uses the fewest
      final masks = List.generate(1 << bonus.length, (m) => m)
        ..sort((a, b) => _bitCount(a).compareTo(_bitCount(b)));
      for (final mask in masks) {
        final addOns = [
          for (var i = 0; i < bonus.length; i++)
            if (mask & (1 << i) != 0) bonus[i],
        ];
        final pin = target - addOns.fold<int>(0, (sum, a) => sum + a);
        for (final candidate in [pin, pin - 1, pin + 1]) {
          if (stack.contains(candidate)) {
            return Loadout(
              kind: WeightProfileKind.linear,
              base: profile.base,
              pin: _fromUnits(candidate),
              addOns: [for (final a in addOns..sort((a, b) => b.compareTo(a))) _fromUnits(a)],
            );
          }
        }
      }
      return null;
  }
}

List<int> _positiveUnits(List<num> weights) => [
  for (final w in weights)
    if (_units(w) > 0) _units(w),
];

/// The pin positions of a [WeightProfileKind.linear] stack
Iterable<int> _stack(WeightProfile profile) sync* {
  final base = _units(profile.base);
  final step = _units(profile.step ?? 0);
  final max = profile.max == null ? null : _units(profile.max!);
  yield base;
  if (step <= 0) {
    return;
  }
  for (var k = 1; k <= _maxLinearSteps; k++) {
    final pin = base + k * step;
    if (max != null && pin > max + 1) {
      return;
    }
    yield pin;
  }
}

/// The sums of every subset of [values], including the empty one
Set<int> _subsetSums(List<int> values) {
  var sums = {0};
  for (final v in values) {
    sums = {...sums, for (final s in sums) s + v};
  }
  return sums;
}

int _bitCount(int n) {
  var count = 0;
  for (var m = n; m > 0; m >>= 1) {
    count += m & 1;
  }
  return count;
}

/// The fewest of [plates] (each usable many times) that add up to [side],
/// heaviest first, null if none do
List<int>? _fewestPlates(List<int> plates, int side) {
  if (side == 0) {
    return [];
  }
  if (plates.isEmpty) {
    return null;
  }
  final step = plates.reduce(_gcd);
  if (side % step != 0) {
    return null;
  }
  final scaled = [for (final p in plates) p ~/ step]..sort((a, b) => b.compareTo(a));
  final target = side ~/ step;

  // fewest[s] is the fewest plates for s, last[s] the heaviest plate of it
  final fewest = List<int?>.filled(target + 1, null)..[0] = 0;
  final last = List<int>.filled(target + 1, 0);
  for (var s = 1; s <= target; s++) {
    for (final p in scaled) {
      final rest = s - p;
      if (rest < 0 || fewest[rest] == null) {
        continue;
      }
      // Strictly fewer only, so on a tie the heavier plate (first) stays
      if (fewest[s] == null || fewest[rest]! + 1 < fewest[s]!) {
        fewest[s] = fewest[rest]! + 1;
        last[s] = p;
      }
    }
  }
  if (fewest[target] == null) {
    return null;
  }

  final result = <int>[];
  for (var s = target; s > 0; s -= last[s]) {
    result.add(last[s] * step);
  }
  return result..sort((a, b) => b.compareTo(a));
}

int _gcd(int a, int b) => b == 0 ? a : _gcd(b, a % b);
