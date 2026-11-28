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

import 'dart:io';

import 'package:extended_image/extended_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:wger/features/routines/notifications/workout_notification_content.dart';
import 'package:wger/features/routines/notifications/workout_notification_service.dart';
import 'package:wger/features/routines/notifications/workout_reminder.dart';
import 'package:wger/features/routines/notifications/workout_rest_warning.dart';

void main() {
  final binding = TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('dexterous.com/flutter/local_notifications');
  late List<MethodCall> calls;
  late bool exactAllowed;

  const labels = WorkoutNotificationLabels(
    logSet: 'Log set',
    skipRest: 'Skip rest',
    extendRest: '+30 s',
    shortenRest: '−15 s',
    lengthenRest: '+15 s',
    maxRest: 'Max',
    controlsChannel: 'Workout',
    alarmChannel: 'Rest alarm',
    notLoggedTitle: 'Set not logged',
    notLoggedBody: 'Open gym mode',
  );
  final payload = WorkoutNotificationPayload(
    routineId: 1,
    dayId: 1,
    iteration: 1,
    workoutStart: DateTime.utc(2025, 3, 29, 14, 33),
  );

  setUpAll(tzdata.initializeTimeZones);

  group('actionHandled', () {
    const tasksChannel = MethodChannel('de.wger.flutter/notification_actions');
    late List<String> taskCalls;

    setUp(() {
      taskCalls = [];
      binding.defaultBinaryMessenger.setMockMethodCallHandler(tasksChannel, (call) async {
        taskCalls.add(call.method);
        return null;
      });
      addTearDown(
        () => binding.defaultBinaryMessenger.setMockMethodCallHandler(tasksChannel, null),
      );
    });

    test('Ends the background task on iOS', () async {
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
      addTearDown(() => debugDefaultTargetPlatformOverride = null);

      await LocalWorkoutNotificationService().actionHandled();

      expect(taskCalls, ['actionHandled']);
    });

    test('Does nothing on Android, which keeps no task', () async {
      await LocalWorkoutNotificationService().actionHandled();

      expect(taskCalls, isEmpty);
    });
  });

  setUp(() {
    // The Android side of the plugin, talking to a fake platform channel
    FlutterLocalNotificationsPlatform.instance = AndroidFlutterLocalNotificationsPlugin();
    calls = [];
    exactAllowed = true;
    binding.defaultBinaryMessenger.setMockMethodCallHandler(channel, (call) async {
      calls.add(call);
      return switch (call.method) {
        'canScheduleExactNotifications' => exactAllowed,
        'initialize' => true,
        _ => null,
      };
    });
    addTearDown(() => binding.defaultBinaryMessenger.setMockMethodCallHandler(channel, null));
  });

  Map<Object?, Object?> scheduled() =>
      (calls.singleWhere((c) => c.method == 'zonedSchedule').arguments as Map)['platformSpecifics']
          as Map;

  RestAlarm alarm({
    bool canLogSet = true,
    bool canExtendRest = false,
    List<String> quickLogs = const [],
    Uri? image,
  }) => RestAlarm(
    at: DateTime.now().add(const Duration(minutes: 2)),
    title: 'Rest is over',
    body: 'Next: Bench press',
    canLogSet: canLogSet,
    canExtendRest: canExtendRest,
    payload: payload,
    quickLogs: quickLogs,
    image: image,
  );

  Map<Object?, Object?> shown() =>
      (calls.singleWhere((c) => c.method == 'show').arguments as Map)['platformSpecifics'] as Map;

  test('Initializes with the monochrome status bar icon', () async {
    await LocalWorkoutNotificationService().initialize(labels);

    final init = calls.singleWhere((c) => c.method == 'initialize').arguments as Map;
    expect(init['defaultIcon'], 'ic_stat_wger');
  });

  test('The rest alarm is exact when allowed', () async {
    await LocalWorkoutNotificationService().scheduleRestAlarm(alarm(), labels);

    expect(scheduled()['scheduleMode'], AndroidScheduleMode.exactAllowWhileIdle.name);
  });

  test('Without the exact alarm permission it falls back to an inexact alarm', () async {
    exactAllowed = false;

    await LocalWorkoutNotificationService().scheduleRestAlarm(alarm(), labels);

    expect(scheduled()['scheduleMode'], AndroidScheduleMode.inexactAllowWhileIdle.name);
  });

  test('The alarm only offers "Log set" when the set can be logged', () async {
    final service = LocalWorkoutNotificationService();

    await service.scheduleRestAlarm(alarm(), labels);
    expect(
      (scheduled()['actions'] as List).map((a) => (a as Map)['id']),
      [WORKOUT_NOTIFICATION_ACTION_LOG_SET],
    );

    calls.clear();
    await service.scheduleRestAlarm(alarm(canLogSet: false), labels);
    expect(scheduled()['actions'], anyOf(isNull, isEmpty));
  });

  List<Object?> actionIds(Map<Object?, Object?> details) =>
      (details['actions'] as List).map((a) => (a as Map)['id']).toList();

  group('Rest timer', () {
    test('A running rest is a Live Update with -/+ and max, in app order', () async {
      final endsAt = DateTime.now().add(const Duration(minutes: 2));
      await LocalWorkoutNotificationService().showControls(
        WorkoutControls(
          title: 'wger – Timer',
          body: 'Next: Bench press',
          payload: payload,
          isTimer: true,
          chronometerAt: endsAt,
          chronometerCountsDown: true,
          canShortenRest: true,
          canLengthenRest: true,
          maxRest: const Duration(minutes: 3),
        ),
        labels,
      );

      expect(shown()['requestPromotedOngoing'], isTrue);
      expect(shown()['ongoing'], isTrue);
      expect(shown()['usesChronometer'], isTrue);
      expect(shown()['chronometerCountDown'], isTrue);
      expect(shown()['when'], endsAt.millisecondsSinceEpoch);
      expect(actionIds(shown()), [
        WORKOUT_NOTIFICATION_ACTION_SHORTEN_REST,
        WORKOUT_NOTIFICATION_ACTION_LENGTHEN_REST,
        WORKOUT_NOTIFICATION_ACTION_MAX_REST,
      ]);
      expect((shown()['actions'] as List).map((a) => (a as Map)['title']), [
        '−15 s',
        '+15 s',
        'Max',
      ]);
    });

    test('Other controls are not promoted', () async {
      await LocalWorkoutNotificationService().showControls(
        WorkoutControls(title: 'Bench press', body: 'Set 2 of 3', payload: payload),
        labels,
      );

      expect(shown()['requestPromotedOngoing'], isFalse);
    });

    test('Its end replaces it in place: still promoted, counting on, sounding', () async {
      final at = DateTime.now().add(const Duration(minutes: 2));
      await LocalWorkoutNotificationService().scheduleRestAlarm(
        RestAlarm(
          at: at,
          title: 'wger – Timer expired',
          body: 'Next: Bench press',
          payload: payload,
          isTimer: true,
          canLengthenRest: true,
          maxRest: const Duration(minutes: 3),
          canLogSet: true,
        ),
        labels,
      );

      final call = calls.singleWhere((c) => c.method == 'zonedSchedule').arguments as Map;
      // The id of the controls, so no second notification
      expect(call['id'], 1);
      expect(scheduled()['channelId'], 'rest_alarm_v2');
      expect(scheduled()['playSound'], isTrue);
      expect(scheduled()['enableVibration'], isTrue);
      expect(scheduled()['requestPromotedOngoing'], isTrue);
      expect(scheduled()['ongoing'], isTrue);
      expect(scheduled()['autoCancel'], isFalse);
      expect(scheduled()['usesChronometer'], isTrue);
      expect(scheduled()['chronometerCountDown'], isTrue);
      expect(scheduled()['when'], at.millisecondsSinceEpoch);
      expect(actionIds(scheduled()), [
        WORKOUT_NOTIFICATION_ACTION_LENGTHEN_REST,
        WORKOUT_NOTIFICATION_ACTION_MAX_REST,
        WORKOUT_NOTIFICATION_ACTION_LOG_SET,
      ]);
    });

    test('Without the controls the alarm stays a plain one that can be dismissed', () async {
      await LocalWorkoutNotificationService().scheduleRestAlarm(alarm(canExtendRest: true), labels);

      expect(scheduled()['requestPromotedOngoing'], isFalse);
      expect(scheduled()['ongoing'], isFalse);
      expect(scheduled()['autoCancel'], isTrue);
      expect(scheduled()['usesChronometer'], isFalse);
      expect(actionIds(scheduled()), [
        WORKOUT_NOTIFICATION_ACTION_EXTEND_REST,
        WORKOUT_NOTIFICATION_ACTION_LOG_SET,
      ]);
    });

    test('A count-up rest keeps its skip button', () async {
      await LocalWorkoutNotificationService().showControls(
        WorkoutControls(
          title: 'wger – Timer',
          body: '',
          payload: payload,
          isTimer: true,
          chronometerAt: DateTime.now(),
          canSkipRest: true,
        ),
        labels,
      );

      expect(actionIds(shown()), [WORKOUT_NOTIFICATION_ACTION_SKIP_REST]);
    });
  });

  test('A silent alarm stands in for the controls, without sound', () async {
    final service = LocalWorkoutNotificationService();

    await service.scheduleRestAlarm(alarm(), labels);
    expect(scheduled()['channelId'], 'rest_alarm_v2');
    expect(scheduled()['playSound'], isTrue);

    calls.clear();
    await service.scheduleRestAlarm(
      RestAlarm(
        at: DateTime.now().add(const Duration(minutes: 2)),
        title: 'Bench press',
        body: 'Set 2 of 3 · 3x100kg',
        payload: payload,
        silent: true,
      ),
      labels,
    );
    expect(scheduled()['channelId'], 'workout_controls');
    expect(scheduled()['playSound'], isFalse);
    expect(scheduled()['enableVibration'], isFalse);
    expect(scheduled()['ongoing'], isTrue);
    expect(scheduled()['autoCancel'], isFalse);
  });

  group('Sounds with the ringer on vibrate or silent', () {
    test('The rest alarm plays on the alarm stream', () async {
      await LocalWorkoutNotificationService().scheduleRestAlarm(alarm(), labels);

      expect(scheduled()['audioAttributesUsage'], AudioAttributesUsage.alarm.value);
    });

    test('So does the warning before the end of the rest', () async {
      await LocalWorkoutNotificationService().scheduleRestWarning(
        RestWarning(
          at: DateTime.now().add(const Duration(minutes: 2)),
          title: 'Rest ends in 30 s',
          body: 'Next: Bench press',
        ),
        labels,
      );

      expect(scheduled()['channelId'], 'rest_alarm_v2');
      expect(scheduled()['audioAttributesUsage'], AudioAttributesUsage.alarm.value);
    });

    test('Removes the old channel on the notification stream', () async {
      await LocalWorkoutNotificationService().initialize(labels);

      expect(
        calls.where((c) => c.method == 'deleteNotificationChannel').map((c) => c.arguments),
        ['rest_alarm'],
      );
    });
  });

  test('The alarm says next to the app name that the rest is over', () async {
    await LocalWorkoutNotificationService().scheduleRestAlarm(
      RestAlarm(
        at: DateTime.now().add(const Duration(minutes: 2)),
        title: 'Bench press',
        body: 'Set 2 of 3 · 3x100kg',
        subtitle: 'Rest is over',
        payload: payload,
      ),
      labels,
    );

    expect(scheduled()['subText'], 'Rest is over');
  });

  group('Reminder of missing entries', () {
    final reminder = MissingEntriesReminder(
      at: DateTime.now().add(const Duration(minutes: 30)),
      title: 'Missed any entries?',
      body: 'Bench press is missing entries',
      channelName: 'Reminder',
    );

    test('Has a notification and channel of its own', () async {
      await LocalWorkoutNotificationService().scheduleReminder(reminder);

      final call = calls.singleWhere((c) => c.method == 'zonedSchedule').arguments as Map;
      expect(call['id'], 2);
      expect(call['title'], 'Missed any entries?');
      expect(scheduled()['channelId'], 'workout_reminder');
      expect(scheduled()['scheduleMode'], AndroidScheduleMode.exactAllowWhileIdle.name);
    });

    test('Inexact without the exact alarm permission', () async {
      exactAllowed = false;

      await LocalWorkoutNotificationService().scheduleReminder(reminder);

      expect(scheduled()['scheduleMode'], AndroidScheduleMode.inexactAllowWhileIdle.name);
    });

    test('Survives clearing the rest notification, goes on its own', () async {
      final service = LocalWorkoutNotificationService();
      List<Object?> cancelled() => [
        for (final c in calls.where((c) => c.method == 'cancel')) (c.arguments as Map)['id'],
      ];

      await service.cancelAll();
      expect(cancelled(), [1]);

      calls.clear();
      await service.cancelReminder();
      expect(cancelled(), [2]);
    });
  });

  group('Log set', () {
    List<Object?> inputsOfLogSet(Map<Object?, Object?> details) =>
        ((details['actions'] as List).cast<Map<Object?, Object?>>().singleWhere(
              (a) => a['id'] == WORKOUT_NOTIFICATION_ACTION_LOG_SET,
            )['inputs']
            as List?) ??
        const [];

    test('Offers the quick logs as choices, without free text', () async {
      await LocalWorkoutNotificationService().showControls(
        WorkoutControls(
          title: 'Pause',
          body: 'Next: Bench press',
          payload: payload,
          canLogSet: true,
          quickLogs: const ['9 × 60 kg', '8 × 62.5 kg'],
        ),
        labels,
      );

      final input = inputsOfLogSet(shown()).single! as Map;
      expect(input['choices'], ['9 × 60 kg', '8 × 62.5 kg']);
      expect(input['allowFreeFormInput'], isFalse);
    });

    test('Without quick logs the action takes no input', () async {
      await LocalWorkoutNotificationService().scheduleRestAlarm(alarm(), labels);

      expect(inputsOfLogSet(scheduled()), isEmpty);
    });

    test('The alarm offers the quick logs too', () async {
      await LocalWorkoutNotificationService().scheduleRestAlarm(
        alarm(quickLogs: ['9 × 60 kg']),
        labels,
      );

      expect((inputsOfLogSet(scheduled()).single! as Map)['choices'], ['9 × 60 kg']);
    });
  });

  group('Exercise image', () {
    const pathProvider = MethodChannel('plugins.flutter.io/path_provider');
    final image = Uri.parse('https://wger.test/media/bench.png');
    late Directory temp;

    setUp(() {
      temp = Directory.systemTemp.createTempSync('notification_image');
      addTearDown(() => temp.deleteSync(recursive: true));
      binding.defaultBinaryMessenger.setMockMethodCallHandler(
        pathProvider,
        (call) async => temp.path,
      );
      addTearDown(
        () => binding.defaultBinaryMessenger.setMockMethodCallHandler(pathProvider, null),
      );
    });

    test('Shows the image the app has cached', () async {
      final file = File(p.join(temp.path, cacheImageFolderName, keyToMd5(image.toString())))
        ..createSync(recursive: true);

      await LocalWorkoutNotificationService().scheduleRestAlarm(alarm(image: image), labels);

      expect(scheduled()['largeIcon'], file.path);
    });

    test('Does not wait for an image that is not cached', () async {
      await LocalWorkoutNotificationService().scheduleRestAlarm(alarm(image: image), labels);

      expect(scheduled()['largeIcon'], isNull);
    });
  });

  group('iOS', () {
    setUp(() {
      FlutterLocalNotificationsPlatform.instance = IOSFlutterLocalNotificationsPlugin();
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
      addTearDown(() => debugDefaultTargetPlatformOverride = null);
    });

    test('The alarm offers "+30 s" next to "Log set", or alone', () async {
      final service = LocalWorkoutNotificationService();
      await service.initialize(labels);
      final categories = {
        for (final c in (calls.single.arguments as Map)['notificationCategories'] as List)
          (c as Map)['identifier']: [
            for (final a in c['actions'] as List) (a as Map)['identifier'],
          ],
      };

      Future<Object?> categoryOf(RestAlarm alarm) async {
        calls.clear();
        await service.scheduleRestAlarm(alarm, labels);
        return scheduled()['categoryIdentifier'];
      }

      expect(categories[await categoryOf(alarm(canExtendRest: true))], [
        WORKOUT_NOTIFICATION_ACTION_LOG_SET,
        WORKOUT_NOTIFICATION_ACTION_EXTEND_REST,
      ]);
      expect(categories[await categoryOf(alarm(canLogSet: false, canExtendRest: true))], [
        WORKOUT_NOTIFICATION_ACTION_EXTEND_REST,
      ]);
      expect(await categoryOf(alarm(canLogSet: false)), isNull);
    });
  });
}
