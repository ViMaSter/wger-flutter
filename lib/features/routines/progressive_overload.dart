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

import 'dart:math';

import 'package:wger/features/routines/models/overload_option.dart';

/// Tolerance for floating point noise, e.g. 600 / 22.5
const _epsilon = 1e-9;

/// Added to a deficit so making it up exactly is strictly more than before
const _deficitEpsilon = 1e-6;

/// Logs store two decimals, so an available weight of 1.875 was logged as
/// 1.87 or 1.88. Weights closer than this are the same weight.
const _logPrecision = 0.01;

/// The ways to do more than in [lastSession], the sets of an exercise from its
/// previous session, in order.
///
/// "More" is the volume, the sum of weight × repetitions (or only the
/// repetitions without weight), compared to the baseline: the first
/// [plannedSets] sets of [lastSession], all of them when null, so extra sets
/// done last time don't raise the bar. Repetitions stay within
/// [minReps]..[maxReps], either of them may be null for an open range.
/// [availableWeights] are the known weights, those of the equipment and those
/// logged before, the next [maxWeightSteps] above the lowest weight of the
/// baseline are suggested.
///
/// Returns, in this order: one more repetition with the same weights (unless
/// every set is at [maxReps] already), each heavier weight that fits the
/// repetition range, and one more set. Empty without a previous session.
List<OverloadOption> calculateOverloadOptions({
  required List<OverloadSet> lastSession,
  List<num> availableWeights = const [],
  num? minReps,
  num? maxReps,
  int maxWeightSteps = 3,
  int? plannedSets,
}) {
  final baseline = overloadBaseline(lastSession, plannedSets: plannedSets);
  if (baseline.isEmpty) {
    return [];
  }

  final options = <OverloadOption>[];
  final moreReps = _moreReps(baseline, maxReps);
  if (moreReps != null) {
    options.add(moreReps);
  }
  options.addAll(
    _heavier(baseline, availableWeights, minReps, maxReps, maxWeightSteps),
  );
  options.add(
    OverloadOption(type: OverloadType.moreSets, sets: [...baseline, baseline.last]),
  );
  return options;
}

/// The sets of [lastSession] the options are compared to, the first
/// [plannedSets] of them, all of them when null
List<OverloadSet> overloadBaseline(List<OverloadSet> lastSession, {int? plannedSets}) =>
    plannedSets == null || plannedSets >= lastSession.length
    ? lastSession
    : lastSession.take(max(plannedSets, 0)).toList();

/// The repetitions for the remaining sets of a running workout, so the whole
/// workout still beats [baselineVolume].
///
/// [targets] are the planned sets of the chosen option, [logged] what was
/// logged so far by the index into [targets]. Logged sets stay as they are,
/// the others keep their target weight with the fewest repetitions within
/// [minReps]..[maxReps] that make the volume strictly more, taken from the
/// back first. Logged indices past [targets] (extra sets) count too and are
/// appended in order.
///
/// [RebalanceInfeasible] if even [maxReps] on every remaining set falls short.
RebalanceResult rebalanceRemaining({
  required num baselineVolume,
  required List<OverloadSet> targets,
  required Map<int, OverloadSet> logged,
  num? minReps,
  num? maxReps,
}) {
  final rowCount = max(targets.length, logged.keys.fold(0, (m, i) => max(m, i + 1)));
  final rows = <int>[
    for (var i = 0; i < rowCount; i++)
      if (logged.containsKey(i) || i < targets.length) i,
  ];
  final loggedVolume = overloadVolume(logged.values);
  final remaining = [
    for (var i = 0; i < targets.length; i++)
      if (!logged.containsKey(i)) i,
  ];

  final need = baselineVolume - loggedVolume;
  final floor = max<num>(minReps ?? 1, 1);
  num perRep(int i) => _perRep(targets[i].weight);

  // Start every remaining set high enough, then take repetitions away
  final reps = <int, num>{};
  if (maxReps != null) {
    for (final i in remaining) {
      reps[i] = max(maxReps, floor);
    }
  } else if (remaining.isNotEmpty) {
    final perRound = remaining.fold<num>(0, (sum, i) => sum + perRep(i));
    final even = max<num>((need / perRound + _epsilon).floor() + 1, floor);
    for (final i in remaining) {
      reps[i] = even;
    }
  }

  var volume = remaining.fold<num>(0, (sum, i) => sum + perRep(i) * reps[i]!);
  if (volume - need <= _epsilon) {
    return RebalanceInfeasible(need - volume + _deficitEpsilon);
  }

  // Take one repetition from the set with the most, the last of them on a
  // tie, as long as the volume stays strictly more
  while (true) {
    int? pick;
    for (final i in remaining.reversed) {
      if (reps[i]! - 1 < floor || volume - perRep(i) - need <= _epsilon) {
        continue;
      }
      if (pick == null || reps[i]! > reps[pick]!) {
        pick = i;
      }
    }
    if (pick == null) {
      break;
    }
    reps[pick] = reps[pick]! - 1;
    volume -= perRep(pick);
  }

  return RebalanceFeasible([
    for (final i in rows)
      logged[i] ?? OverloadSet(weight: targets[i].weight, repetitions: reps[i]!),
  ]);
}

/// Extra sets with a lighter weight that make up [deficit], see
/// [RebalanceInfeasible].
///
/// [lowerWeights] are the weights below the current one, nearest first, one
/// option for each of the first two. Each has as many sets as the fewest
/// repetitions with a volume strictly more than [deficit] need within
/// [maxReps], front-loaded and each at least [minReps].
List<OverloadOption> fillWithLowerWeight({
  required num deficit,
  required List<num> lowerWeights,
  num? minReps,
  num? maxReps,
}) {
  if (deficit <= 0) {
    return [];
  }
  final floor = max<num>(minReps ?? 1, 1).ceil();

  final options = <OverloadOption>[];
  for (final weight in lowerWeights.where((w) => w > 0).take(2)) {
    final required = (deficit / weight + _epsilon).floor() + 1;
    final nrOfSets = maxReps == null ? 1 : max(1, (required / maxReps).ceil());
    final total = max(required, nrOfSets * floor);
    options.add(
      OverloadOption(
        type: OverloadType.fill,
        requiredRepetitions: required,
        sets: [
          for (final r in _frontLoaded(total, nrOfSets))
            OverloadSet(weight: weight, repetitions: r),
        ],
      ),
    );
  }
  return options;
}

/// The option with the least volume, the smallest step beyond last time. The
/// first one on a tie, so one more repetition before a heavier weight.
OverloadOption? smallestOverloadOption(List<OverloadOption> options) =>
    options.isEmpty ? null : options.reduce((a, b) => b.volume < a.volume ? b : a);

/// One more repetition on the set with the fewest that is still below
/// [maxReps], the first of them on a tie
OverloadOption? _moreReps(List<OverloadSet> lastSession, num? maxReps) {
  int? index;
  for (var i = 0; i < lastSession.length; i++) {
    final reps = lastSession[i].repetitions;
    if (maxReps != null && reps + 1 > maxReps) {
      continue;
    }
    if (index == null || reps < lastSession[index].repetitions) {
      index = i;
    }
  }
  if (index == null) {
    return null;
  }

  final sets = [...lastSession];
  sets[index] = sets[index].copyWith(repetitions: sets[index].repetitions + 1);
  return OverloadOption(type: OverloadType.moreReps, sets: sets);
}

/// The weight most sets of [lastSession] were done with, the heavier one on a
/// tie, null without weight. A single heavier top set or a lighter warm-up set
/// doesn't move it, so the next weight up is still offered after them.
num? workingWeight(List<OverloadSet> lastSession) {
  final counts = <num, int>{};
  for (final set in lastSession) {
    final weight = set.weight;
    if (weight != null && weight > 0) {
      counts.update(weight, (c) => c + 1, ifAbsent: () => 1);
    }
  }
  if (counts.isEmpty) {
    return null;
  }
  return counts.entries
      .reduce((a, b) => b.value > a.value || (b.value == a.value && b.key > a.key) ? b : a)
      .key;
}

/// The same number of sets with each known weight above the lowest of
/// [baseline], every set at that weight, with the fewest repetitions that beat
/// the volume of [baseline], front-loaded
List<OverloadOption> _heavier(
  List<OverloadSet> baseline,
  List<num> knownWeights,
  num? minReps,
  num? maxReps,
  int maxWeightSteps,
) {
  final weights = baseline.map((s) => s.weight).nonNulls.where((w) => w > 0).toList();
  if (weights.isEmpty) {
    return [];
  }
  // Strictly above the lowest weight, so with a lighter first set the weight
  // of the others is offered too: it puts every set there. With every set at
  // one weight, the ones above it are left anyway.
  final lowest = weights.reduce(min);

  final volume = overloadVolume(baseline);
  final nrOfSets = baseline.length;
  final floor = max(minReps ?? 1, 1);

  final nextWeights =
      (knownWeights.where((w) => w - lowest >= _logPrecision - _epsilon).toSet().toList()..sort())
          .take(maxWeightSteps);

  final options = <OverloadOption>[];
  for (final weight in nextWeights) {
    final totalReps = (volume / weight + _epsilon).floor() + 1;
    final reps = [for (final r in _frontLoaded(totalReps, nrOfSets)) max<num>(r, floor)];
    if (maxReps != null && reps.any((r) => r > maxReps)) {
      continue;
    }
    options.add(
      OverloadOption(
        type: OverloadType.heavier,
        requiredRepetitions: totalReps,
        sets: [for (final r in reps) OverloadSet(weight: weight, repetitions: r)],
      ),
    );
  }
  return options;
}

/// [total] repetitions over [nrOfSets] sets, as even as possible with the
/// larger ones first, e.g. 27 over 4 is 7, 7, 7, 6
List<int> _frontLoaded(int total, int nrOfSets) => [
  for (var i = 0; i < nrOfSets; i++) total ~/ nrOfSets + (i < total % nrOfSets ? 1 : 0),
];

/// The volume of one repetition, the weight or 1 without one
num _perRep(num? weight) => (weight == null || weight == 0) ? 1 : weight;
