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
import 'package:wger/features/routines/notifications/workout_rest_warning.dart';
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
    notifier = ProviderContainer.test().read(gymStateProvider.notifier);
    final routine = getTestRoutine();
    withClock(Clock.fixed(start), () => notifier.initData(routine, routine.days.first.id!, 1));
  });

  SlotPageEntry firstTimer() => notifier.state.pages
      .expand((p) => p.slotPages)
      .firstWhere((p) => p.type == SlotPageType.timer);

  /// On the first rest of the fixture (120 s), started at [start]
  void startRest() {
    final timer = firstTimer();
    withClock(Clock.fixed(start), () {
      notifier.setCurrentPage(timer.pageIndex - 1);
      notifier.setCurrentPage(timer.pageIndex);
    });
  }

  RestWarning? buildAt(DateTime now) =>
      buildRestWarning(notifier.state, i18n, now: now, languageCode: 'en');

  test('Sounds 30 seconds before the end of the rest, with the next set', () {
    startRest();

    final warning = buildAt(start)!;

    expect(warning.at.isAtSameMomentAs(start.add(const Duration(seconds: 90))), isTrue);
    expect(warning.title, '30 seconds of rest left');
    expect(warning.body, startsWith('Next: Bench press'));
  });

  test('Nothing without a running rest', () {
    expect(buildAt(start), isNull);
  });

  test('Nothing once 30 seconds or less are left', () {
    startRest();

    expect(buildAt(start.add(const Duration(seconds: 89))), isNotNull);
    expect(buildAt(start.add(const Duration(seconds: 90))), isNull);
  });

  test('Nothing with the alert off', () {
    startRest();
    notifier.state = notifier.state.copyWith(alertOnCountdownEnd: false);

    expect(buildAt(start), isNull);
  });

  test('Nothing after skipping the rest, its start stays behind', () {
    startRest();
    withClock(Clock.fixed(start), notifier.skipRest);

    expect(notifier.state.progressOf(firstTimer().key).timerStartedAt, isNotNull);
    expect(buildAt(start), isNull);
  });

  test('Moves along when the rest is extended', () {
    startRest();
    withClock(Clock.fixed(start), () => notifier.extendRest(const Duration(seconds: 15)));

    expect(
      buildAt(start)!.at.isAtSameMomentAs(start.add(const Duration(seconds: 105))),
      isTrue,
    );
  });
}
