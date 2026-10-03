/*
 * This file is part of wger Workout Manager <https://github.com/wger-project>.
 * Copyright (c) 2026 wger Team
 *
 * wger Workout Manager is free software: you can redistribute it and/or modify
 * it under the terms of the GNU Affero General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * wger Workout Manager is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU Affero General Public License for more details.
 *
 * You should have received a copy of the GNU Affero General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

import 'package:clock/clock.dart';
import 'package:fake_async/fake_async.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';
import 'package:wger/features/routines/models/page_progress.dart';
import 'package:wger/features/routines/providers/gym_rest_timer_provider.dart';
import 'package:wger/features/routines/providers/gym_state.dart';
import 'package:wger/features/routines/providers/gym_state_notifier.dart';
import 'package:wger/features/routines/services/gym_rest_timer.dart';
import 'package:wger/features/routines/widgets/gym_mode/timer.dart';
import 'package:wger/l10n/generated/app_localizations.dart';

import '../../../../../test_data/routines.dart' as testdata;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Timer up-next', () {
    late ProviderContainer container;

    // Page structure of the test routine (exercise + timer pages enabled):
    //   start(0)
    //   slot 1 (bench press): overview(1), log(2), timer(3), log(4), timer(5), log(6), timer(7)
    //   slot 2 (side raises): overview(8), log(9), timer(10), log(11), timer(12), log(13), timer(14)
    //   session(15), summary(16)
    setUp(() {
      SharedPreferencesAsyncPlatform.instance = InMemorySharedPreferencesAsync.empty();
      container = ProviderContainer.test();
      final notifier = container.read(gymStateProvider.notifier);
      final routine = testdata.getTestRoutine();
      notifier.initData(routine, routine.days.first.id!, 1);
    });

    Future<void> pumpTimer(WidgetTester tester, int timerPageIndex, {bool countsUp = false}) async {
      final slotPage = container.read(gymStateProvider).getSlotEntryPageByIndex(timerPageIndex)!;
      expect(slotPage.type, SlotPageType.timer);

      // No pumpAndSettle: the widgets keep a periodic UI timer alive, which
      // would never settle.
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            locale: const Locale('en'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(
              body: Builder(
                builder: (context) {
                  final controller = PageController();
                  return PageView(
                    controller: controller,
                    children: [
                      if (countsUp)
                        TimerWidget(controller, slotPage.key)
                      else
                        TimerCountdownWidget(controller, 90, slotPage.key),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      );
      await tester.pump();
    }

    testWidgets('shows the next set of the same exercise for a rest between sets', (tester) async {
      await pumpTimer(tester, 3);

      expect(find.text('Up next'), findsOneWidget);
      expect(find.text('Bench press'), findsOneWidget);
      expect(find.text('3x100kg'), findsOneWidget);
      expect(find.text('2 / 3'), findsOneWidget);
    });

    testWidgets('shows the next exercise after the final rest of an exercise', (tester) async {
      await pumpTimer(tester, 7);

      expect(find.text('Up next'), findsOneWidget);
      expect(find.text('Side raises'), findsOneWidget);
      expect(find.text('12x10kg'), findsOneWidget);
      expect(find.text('1 / 3'), findsOneWidget);
    });

    testWidgets('shows nothing after the last set of the day', (tester) async {
      await pumpTimer(tester, 14);

      expect(find.text('Up next'), findsNothing);
    });

    testWidgets('countdown continues when the page is disposed and re-created', (tester) async {
      final t0 = DateTime(2024, 5, 2, 12);

      await withClock(Clock.fixed(t0), () async {
        await pumpTimer(tester, 3);
        expect(find.text('1:30'), findsOneWidget);
      });

      // 30s later the countdown kept running (re-pumping forces a rebuild,
      // in the app the periodic UI timer does this every second)
      await withClock(Clock.fixed(t0.add(const Duration(seconds: 30))), () async {
        await pumpTimer(tester, 3);
        expect(find.text('1:00'), findsOneWidget);
      });

      // Leaving the page disposes the widget ...
      await withClock(Clock.fixed(t0.add(const Duration(seconds: 45))), () async {
        await tester.pumpWidget(const SizedBox());
        await tester.pump();

        // ... and coming back must not restart the countdown
        await pumpTimer(tester, 3);
        expect(find.text('0:45'), findsOneWidget);
      });
    });

    testWidgets('counts up from the start in the gym state', (tester) async {
      final t0 = DateTime(2024, 5, 2, 12);
      final key = container.read(gymStateProvider).getSlotEntryPageByIndex(3)!.key;
      final notifier = container.read(gymStateProvider.notifier);
      notifier.state = notifier.state.copyWith(
        progress: {key: PageProgress(timerStartedAt: t0.subtract(const Duration(seconds: 30)))},
      );

      await withClock(Clock.fixed(t0), () => pumpTimer(tester, 3, countsUp: true));

      expect(find.text('0:30'), findsOneWidget);
    });
  });

  group('Rest timer controls, alerts and watch', () {
    late ProviderContainer container;
    late List<Map<String, dynamic>> updates;
    late int alerts;
    late bool foreground;
    late String timerKey;
    final t0 = DateTime(2024, 5, 2, 12);

    // Timer page 3 rests 120 s (see the page structure above)
    const timerPage = 3;
    const rest = Duration(seconds: 120);

    setUp(() {
      SharedPreferencesAsyncPlatform.instance = InMemorySharedPreferencesAsync.empty();
      updates = [];
      alerts = 0;
      foreground = true;
      container = ProviderContainer.test(
        overrides: [
          gymRestTimerWatchUpdateProvider.overrideWithValue((update) async => updates.add(update)),
          gymRestTimerAlertProvider.overrideWithValue(() async => alerts++),
          gymRestTimerForegroundProvider.overrideWithValue(() => foreground),
        ],
      );
      final notifier = container.read(gymStateProvider.notifier);
      final routine = testdata.getTestRoutine();
      notifier.initData(routine, routine.days.first.id!, 1);
      timerKey = notifier.state.getSlotEntryPageByIndex(timerPage)!.key;
    });

    GymStateNotifier notifier() => container.read(gymStateProvider.notifier);

    /// Starts the rest of the timer page at [startedAt] and shows [page]
    void startRest(DateTime startedAt, {int page = timerPage}) {
      notifier().state = notifier().state.copyWith(
        currentPage: page,
        progress: {timerKey: PageProgress(timerStartedAt: startedAt)},
      );
    }

    Map<String, dynamic> watchTimer(DateTime? end) => {
      'timer': {'endTimeISO8601': end?.toIso8601String()},
    };

    Future<void> pumpCountdown(WidgetTester tester) async {
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            locale: const Locale('en'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(
              body: Builder(
                builder: (context) {
                  final controller = PageController();
                  return PageView(
                    controller: controller,
                    children: [TimerCountdownWidget(controller, rest.inSeconds, timerKey)],
                  );
                },
              ),
            ),
          ),
        ),
      );
      await tester.pump();
    }

    testWidgets('+/-15 s and min/max resets move the countdown in the gym state', (tester) async {
      container
              .read(gymStateProvider)
              .getSlotEntryPageByIndex(timerPage)!
              .setConfigData!
              .maxRestTime =
          180;

      await withClock(Clock.fixed(t0), () async {
        startRest(t0);
        await pumpCountdown(tester);
        expect(find.text('2:00'), findsOneWidget);

        await tester.tap(find.byKey(const ValueKey('rest-timer-plus')));
        await tester.pump();
        expect(container.read(gymStateProvider).restEndsAt, t0.add(const Duration(seconds: 135)));
        expect(find.text('2:15'), findsOneWidget);

        await tester.tap(find.byKey(const ValueKey('rest-timer-minus')));
        await tester.pump();
        expect(container.read(gymStateProvider).restEndsAt, t0.add(rest));

        await tester.tap(find.byKey(const ValueKey('rest-timer-max')));
        await tester.pump();
        expect(find.text('3:00'), findsOneWidget);

        await tester.tap(find.byKey(const ValueKey('rest-timer-min')));
        await tester.pump();
        expect(find.text('2:00'), findsOneWidget);
      });

      // The reset countdown keeps running after the page is re-created
      await withClock(Clock.fixed(t0.add(const Duration(seconds: 10))), () async {
        await tester.pumpWidget(const SizedBox());
        await pumpCountdown(tester);
        expect(find.text('1:50'), findsOneWidget);
      });
    });

    testWidgets('max reset is disabled without a maximum rest, -15 s once the rest is over', (
      tester,
    ) async {
      await withClock(Clock.fixed(t0), () async {
        startRest(t0.subtract(const Duration(seconds: 200)));
        await pumpCountdown(tester);
      });

      IconButton button(String key) => tester.widget<IconButton>(find.byKey(ValueKey(key)));
      expect(button('rest-timer-max').onPressed, isNull);
      expect(button('rest-timer-minus').onPressed, isNull);
      expect(button('rest-timer-plus').onPressed, isNotNull);
      expect(button('rest-timer-min').onPressed, isNotNull);
    });

    test('alerts once at the end, also from another page, and mirrors it to the watch', () {
      fakeAsync((time) {
        withClock(Clock(() => t0.add(time.elapsed)), () {
          container.read(gymRestTimerProvider);
          startRest(t0);
          time.flushMicrotasks();
          expect(updates.last, watchTimer(t0.add(rest)));

          // Swiping on to the next set doesn't stop the rest
          notifier().state = notifier().state.copyWith(currentPage: timerPage + 1);
          time.elapse(const Duration(seconds: 119));
          expect(alerts, 0);

          time.elapse(const Duration(seconds: 1));
          expect(alerts, 1);
          expect(updates.last, watchTimer(null));

          // Returning to the expired rest doesn't alert again
          notifier().state = notifier().state.copyWith(currentPage: timerPage);
          time.elapse(const Duration(seconds: 60));
          expect(alerts, 1);
        });
      });
    });

    test('extending after the end alerts again, shortening past zero alerts at once', () {
      fakeAsync((time) {
        withClock(Clock(() => t0.add(time.elapsed)), () {
          container.read(gymRestTimerProvider);
          startRest(t0);
          time.elapse(rest);
          expect(alerts, 1);

          notifier().extendRest(const Duration(seconds: 30));
          time.elapse(const Duration(seconds: 29));
          expect(alerts, 1);
          time.elapse(const Duration(seconds: 1));
          expect(alerts, 2);

          notifier().resetRest(const Duration(seconds: 10));
          time.flushMicrotasks();
          expect(updates.last, watchTimer(clock.now().add(const Duration(seconds: 10))));
          notifier().extendRest(const Duration(seconds: -15));
          time.flushMicrotasks();
          expect(alerts, 3);
          expect(updates.last, watchTimer(null));
        });
      });
    });

    test('a rest that is already over when gym mode opens does not alert', () {
      fakeAsync((time) {
        withClock(Clock(() => t0.add(time.elapsed)), () {
          startRest(t0.subtract(const Duration(minutes: 10)));
          container.read(gymRestTimerProvider);
          time.elapse(const Duration(minutes: 5));
          expect(alerts, 0);
          expect(updates, isEmpty);
        });
      });
    });

    test('workout reset clears the watch without alerting', () {
      fakeAsync((time) {
        withClock(Clock(() => t0.add(time.elapsed)), () {
          container.read(gymRestTimerProvider);
          startRest(t0);
          time.elapse(const Duration(seconds: 10));
          notifier().state = notifier().state.copyWith(progress: {});
          time.elapse(const Duration(minutes: 5));
          expect(alerts, 0);
          expect(updates.last, watchTimer(null));
        });
      });
    });

    test('no in-app alert when switched off or in the background', () {
      fakeAsync((time) {
        withClock(Clock(() => t0.add(time.elapsed)), () {
          container.read(gymRestTimerProvider);
          notifier().state = notifier().state.copyWith(alertOnCountdownEnd: false);
          startRest(t0);
          time.elapse(rest);
          expect(alerts, 0);
          expect(updates.last, watchTimer(null), reason: 'the watch is still updated');

          notifier().state = notifier().state.copyWith(alertOnCountdownEnd: true);
          foreground = false;
          notifier().extendRest(const Duration(seconds: 5));
          time.elapse(const Duration(seconds: 5));
          expect(alerts, 0);
        });
      });
    });

    test('activeRestEnd prefers the current timer page over a later started rest', () {
      final state = container.read(gymStateProvider);
      final otherKey = state.getSlotEntryPageByIndex(5)!.key;
      final current = state.copyWith(
        currentPage: timerPage,
        progress: {
          timerKey: PageProgress(timerStartedAt: t0),
          otherKey: PageProgress(timerStartedAt: t0.add(const Duration(minutes: 1))),
        },
      );
      expect(activeRestEnd(current), t0.add(rest));
      expect(
        activeRestEnd(current.copyWith(currentPage: 4)),
        t0.add(const Duration(minutes: 1)).add(rest),
      );
    });
  });

  group('End of rest vibration', () {
    test('unsupported vibrator does not vibrate or probe custom support', () async {
      var sounds = 0;
      await notifyRestTimerExpired(
        hasVibrator: () async => false,
        hasCustomVibrationsSupport: () async => throw StateError('must not probe'),
        vibrate: ({duration = 0, pattern = const []}) async => throw StateError('must not vibrate'),
        sound: () async => sounds++,
      );
      expect(sounds, 1);
    });

    test('missing vibration plugin still permits expiry sound', () async {
      var sounds = 0;
      await notifyRestTimerExpired(
        hasVibrator: () async => throw MissingPluginException(),
        sound: () async => sounds++,
      );
      expect(sounds, 1);
    });

    test('supported vibration selects custom pattern or duration fallback', () async {
      final patterns = <List<int>>[];
      final durations = <int>[];
      for (final customSupport in [true, false]) {
        await notifyRestTimerExpired(
          hasVibrator: () async => true,
          hasCustomVibrationsSupport: () async => customSupport,
          vibrate: ({duration = 0, pattern = const []}) async {
            durations.add(duration);
            patterns.add(pattern);
          },
          sound: () async {},
        );
      }
      expect(patterns, [
        [0, 300, 150, 600],
        [],
      ]);
      expect(durations, [700, 700]);
    });
  });
}
