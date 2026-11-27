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

import 'package:flutter/foundation.dart';
import 'package:wger/features/routines/models/overload_option.dart';

/// One planned exercise of the day, the input of `planMuscleOverload`
@immutable
class MuscleEntry {
  final int slotEntryId;

  /// The muscle groups it counts towards, see `overloadMuscles`
  final List<String> muscles;

  /// Its sets of the last session in any routine, empty if never done
  final List<OverloadSet> lastSession;

  /// The planned weight, the start without a last session
  final num? plannedWeight;

  /// The planned repetitions, [maxReps] null for a fixed number
  final num? minReps;
  final num? maxReps;

  /// The planned sets, [maxSets] null for a fixed number
  final int plannedSets;
  final int? maxSets;

  /// The weights of the equipment and those logged before, ascending
  final List<num> knownWeights;

  const MuscleEntry({
    required this.slotEntryId,
    required this.muscles,
    required this.plannedSets,
    this.lastSession = const [],
    this.plannedWeight,
    this.minReps,
    this.maxReps,
    this.maxSets,
    this.knownWeights = const [],
  });
}

/// The volume of one muscle group today and in the session it is compared to
@immutable
class MuscleTarget {
  final String muscle;

  /// The volume of the compared session, the one to beat
  final num baseline;

  /// The volume of today's plan, the last weights before any step
  final num start;

  /// The volume of today's plan
  final num planned;

  const MuscleTarget({
    required this.muscle,
    required this.baseline,
    required this.start,
    required this.planned,
  });

  /// Whether the plan does strictly more than the compared session
  bool get reached => planned - baseline > 1e-9;

  /// How much volume is missing, 0 once [reached]
  num get gap => reached ? 0 : baseline - planned;
}

/// The overload per muscle group for the first session of a day after a
/// programme switch: today's sets of each exercise, chosen so every muscle
/// group beats the most similar session before the switch
@immutable
class MuscleOverloadPlan {
  /// When the compared session took place
  final DateTime baselineDate;

  /// The routine of the compared session, null without one
  final int? baselineRoutineId;

  /// Today's sets by slot entry ID, all of type [OverloadType.muscleGroup]
  final Map<int, OverloadOption> options;

  /// Each muscle group trained in both sessions, the largest gap first
  final List<MuscleTarget> targets;

  const MuscleOverloadPlan({
    required this.baselineDate,
    required this.options,
    required this.targets,
    this.baselineRoutineId,
  });

  /// The muscle groups the plan can't get beyond the compared session within
  /// the planned ranges
  List<MuscleTarget> get gaps => targets.where((t) => !t.reached).toList();
}
