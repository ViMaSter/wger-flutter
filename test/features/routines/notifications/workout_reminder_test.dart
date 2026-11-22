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

import 'package:clock/clock.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';
import 'package:wger/features/routines/models/log.dart';
import 'package:wger/features/routines/models/page_progress.dart';
import 'package:wger/features/routines/notifications/workout_reminder.dart';
import 'package:wger/features/routines/providers/gym_state.dart';
import 'package:wger/features/routines/providers/gym_state_notifier.dart';
import 'package:wger/l10n/generated/app_localizations.dart';

import '../../../../test_data/routines.dart';

void main() {
  final start = DateTime.utc(2025, 3, 29, 14);
  final i18n = lookupAppLocalizations(const Locale('en'));
  late GymStateNotifier notifier;

  setUp(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferencesAsyncPlatform.instance = InMemorySharedPreferencesAsync.empty();
    final container = ProviderContainer.test();
    notifier = container.read(gymStateProvider.notifier);
    final routine = getTestRoutine();
    withClock(Clock.fixed(start), () => notifier.initData(routine, routine.days.first.id!, 1));

    // The fixture puts both exercises into slot entry 1, in the app each has
    // its own
    for (final page in notifier.state.pages.expand((p) => p.slotPages)) {
      final config = page.setConfigData;
      if (config != null && config.exercise.getTranslation('en').name == 'Side raises') {
        config.slotEntryId = 2;
      }
    }
  });

  // Fixture: bench press (3 sets), then side raises (3 sets)
  List<List<SlotPageEntry>> blocks() => notifier.state.logPagesBySlotEntry;

  MissingEntriesReminder? build() =>
      buildMissingEntriesReminder(notifier.state, i18n, languageCode: 'en');

  /// Marks [pages] as logged, each at [at]
  void logAll(Iterable<SlotPageEntry> pages, DateTime at) {
    notifier.state = notifier.state.copyWith(
      progress: {
        ...notifier.state.progress,
        for (final page in pages)
          page.key: PageProgress(
            done: true,
            loggedEntry: Log(exerciseId: page.setConfigData!.exerciseId, date: at),
          ),
      },
    );
  }

  test('Nothing before the first logged set, the workout never started', () {
    expect(build(), isNull);

    logAll([blocks().first.first], start.add(const Duration(minutes: 5)));
    final reminder = build()!;

    expect(
      reminder.at.isAtSameMomentAs(start.add(const Duration(minutes: 5) + WORKOUT_REMINDER_DELAY)),
      isTrue,
    );
    expect(reminder.title, 'Missed any entries?');
  });

  test('An extra set alone also starts the workout', () {
    final slotEntryId = blocks().first.first.setConfigData!.slotEntryId;
    notifier.state = notifier.state.copyWith(
      extraLogs: {
        slotEntryId: [Log(exerciseId: 1, date: start)],
      },
    );

    expect(build(), isNotNull);
  });

  test('Due a delay after the last logged set', () {
    logAll([blocks().first.first], start.add(const Duration(minutes: 5)));
    logAll([blocks().first[1]], start.add(const Duration(minutes: 12)));

    final reminder = buildMissingEntriesReminder(
      notifier.state,
      i18n,
      delay: const Duration(minutes: 10),
      languageCode: 'en',
    )!;

    expect(reminder.at.isAtSameMomentAs(start.add(const Duration(minutes: 22))), isTrue);
  });

  test('Names the first exercise with missing sets and counts the others', () {
    // One logged set still leaves the exercise incomplete
    logAll([blocks().first.first], start);
    expect(build()!.body, 'Bench press and 1 other exercise are missing entries');

    logAll(blocks().first, start);
    expect(build()!.body, 'Side raises is missing entries');
  });

  test('Counts several other exercises in the plural', () {
    // A third exercise, built here so the shared fixture stays as it is
    final template = blocks().last.first;
    final lastPage = notifier.state.pages.last;
    notifier.state = notifier.state.copyWith(
      pages: [
        ...notifier.state.pages,
        PageEntry(
          type: PageType.set,
          pageIndex: lastPage.pageIndex + 1,
          key: 'third',
          slotPages: [
            SlotPageEntry(
              type: SlotPageType.log,
              pageIndex: lastPage.pageIndex + 1,
              setIndex: 0,
              key: 'log:third',
              setConfigData: template.setConfigData!.copyWith(slotEntryId: 999),
            ),
          ],
        ),
      ],
    );

    logAll([blocks().first.first], start);
    expect(build()!.body, 'Bench press and 2 other exercises are missing entries');
  });

  test('Nothing once every planned set is logged, extra sets change nothing', () {
    final slotEntryId = blocks().first.first.setConfigData!.slotEntryId;
    // An extra set doesn't stand in for a planned one
    notifier.state = notifier.state.copyWith(
      extraLogs: {
        slotEntryId: [Log(exerciseId: 1, date: start)],
      },
    );
    logAll(blocks().expand((pages) => pages).skip(1), start);
    expect(build(), isNotNull);

    logAll(blocks().expand((pages) => pages), start);
    expect(build(), isNull);
  });

  test('Nothing without a running workout', () {
    // E.g. ended, with the pages still there
    notifier.state = notifier.state.copyWith(isInitialized: false);

    expect(build(), isNull);
  });
}
