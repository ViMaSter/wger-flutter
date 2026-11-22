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

import 'package:equatable/equatable.dart';
import 'package:wger/features/routines/providers/gym_state.dart';
import 'package:wger/l10n/generated/app_localizations.dart';

/// How long a running workout may go without a logged set before the user is
/// reminded of the missing entries
const WORKOUT_REMINDER_DELAY = Duration(minutes: 30);

/// Payload of the reminder, tapping it opens the first missing set
const WORKOUT_REMINDER_PAYLOAD = 'workout-reminder';

/// The notification that reminds the user of sets not logged yet, after a
/// while without logging anything
class MissingEntriesReminder extends Equatable {
  final DateTime at;
  final String title;
  final String body;

  /// Name of the Android notification channel
  final String channelName;

  const MissingEntriesReminder({
    required this.at,
    required this.title,
    required this.body,
    required this.channelName,
  });

  @override
  List<Object?> get props => [at, title, body, channelName];
}

/// The reminder for the workout [state] runs, null without a running workout,
/// before its first logged set (a workout nothing was logged in never
/// started) or once every planned set is logged.
///
/// It is due [delay] after the last logged set. [languageCode] picks the exercise names,
/// by default the language of [i18n].
MissingEntriesReminder? buildMissingEntriesReminder(
  GymModeState state,
  AppLocalizations i18n, {
  Duration delay = WORKOUT_REMINDER_DELAY,
  String? languageCode,
}) {
  if (!state.isInitialized) {
    return null;
  }
  final missing = state.missingRequired;
  if (missing.isEmpty || _loggedDates(state).isEmpty) {
    return null;
  }

  final exercise = missing.first.exercise
      .getTranslation(languageCode ?? i18n.localeName.split('_').first)
      .name;
  return MissingEntriesReminder(
    at: _lastActivity(state).add(delay),
    title: i18n.workoutReminderTitle,
    body: i18n.workoutReminderBody(exercise, missing.length - 1),
    // There is no channel name of its own yet
    channelName: i18n.workoutReminderTitle,
  );
}

/// The dates of the sets logged in this workout, planned and extra ones.
///
/// The date of a log is when its form was opened, or when a set was logged
/// without the form (notification, list layout), close to when it was saved.
List<DateTime> _loggedDates(GymModeState state) => [
  for (final progress in state.progress.values)
    if (progress.done && progress.loggedEntry != null) progress.loggedEntry!.date,
  for (final logs in state.extraLogs.values) ...logs.map((log) => log.date),
];

/// When a set was last logged in this workout, not before its start
DateTime _lastActivity(GymModeState state) =>
    // Logs of an earlier session restored with the progress don't move it back
    _loggedDates(state).fold(
      state.workoutStart,
      (last, date) => date.isAfter(last) ? date : last,
    );
