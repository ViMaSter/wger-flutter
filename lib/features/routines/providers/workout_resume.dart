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

import 'dart:convert';

import 'package:clock/clock.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';
import 'package:material_ui/material_ui.dart';
import 'package:wger/core/shared_preferences.dart';
import 'package:wger/features/routines/models/workout_progress.dart';
import 'package:wger/features/routines/notifications/workout_notification_controller.dart';
import 'package:wger/features/routines/providers/gym_state.dart';
import 'package:wger/features/routines/screens/gym_mode.dart';

final _logger = Logger('workoutResume');

/// A workout to open again, as for the gym mode route
typedef ResumableWorkout = ({int routineId, int dayId, int iteration});

/// The workout to continue right at app start: one that is still running,
/// has at least one set logged and sets left, e.g. after the app was closed
/// or the session ran out. The stored progress of a finished workout is
/// removed, the app then starts normally.
///
/// Expired or unreadable progress is left to the gym mode, which discards it
/// when a workout is opened.
Future<ResumableWorkout?> workoutToResume() async {
  final prefs = PreferenceHelper.asyncPref;
  final stored = await prefs.getString(PREFS_WORKOUT_PROGRESS);
  if (stored == null) {
    return null;
  }

  final WorkoutProgress progress;
  try {
    progress = WorkoutProgress.fromJson(json.decode(stored) as Map<String, dynamic>);
  } catch (e) {
    _logger.warning('Stored workout progress is unreadable, not resuming: $e');
    return null;
  }

  final routineId = progress.routineId;
  final totalSets = progress.totalSets;
  if (routineId == null || totalSets == null || progress.validUntil.isBefore(clock.now())) {
    return null;
  }

  // Only the planned sets count, like in totalSets: the sets of an exercise
  // added during the workout don't make up for a planned one
  final done = progress.pages.entries
      .where((page) => page.value.done && isRequiredLogKey(page.key))
      .length;
  if (done >= totalSets) {
    _logger.fine('Every set of the stored workout is logged, starting normally');
    await prefs.remove(PREFS_WORKOUT_PROGRESS);
    return null;
  }
  if (done == 0) {
    return null;
  }

  return (routineId: routineId, dayId: progress.dayId, iteration: progress.iteration);
}

/// Opens the gym mode on a workout that was interrupted with sets left, e.g.
/// by closing the app or an expired session, see [workoutToResume]. Called
/// when the home screen appears; does nothing while the gym mode is open.
Future<void> continueInterruptedWorkout(BuildContext context, WidgetRef ref) async {
  final workout = await workoutToResume();
  if (workout == null || !context.mounted || ref.read(gymModeVisibleProvider)) {
    return;
  }
  _logger.info('Continuing the interrupted workout of day ${workout.dayId}');
  await Navigator.of(context).pushNamed(
    GymModeScreen.routeName,
    arguments: GymModeArguments(workout.routineId, workout.dayId, workout.iteration),
  );
}
