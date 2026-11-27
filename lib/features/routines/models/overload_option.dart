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

import 'package:collection/collection.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:wger/features/routines/models/log.dart';
import 'package:wger/features/routines/models/weight_profile.dart';

part 'overload_option.freezed.dart';

/// How an [OverloadOption] beats the previous session
enum OverloadType {
  /// Same weights, one more repetition
  moreReps,

  /// The next available weight, with enough repetitions to keep the volume
  heavier,

  /// The previous session plus one more set
  moreSets,

  /// Extra sets with a lighter weight that make up what the planned sets
  /// couldn't, see `fillWithLowerWeight`
  fill,

  /// After a programme switch: the sets that make every muscle group beat the
  /// most similar session before the switch, see `planMuscleOverload`
  muscleGroup,

  /// The previous session as it was, no overload. Not one of the suggestions,
  /// offered next to them in the list layout.
  asBefore,
}

/// One set of an [OverloadOption]
@freezed
class OverloadSet with _$OverloadSet {
  /// Null for sets without weight, e.g. bodyweight exercises
  final num? weight;
  final num repetitions;

  const OverloadSet({required this.weight, required this.repetitions});

  num get volume => (weight == null || weight == 0) ? repetitions : weight! * repetitions;
}

/// A way to train an exercise today without doing less than last time
@freezed
class OverloadOption with _$OverloadOption {
  final OverloadType type;

  /// The sets to do, in order
  final List<OverloadSet> sets;

  /// For [OverloadType.heavier] and [OverloadType.fill], the fewest
  /// repetitions in total that beat the volume of last time, in any split
  /// across the sets. [sets] is one split.
  final int? requiredRepetitions;

  const OverloadOption({required this.type, required this.sets, this.requiredRepetitions});

  /// Sum of weight × repetitions, or of the repetitions for sets without weight
  num get volume => overloadVolume(sets);
}

/// Sum of weight × repetitions of [sets], or of the repetitions without weight
num overloadVolume(Iterable<OverloadSet> sets) => sets.fold<num>(0, (sum, set) => sum + set.volume);

/// The outcome of `rebalanceRemaining`
@immutable
sealed class RebalanceResult {
  const RebalanceResult();
}

/// Every set of the workout, the logged ones as they were and the remaining
/// ones with the repetitions that still beat the volume of last time
final class RebalanceFeasible extends RebalanceResult {
  final List<OverloadSet> sets;

  const RebalanceFeasible(this.sets);

  @override
  bool operator ==(Object other) =>
      other is RebalanceFeasible && const ListEquality<OverloadSet>().equals(other.sets, sets);

  @override
  int get hashCode => const ListEquality<OverloadSet>().hash(sets);

  @override
  String toString() => 'RebalanceFeasible($sets)';
}

/// Even the top of the repetition range on every remaining set stays below
/// the volume of last time, by [deficit]
final class RebalanceInfeasible extends RebalanceResult {
  final num deficit;

  const RebalanceInfeasible(this.deficit);

  @override
  String toString() => 'RebalanceInfeasible($deficit)';
}

/// The previous session of an exercise and the ways to beat it
class OverloadSuggestions {
  /// The sets of the previous session the [options] are based on, empty if
  /// the exercise was never done before
  final List<Log> lastSession;

  final List<OverloadOption> options;

  /// Whether a weight profile is assigned to the exercise. Without one the
  /// heavier options only come from the weights logged before.
  final bool hasAvailableWeights;

  /// The assigned weight profile, null without one
  final WeightProfile? profile;

  /// The weights of [profile] and those logged before (in the weight unit of
  /// the last set), ascending
  final List<num> knownWeights;

  /// The volume of the planned sets of the previous session, the one every
  /// option beats
  final num baselineVolume;

  const OverloadSuggestions({
    required this.lastSession,
    required this.options,
    required this.hasAvailableWeights,
    this.profile,
    this.knownWeights = const [],
    this.baselineVolume = 0,
  });
}
