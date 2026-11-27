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
import 'package:equatable/equatable.dart';
import 'package:wger/features/routines/providers/gym_state.dart';
import 'package:wger/l10n/generated/app_localizations.dart';

/// How long before the end of a rest its warning sounds
const REST_WARNING_BEFORE = Duration(seconds: 30);

/// The audio cue shortly before the rest is over. Scheduled with the platform,
/// so it also sounds in the background, on a locked phone and over music.
class RestWarning extends Equatable {
  final DateTime at;
  final String title;
  final String body;

  const RestWarning({required this.at, required this.title, required this.body});

  @override
  List<Object?> get props => [at, title, body];
}

/// The warning for the countdown on the current timer page of [state], null
/// without one, with the alert off, or with [before] or less left at [now].
/// [languageCode] picks the exercise names, by default the language of [i18n].
RestWarning? buildRestWarning(
  GymModeState state,
  AppLocalizations i18n, {
  required DateTime now,
  Duration before = REST_WARNING_BEFORE,
  String? languageCode,
}) {
  if (!state.isInitialized || !state.alertOnCountdownEnd) {
    return null;
  }
  // Only the rest on the current page: skipping it moves on to the next page
  // and leaves its start behind
  final endsAt = state.restEndsAt;
  if (endsAt == null) {
    return null;
  }
  final at = endsAt.subtract(before);
  if (!at.isAfter(now)) {
    return null;
  }

  final current = state.getSlotEntryPageByIndex()!;
  final next = state.pages
      .expand((p) => p.slotPages)
      .firstWhereOrNull((p) => p.type == SlotPageType.log && p.pageIndex > current.pageIndex);
  final config = next?.setConfigData;
  final language = languageCode ?? i18n.localeName.split('_').first;
  return RestWarning(
    at: at,
    title: i18n.workoutNotificationRestEndsSoon(before.inSeconds),
    body: config == null
        ? ''
        : i18n.workoutNotificationNext(
            '${config.exercise.getTranslation(language).name} '
            '${config.textReprShort ?? config.textRepr}',
          ),
  );
}
