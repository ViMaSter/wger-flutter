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

import 'package:wger/features/routines/models/muscle_overload_plan.dart';
import 'package:wger/features/routines/models/overload_option.dart';
import 'package:wger/features/routines/progressive_overload.dart';

const _epsilon = 1e-9;

/// Never more steps than this, a guard against a step that adds nothing
const _maxSteps = 1000;

/// The volume of each muscle group in [exercises]: every exercise adds its
/// whole volume (weight × repetitions, the repetitions without weight) to each
/// of its muscle groups, as the calendar of reports-by-vincent does.
Map<String, num> muscleVolumes(
  Iterable<({List<String> muscles, List<OverloadSet> sets})> exercises,
) {
  final volumes = <String, num>{};
  for (final exercise in exercises) {
    final volume = overloadVolume(exercise.sets);
    for (final muscle in exercise.muscles.toSet()) {
      volumes.update(muscle, (v) => v + volume, ifAbsent: () => volume);
    }
  }
  return volumes;
}

/// The Jaccard overlap of two sets of muscle groups, 0 when both are empty
double muscleOverlap(Set<String> a, Set<String> b) {
  final union = a.union(b).length;
  return union == 0 ? 0 : a.intersection(b).length / union;
}

/// The index of the session in [candidates] (newest first) whose muscle
/// groups overlap [today] the most, the newest on a tie, null if none
/// overlaps at all
int? matchSession(Set<String> today, List<Set<String>> candidates) {
  int? best;
  var bestOverlap = 0.0;
  for (final (index, muscles) in candidates.indexed) {
    final overlap = muscleOverlap(today, muscles);
    if (overlap > bestOverlap + _epsilon) {
      best = index;
      bestOverlap = overlap;
    }
  }
  return best;
}

/// Today's sets of each of [entries] so that every muscle group of
/// [baseline] trained today has strictly more volume than there.
///
/// Every exercise starts from its last session as straight sets: its working
/// weight (the planned weight without a last session), its repetitions and
/// number of sets moved into the planned ranges. A range without a maximum is
/// a fixed number. Then, as long as a muscle group falls short, the one
/// furthest behind (relative to its baseline) gets the smallest step of one
/// of its exercises, the one raised the least so far, so the increase is
/// spread evenly: one more repetition, the next known weight for every set,
/// or one more set, see [calculateOverloadOptions]. Weights go at most
/// [maxWeightSteps] known weights beyond the start, repetitions and sets never
/// leave the planned ranges; whatever is still missing then stays a gap.
({Map<int, OverloadOption> options, List<MuscleTarget> targets}) planMuscleOverload({
  required Map<String, num> baseline,
  required List<MuscleEntry> entries,
  int maxWeightSteps = 3,
}) {
  final states = [for (final entry in entries) _EntryState(entry, maxWeightSteps)];
  final todaysMuscles = {for (final entry in entries) ...entry.muscles};
  final compared = {
    for (final MapEntry(:key, :value) in baseline.entries)
      if (todaysMuscles.contains(key) && value > 0) key: value,
  };

  Map<String, num> planned() =>
      muscleVolumes([for (final s in states) (muscles: s.entry.muscles, sets: s.current)]);
  final start = planned();

  final exhausted = <String>{};
  for (var step = 0; step < _maxSteps; step++) {
    final volumes = planned();
    String? furthest;
    num furthestShare = double.infinity;
    for (final MapEntry(key: muscle, value: target) in compared.entries) {
      final volume = volumes[muscle] ?? 0;
      if (exhausted.contains(muscle) || volume - target > _epsilon) {
        continue;
      }
      final share = volume / target;
      if (share < furthestShare) {
        furthest = muscle;
        furthestShare = share;
      }
    }
    if (furthest == null) {
      break;
    }

    _EntryState? pick;
    OverloadOption? pickStep;
    for (final state in states.where((s) => s.entry.muscles.contains(furthest))) {
      final next = state.nextStep();
      if (next == null) {
        continue;
      }
      final better =
          pick == null ||
          state.increase < pick.increase - _epsilon ||
          ((state.increase - pick.increase).abs() <= _epsilon &&
              next.volume - state.volume < pickStep!.volume - pick.volume);
      if (better) {
        pick = state;
        pickStep = next;
      }
    }
    if (pick == null) {
      exhausted.add(furthest);
      continue;
    }
    pick.current = pickStep!.sets;
  }

  final volumes = planned();
  final targets = [
    for (final MapEntry(key: muscle, value: target) in compared.entries)
      MuscleTarget(
        muscle: muscle,
        baseline: target,
        start: start[muscle] ?? 0,
        planned: volumes[muscle] ?? 0,
      ),
  ]..sort((a, b) => b.gap.compareTo(a.gap));

  return (
    options: {
      for (final state in states)
        if (state.current.isNotEmpty)
          state.entry.slotEntryId: OverloadOption(
            type: OverloadType.muscleGroup,
            sets: state.current,
          ),
    },
    targets: targets,
  );
}

/// The sets of one exercise while the plan is being built
class _EntryState {
  final MuscleEntry entry;
  final num _minReps;
  final num _maxReps;
  final int _maxSets;
  final List<num> _weights;
  late List<OverloadSet> current;
  late final num _startVolume;

  _EntryState(this.entry, int maxWeightSteps)
    : _minReps = max(entry.minReps ?? _lastReps(entry) ?? 1, 1),
      _maxReps = max(entry.maxReps ?? entry.minReps ?? _lastReps(entry) ?? 1, 1),
      _maxSets = max(entry.maxSets ?? entry.plannedSets, entry.plannedSets),
      _weights = _allowedWeights(entry, maxWeightSteps) {
    current = _start();
    _startVolume = overloadVolume(current);
  }

  num get volume => overloadVolume(current);

  /// How much it was raised so far, relative to the start
  num get increase => _startVolume <= 0 ? volume : (volume - _startVolume) / _startVolume;

  /// The smallest step beyond [current] within the ranges, null without one
  OverloadOption? nextStep() {
    if (current.isEmpty) {
      return null;
    }
    final options = calculateOverloadOptions(
      lastSession: current,
      availableWeights: _weights,
      minReps: _minReps,
      maxReps: _maxReps,
    ).where((o) => o.sets.length <= _maxSets && o.volume - volume > _epsilon).toList();
    return smallestOverloadOption(options);
  }

  /// Straight sets with the working weight of the last session, its
  /// repetitions set by set moved into the range, as many sets as planned
  List<OverloadSet> _start() {
    final last = entry.lastSession;
    final weight = workingWeight(last) ?? (last.isEmpty ? entry.plannedWeight : null);
    final nrOfSets = entry.plannedSets.clamp(1, _maxSets);
    final lastReps = [for (final set in last) set.repetitions];
    return [
      for (var i = 0; i < nrOfSets; i++)
        OverloadSet(
          weight: weight,
          repetitions: (lastReps.isEmpty ? _minReps : lastReps[min(i, lastReps.length - 1)]).clamp(
            _minReps,
            _maxReps,
          ),
        ),
    ];
  }

  static num? _lastReps(MuscleEntry entry) =>
      entry.lastSession.isEmpty ? null : entry.lastSession.map((s) => s.repetitions).reduce(max);

  /// The known weights up to the [maxWeightSteps]th one above the start weight
  static List<num> _allowedWeights(MuscleEntry entry, int maxWeightSteps) {
    final start = workingWeight(entry.lastSession) ?? entry.plannedWeight;
    if (start == null) {
      return const [];
    }
    final above = (entry.knownWeights.where((w) => w - start > 0.005).toSet().toList()..sort())
        .take(maxWeightSteps);
    return above.toList();
  }
}
