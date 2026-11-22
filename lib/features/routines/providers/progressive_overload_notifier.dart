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

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:wger/core/consts.dart';
import 'package:wger/features/routines/models/log.dart';
import 'package:wger/features/routines/models/overload_option.dart';
import 'package:wger/features/routines/models/weight_profile.dart';
import 'package:wger/features/routines/progressive_overload.dart';
import 'package:wger/features/routines/providers/weight_profiles_notifier.dart';
import 'package:wger/features/routines/providers/workout_logs_repository.dart';

part 'progressive_overload_notifier.g.dart';

/// The progressive overload options for [exerciseId], based on its last
/// session before [before] (the start of the running workout, so its own sets
/// don't count), its first [plannedSets] sets (all when null) and the
/// repetition range [minReps]..[maxReps].
///
/// The known weights are those of the weight profile assigned to the exercise
/// and those logged before in the weight unit of the last set.
@riverpod
Future<OverloadSuggestions> overloadSuggestions(
  Ref ref, {
  required int exerciseId,
  required DateTime before,
  num? minReps,
  num? maxReps,
  int? plannedSets,
}) async {
  final profile = await ref.watch(
    weightProfilesProvider.selectAsync((state) => state.profileFor(exerciseId)),
  );
  final repository = ref.read(workoutLogRepositoryProvider);
  final lastSession = comparableSets(
    await repository.getLastSessionLogsByExercise(exerciseId, before: before),
  );

  final logged = lastSession.isEmpty
      ? const <num>[]
      : await repository.getDistinctWeightsByExercise(
          exerciseId,
          weightUnitId: lastSession.last.weightUnitId,
        );
  final knownWeights = knownWeightsOf(
    profile == null ? const [] : achievableWeights(profile),
    logged,
  );

  final sets = [
    for (final log in lastSession) OverloadSet(weight: log.weight, repetitions: log.repetitions!),
  ];
  return OverloadSuggestions(
    lastSession: lastSession,
    options: calculateOverloadOptions(
      lastSession: sets,
      availableWeights: knownWeights,
      minReps: minReps,
      maxReps: maxReps,
      plannedSets: plannedSets,
    ),
    hasAvailableWeights: profile != null,
    profile: profile,
    knownWeights: knownWeights,
    baselineVolume: overloadVolume(overloadBaseline(sets, plannedSets: plannedSets)),
  );
}

/// The [profileWeights] and the [loggedWeights], ascending. A logged weight
/// within two decimals of a profile weight is that weight: 1.875 is logged
/// as 1.87 or 1.88.
List<num> knownWeightsOf(List<num> profileWeights, List<num> loggedWeights) {
  final known = [...profileWeights];
  for (final logged in loggedWeights) {
    if (!known.any((w) => (w - logged).abs() < 0.01 - 1e-9)) {
      known.add(logged);
    }
  }
  return known..sort();
}

/// The sets of [logs] whose volume can be compared: counted in repetitions
/// and, with a weight, in the weight unit of the last set
List<Log> comparableSets(List<Log> logs) {
  final unitId = logs.lastOrNull?.weightUnitId;
  return logs
      .where(
        (log) =>
            log.repetitions != null &&
            log.repetitions! > 0 &&
            log.repetitionsUnitId == REP_UNIT_REPETITIONS_ID &&
            (log.weight == null || log.weight == 0 || log.weightUnitId == unitId),
      )
      .toList();
}
