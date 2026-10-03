import 'package:clock/clock.dart';
import 'package:fake_async/fake_async.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:wger/features/routines/models/set_config_data.dart';
import 'package:wger/features/routines/providers/gym_rest_timer_provider.dart';
import 'package:wger/features/routines/providers/gym_state.dart';
import 'package:wger/features/routines/providers/gym_state_notifier.dart';
import 'package:wger/features/routines/widgets/gym_mode/timer.dart';
import 'package:wger/l10n/generated/app_localizations.dart';
import 'package:wger/l10n/localizations_delegates.dart';

import '../../../../../test_data/routines.dart';

void main() {
  late ProviderContainer container;
  late List<Map<String, dynamic>> updates;
  late int alerts;
  late PageController controller;
  late bool containerDisposed;

  void disposeContainer() {
    if (!containerDisposed) {
      container.dispose();
      containerDisposed = true;
    }
  }

  setUp(() {
    updates = [];
    alerts = 0;
    containerDisposed = false;
    container = ProviderContainer(
      overrides: [
        gymRestTimerWatchUpdateProvider.overrideWithValue((update) async => updates.add(update)),
        gymRestTimerAlertProvider.overrideWithValue(() async => alerts++),
      ],
    );
    controller = PageController();
  });

  tearDown(() {
    disposeContainer();
    controller.dispose();
  });

  void seed({num? minimum = 60, num? maximum = 120, bool countdown = true}) {
    final notifier = container.read(gymStateProvider.notifier);
    final config = SetConfigData(
      slotEntryId: 1,
      exerciseId: 1,
      restTime: minimum,
      maxRestTime: maximum,
    );
    notifier.state = GymModeState(
      isInitialized: true,
      dayId: 1,
      iteration: 1,
      routine: getTestRoutine(),
      useCountdownBetweenSets: countdown,
      countdownDuration: const Duration(seconds: 180),
      showWorkoutDuration: false,
      currentPage: 1,
      pages: [
        PageEntry(type: PageType.start, pageIndex: 0),
        PageEntry(
          type: PageType.set,
          pageIndex: 1,
          slotPages: [
            SlotPageEntry(
              type: SlotPageType.timer,
              pageIndex: 1,
              setIndex: 1,
              setConfigData: config,
            ),
            SlotPageEntry(type: SlotPageType.log, pageIndex: 2, setIndex: 1, setConfigData: config),
          ],
        ),
      ],
    );
  }

  Future<void> pumpTimer(WidgetTester tester, {bool countdown = true}) async {
    addTearDown(disposeContainer);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          locale: const Locale('en'),
          localizationsDelegates: appLocalizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: countdown ? TimerCountdownWidget(controller, 180) : TimerWidget(controller),
          ),
        ),
      ),
    );
    await tester.pump();
  }

  testWidgets('persists across rebuild and unmount, controls reset to set min/max', (tester) async {
    await withClock(
      Clock(tester.binding.clock.now),
      () async {
        seed();
        await pumpTimer(tester);
        final timer = container.read(gymRestTimerProvider);
        final deadline = timer.endTime;
        expect(timer.remainingSeconds, 60);
        await pumpTimer(tester);
        expect(timer.endTime, deadline);
        await tester.tap(find.byKey(const ValueKey('rest-timer-plus')));
        expect(timer.endTime, deadline!.add(const Duration(seconds: 15)));
        await tester.tap(find.byKey(const ValueKey('rest-timer-minus')));
        expect(timer.endTime, deadline);
        await tester.tap(find.byKey(const ValueKey('rest-timer-max')));
        expect(timer.remainingSeconds, 120);
        await tester.tap(find.byKey(const ValueKey('rest-timer-min')));
        expect(timer.remainingSeconds, 60);
        final resetDeadline = timer.endTime;
        await tester.pumpWidget(const SizedBox());
        await tester.pump(const Duration(seconds: 10));
        await pumpTimer(tester);
        expect(timer.endTime, resetDeadline);
        expect(timer.remainingSeconds, 50);
        expect(updates.last['timer'], {'endTimeISO8601': resetDeadline!.toIso8601String()});
        await tester.pumpWidget(const SizedBox());
      },
    );
  });

  testWidgets('expiry while disposed clears watch once and a later entry starts again', (
    tester,
  ) async {
    seed(minimum: 2);
    await pumpTimer(tester);
    final timer = container.read(gymRestTimerProvider);
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 2));
    expect(timer.endTime, isNull);
    expect(alerts, 1);
    expect(updates.last, {
      'timer': {'endTimeISO8601': null},
    });
    await tester.pump(const Duration(seconds: 10));
    expect(alerts, 1);
    await pumpTimer(tester);
    expect(timer.endTime, isNotNull);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('elapsed rest timer also persists across remount', (tester) async {
    await withClock(Clock(tester.binding.clock.now), () async {
      seed(minimum: null, maximum: null, countdown: false);
      await pumpTimer(tester, countdown: false);
      await tester.pump(const Duration(seconds: 10));
      expect(find.text('0:10'), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(seconds: 5));
      await pumpTimer(tester, countdown: false);
      expect(find.text('0:15'), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
    });
  });

  testWidgets('expiry stays at zero on rebuild until explicit reset', (tester) async {
    seed(minimum: 1);
    await pumpTimer(tester);
    final timer = container.read(gymRestTimerProvider);
    await tester.pump(const Duration(seconds: 1));
    await tester.pump();
    expect(timer.endTime, isNull);
    expect(find.text('0:00'), findsOneWidget);
    await pumpTimer(tester);
    expect(timer.endTime, isNull);
    expect(alerts, 1);
    await tester.tap(find.byKey(const ValueKey('rest-timer-min')));
    expect(timer.endTime, isNotNull);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('user countdown is fallback only, max without config is disabled', (tester) async {
    seed(minimum: null, maximum: null);
    await pumpTimer(tester);
    final timer = container.read(gymRestTimerProvider);
    expect(timer.remainingSeconds, 180);
    final maximum = tester.widget<IconButton>(find.byKey(const ValueKey('rest-timer-max')));
    expect(maximum.onPressed, isNull);
    timer.adjust(15);
    await tester.tap(find.byKey(const ValueKey('rest-timer-min')));
    expect(timer.remainingSeconds, 180);
    await tester.pumpWidget(const SizedBox());
  });

  test('page changes retain deadline, workout reset clears it without alerting', () {
    fakeAsync((time) {
      withClock(Clock(() => DateTime.utc(2026).add(time.elapsed)), () {
        seed();
        final timer = container.read(gymRestTimerProvider);
        timer.ensureStarted(60);
        final deadline = timer.endTime;
        final notifier = container.read(gymStateProvider.notifier);
        notifier.state = notifier.state.copyWith(currentPage: 2);
        expect(timer.endTime, deadline);
        time.elapse(const Duration(seconds: 10));
        notifier.startWorkout();
        expect(timer.endTime, isNull);
        expect(alerts, 0);
        expect(updates.last, {
          'timer': {'endTimeISO8601': null},
        });
        timer.ensureStarted(60);
        notifier.clear();
        expect(timer.endTime, isNull);
        time.elapse(const Duration(seconds: 120));
        expect(alerts, 0);
      });
    });
  });

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
}
