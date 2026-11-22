/*
 * This file is part of wger Workout Manager <https://github.com/wger-project>.
 * Copyright (c) 2026 wger Team
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
import 'package:wger/features/routines/models/log.dart';
import 'package:wger/features/routines/models/overload_option.dart';

part 'workout_progress.freezed.dart';
part 'workout_progress.g.dart';

/// The progress through a running workout, as stored in the preferences. The
/// pages themselves are derived from the routine again and matched by key.
@freezed
sealed class WorkoutProgress with _$WorkoutProgress {
  const factory WorkoutProgress({
    required int dayId,
    required int iteration,
    required String currentPageKey,
    required DateTime workoutStart,
    required DateTime validUntil,
    @Default({}) Map<String, StoredPageProgress> pages,

    /// To open the workout again right at app start, before the routine is
    /// loaded. Null in progress stored by older versions.
    int? routineId,

    /// The number of planned sets, so a finished workout is recognised
    /// without the routine. Null in progress stored by older versions.
    int? totalSets,

    /// The chosen progressive overload options, by slot entry ID
    @Default({}) Map<String, StoredOverloadChoice> overload,

    /// Slot entries whose option was chosen, also "as before"
    @Default([]) List<int> overloadDecided,

    /// Sets logged beyond the planned ones, by slot entry ID
    @Default({}) Map<String, List<StoredLog>> extraLogs,

    /// Values entered for sets that aren't logged yet, by row key
    @Default({}) Map<String, StoredRowDraft> drafts,

    /// Planned sets removed from the list layout, by page key
    @Default([]) List<String> removedRows,
  }) = _WorkoutProgress;

  factory WorkoutProgress.fromJson(Map<String, dynamic> json) => _$WorkoutProgressFromJson(json);
}

/// The stored part of a page's progress, the logged entry only by its ID
@freezed
sealed class StoredPageProgress with _$StoredPageProgress {
  const factory StoredPageProgress({
    @Default(false) bool done,
    String? logId,
    DateTime? timerStartedAt,

    /// The values of the logged entry, to send it again if the server lost it
    StoredLog? log,
  }) = _StoredPageProgress;

  factory StoredPageProgress.fromJson(Map<String, dynamic> json) =>
      _$StoredPageProgressFromJson(json);
}

/// A logged set as stored with the progress, enough to write it again
@freezed
sealed class StoredLog with _$StoredLog {
  const factory StoredLog({
    required String id,
    required int exerciseId,
    required DateTime date,
    int? routineId,
    String? sessionId,
    int? iteration,
    int? slotEntryId,
    num? rir,
    num? rirTarget,
    num? repetitions,
    num? repetitionsTarget,
    int? repetitionsUnitId,
    num? weight,
    num? weightTarget,
    int? weightUnitId,
  }) = _StoredLog;

  const StoredLog._();

  factory StoredLog.fromJson(Map<String, dynamic> json) => _$StoredLogFromJson(json);

  /// Null for a log that was never saved, it has no ID yet
  static StoredLog? fromLog(Log? log) {
    final id = log?.id;
    if (log == null || id == null) {
      return null;
    }
    return StoredLog(
      id: id,
      exerciseId: log.exerciseId,
      date: log.date,
      routineId: log.routineId,
      sessionId: log.sessionId,
      iteration: log.iteration,
      slotEntryId: log.slotEntryId,
      rir: log.rir,
      rirTarget: log.rirTarget,
      repetitions: log.repetitions,
      repetitionsTarget: log.repetitionsTarget,
      repetitionsUnitId: log.repetitionsUnitId,
      weight: log.weight,
      weightTarget: log.weightTarget,
      weightUnitId: log.weightUnitId,
    );
  }

  Log toLog() => Log(
    id: id,
    exerciseId: exerciseId,
    date: date,
    routineId: routineId,
    sessionId: sessionId,
    iteration: iteration,
    slotEntryId: slotEntryId,
    rir: rir,
    rirTarget: rirTarget,
    repetitions: repetitions,
    repetitionsTarget: repetitionsTarget,
    repetitionsUnitId: repetitionsUnitId,
    weight: weight,
    weightTarget: weightTarget,
    weightUnitId: weightUnitId,
  );
}

/// A chosen [OverloadOption] as stored with the progress
@freezed
sealed class StoredOverloadChoice with _$StoredOverloadChoice {
  const factory StoredOverloadChoice({
    required String type,
    @Default([]) List<StoredRowDraft> sets,
    int? requiredRepetitions,
  }) = _StoredOverloadChoice;

  const StoredOverloadChoice._();

  factory StoredOverloadChoice.fromJson(Map<String, dynamic> json) =>
      _$StoredOverloadChoiceFromJson(json);

  factory StoredOverloadChoice.fromOption(OverloadOption option) => StoredOverloadChoice(
    type: option.type.name,
    sets: [
      for (final set in option.sets)
        StoredRowDraft(weight: set.weight, repetitions: set.repetitions),
    ],
    requiredRepetitions: option.requiredRepetitions,
  );

  /// Null for a type this version doesn't know
  OverloadOption? toOption() {
    final overloadType = OverloadType.values.asNameMap()[type];
    if (overloadType == null) {
      return null;
    }
    return OverloadOption(
      type: overloadType,
      sets: [
        for (final set in sets) OverloadSet(weight: set.weight, repetitions: set.repetitions ?? 0),
      ],
      requiredRepetitions: requiredRepetitions,
    );
  }
}

/// Weight and repetitions entered for a set, either may be empty
@freezed
sealed class StoredRowDraft with _$StoredRowDraft {
  const factory StoredRowDraft({num? weight, num? repetitions}) = _StoredRowDraft;

  factory StoredRowDraft.fromJson(Map<String, dynamic> json) => _$StoredRowDraftFromJson(json);
}
