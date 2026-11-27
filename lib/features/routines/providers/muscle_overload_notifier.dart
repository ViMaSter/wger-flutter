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
import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:wger/core/consts.dart';
import 'package:wger/features/exercises/muscle_mapping.dart';
import 'package:wger/features/exercises/providers/exercises_notifier.dart';
import 'package:wger/features/routines/models/log.dart';
import 'package:wger/features/routines/models/muscle_overload_plan.dart';
import 'package:wger/features/routines/models/overload_option.dart';
import 'package:wger/features/routines/models/set_config_data.dart';
import 'package:wger/features/routines/muscle_overload.dart';
import 'package:wger/features/routines/providers/progressive_overload_notifier.dart';
import 'package:wger/features/routines/providers/workout_logs_repository.dart';

part 'muscle_overload_notifier.g.dart';

/// One planned exercise of the day: its set config and how many sets are
/// planned
typedef PlannedEntry = ({SetConfigData config, int plannedSets});

/// The planned exercises of a day, equal when everything the plan per muscle
/// group depends on is, so a rebuild of gym mode doesn't compute it again
@immutable
class PlannedEntries {
  final List<PlannedEntry> items;

  const PlannedEntries(this.items);

  List<Object?> get _key => [
    for (final e in items) ...[
      e.config.slotEntryId,
      e.config.exerciseId,
      e.plannedSets,
      e.config.maxNrOfSets,
      e.config.repetitions,
      e.config.maxRepetitions,
      e.config.repetitionsUnitId,
      e.config.weight,
    ],
  ];

  @override
  bool operator ==(Object other) =>
      other is PlannedEntries && const ListEquality<Object?>().equals(other._key, _key);

  @override
  int get hashCode => const ListEquality<Object?>().hash(_key);
}

/// Whether a planned exercise counts for the overload per muscle group:
/// counted in repetitions, with a real number of them, not a stretch (1) or a
/// placeholder for "as many as possible" (1000)
bool countsForMuscleOverload(SetConfigData config) {
  final reps = config.repetitions;
  return (config.repetitionsUnitId ?? REP_UNIT_REPETITIONS_ID) == REP_UNIT_REPETITIONS_ID &&
      reps != null &&
      reps > 1 &&
      reps < 1000;
}

/// The overload per muscle group for the day of [entries] of routine [routineId] in
/// the workout started at [before], null unless it is the first session of
/// that day since [routineStart] (a programme switch, or the same routine
/// started again) and something was trained before it.
///
/// [entries] are the day's planned exercises. Today's muscle groups are
/// compared to the session before the switch that overlaps them the most.
@riverpod
Future<MuscleOverloadPlan?> muscleOverloadPlan(
  Ref ref, {
  required int routineId,
  required DateTime routineStart,
  required DateTime before,
  required PlannedEntries entries,
}) async {
  final repository = ref.read(workoutLogRepositoryProvider);
  final since = DateTime(routineStart.year, routineStart.month, routineStart.day);
  final counted = entries.items.where((e) => countsForMuscleOverload(e.config)).toList();
  if (counted.isEmpty) {
    return null;
  }

  final trainedSinceStart = await repository.hasLogsForSlotEntries(
    routineId,
    [for (final e in entries.items) e.config.slotEntryId],
    since: since,
    before: before,
  );
  if (trainedSinceStart) {
    return null;
  }

  final sessions = await repository.getSessionsBefore(
    before: before,
    excludeRoutineId: routineId,
    excludeSince: since,
  );
  if (sessions.isEmpty) {
    return null;
  }

  final exerciseState = await ref.watch(exercisesProvider.future);
  List<String> musclesOf(int exerciseId) {
    final exercise = exerciseState.getByIdOrNull(exerciseId);
    return exercise == null ? const [] : overloadMuscles(exercise);
  }

  // The sessions before the switch as muscle group volumes
  final volumes = [
    for (final logs in sessions)
      muscleVolumes([
        for (final log in logs.where(_countsForBaseline))
          (
            muscles: musclesOf(log.exerciseId),
            sets: [OverloadSet(weight: log.weight, repetitions: log.repetitions!)],
          ),
      ]),
  ];

  final todaysEntries = <MuscleEntry>[];
  for (final entry in counted) {
    final muscles = overloadMuscles(entry.config.exercise);
    if (muscles.isEmpty) {
      continue;
    }
    final suggestions = await ref.watch(
      overloadSuggestionsProvider(
        exerciseId: entry.config.exerciseId,
        before: before,
        minReps: entry.config.repetitions,
        maxReps: entry.config.maxRepetitions,
        plannedSets: entry.plannedSets,
      ).future,
    );
    // The last time in this routine (e.g. its previous run): an exercise
    // shared with the previous programme was done there with other
    // repetitions, its weight doesn't fit today's. Any routine without one.
    final inRoutine = comparableSets(
      await repository.getLastSessionLogsByExercise(
        entry.config.exerciseId,
        before: before,
        routineId: routineId,
      ),
    );
    final lastSession = inRoutine.isNotEmpty ? inRoutine : suggestions.lastSession;
    todaysEntries.add(
      MuscleEntry(
        slotEntryId: entry.config.slotEntryId,
        muscles: muscles,
        lastSession: [
          for (final log in lastSession)
            OverloadSet(weight: log.weight, repetitions: log.repetitions!),
        ],
        plannedWeight: entry.config.weight,
        minReps: entry.config.repetitions,
        maxReps: entry.config.maxRepetitions,
        plannedSets: entry.plannedSets,
        maxSets: entry.config.maxNrOfSets?.toInt(),
        knownWeights: suggestions.knownWeights,
      ),
    );
  }

  final today = {for (final e in todaysEntries) ...e.muscles};
  final match = matchSession(today, [for (final v in volumes) v.keys.toSet()]);
  if (match == null) {
    return null;
  }

  final plan = planMuscleOverload(baseline: volumes[match], entries: todaysEntries);
  final matched = sessions[match];
  return MuscleOverloadPlan(
    baselineDate: matched.first.date,
    baselineRoutineId: matched.first.routineId,
    options: plan.options,
    targets: plan.targets,
  );
}

/// Whether a logged set counts towards the volume of a session before the
/// switch: counted in repetitions, with some
bool _countsForBaseline(Log log) =>
    log.repetitions != null &&
    log.repetitions! > 0 &&
    log.repetitionsUnitId == REP_UNIT_REPETITIONS_ID;
