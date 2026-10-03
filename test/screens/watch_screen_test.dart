import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:vibration_platform_interface/vibration_platform_interface.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:wakelock_plus_platform_interface/messages.g.dart';
import 'package:wakelock_plus_platform_interface/wakelock_plus_platform_interface.dart';
import 'package:wger/screens/watch_screen.dart';

class _ChannelVibration extends VibrationPlatform {
  static const channel = MethodChannel('vibration');

  @override
  Future<bool> hasVibrator() async => await channel.invokeMethod<bool>('hasVibrator') ?? false;

  @override
  Future<bool> hasCustomVibrationsSupport() async =>
      await channel.invokeMethod<bool>('hasCustomVibrationsSupport') ?? false;

  @override
  Future<void> vibrate({
    int duration = 500,
    List<int> pattern = const [],
    int repeat = -1,
    List<int> intensities = const [],
    int amplitude = -1,
    double sharpness = 0.5,
  }) => channel.invokeMethod<void>('vibrate', {'duration': duration});

  @override
  Future<void> cancel() => channel.invokeMethod<void>('cancel');
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final messenger = TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  const methods = [
    MethodChannel('watch_connectivity'),
    MethodChannel('watch_connectivity/methods'),
  ];
  const events = ['watch_connectivity/messages', 'watch_connectivity/context'];
  const wakeChannel = BasicMessageChannel<Object?>(
    'dev.flutter.pigeon.wakelock_plus_platform_interface.WakelockPlusApi.toggle',
    WakelockPlusApi.pigeonChannelCodec,
  );
  final initialVibration = VibrationPlatform.instance;
  final initialWake = wakelockPlusPlatformInstance;
  late Map<String, dynamic> initialContext;
  late List<Map<String, dynamic>> receivedContexts;
  late List<String> canceledStreams;
  late List<String> listenedStreams;
  late List<bool> wakelocks;
  late List<int> vibrationDurations;
  late bool hasVibrator;
  late Future<bool>? customVibrationSupport;
  late DateTime now;

  void mockWatch(Future<Object?> Function(MethodCall)? handler) {
    for (final channel in methods) {
      messenger.setMockMethodCallHandler(channel, handler);
    }
  }

  Future<void> emit(WidgetTester tester, String channel, Object? data) async {
    await messenger.handlePlatformMessage(
      channel,
      const StandardMethodCodec().encodeSuccessEnvelope(data),
      (_) {},
    );
    await messenger.handlePlatformMessage(
      'watch_connectivity',
      const StandardMethodCodec().encodeMethodCall(
        MethodCall(
          channel.endsWith('/messages') ? 'didReceiveMessage' : 'didReceiveApplicationContext',
          data,
        ),
      ),
      (_) {},
    );
    await tester.pump();
  }

  Future<void> mount(WidgetTester tester) async {
    await tester.pumpWidget(MaterialApp(home: WatchScreen(now: () => now)));
    await tester.pump();
  }

  Future<void> advance(WidgetTester tester, int seconds) async {
    now = now.add(Duration(seconds: seconds));
    await tester.pump(Duration(seconds: seconds));
    await tester.pump();
  }

  setUp(() {
    initialContext = {};
    receivedContexts = [];
    canceledStreams = [];
    listenedStreams = [];
    wakelocks = [];
    vibrationDurations = [];
    hasVibrator = true;
    customVibrationSupport = null;
    now = DateTime.utc(2026, 10, 3, 12);
    VibrationPlatform.instance = _ChannelVibration();
    wakelockPlusPlatformInstance = WakelockPlusPlatformInterface.instance;
    messenger.setMockDecodedMessageHandler<Object?>(wakeChannel, (message) async {
      final arguments = message! as List<Object?>;
      wakelocks.add((arguments.first! as ToggleMessage).enable!);
      return <Object?>[null];
    });
    mockWatch((call) async {
      if (call.method == 'isSupported') {
        return true;
      }
      if (call.method == 'applicationContext') {
        return initialContext;
      }
      if (call.method == 'receivedApplicationContexts') {
        return receivedContexts;
      }
      return null;
    });
    for (final channel in events) {
      messenger.setMockMethodCallHandler(MethodChannel(channel), (call) async {
        if (call.method == 'cancel') {
          canceledStreams.add(channel);
        }
        if (call.method == 'listen') {
          listenedStreams.add(channel);
        }
        return null;
      });
    }
    messenger.setMockMethodCallHandler(_ChannelVibration.channel, (call) async {
      if (call.method == 'hasVibrator') {
        return hasVibrator;
      }
      if (call.method == 'hasCustomVibrationsSupport') {
        return customVibrationSupport ?? true;
      }
      if (call.method == 'vibrate') {
        vibrationDurations.add((call.arguments as Map)['duration'] as int);
      }
      return null;
    });
  });

  tearDown(() {
    VibrationPlatform.instance = initialVibration;
    wakelockPlusPlatformInstance = initialWake;
    mockWatch(null);
    messenger.setMockMethodCallHandler(_ChannelVibration.channel, null);
    messenger.setMockDecodedMessageHandler<Object?>(wakeChannel, null);
    for (final channel in events) {
      messenger.setMockMethodCallHandler(MethodChannel(channel), null);
    }
  });

  testWidgets('loads initial and received context, then merges both live streams', (tester) async {
    initialContext = {
      'exercise': {
        'exerciseName': 'Squat',
        'repetitions': 8,
        'weight': 40,
        'currentSetCount': 1,
        'totalSetCount': 3,
      },
    };
    receivedContexts = [
      {
        'timer': {'endTimeISO8601': now.add(const Duration(seconds: 65)).toIso8601String()},
      },
    ];
    await mount(tester);
    expect(find.text('Squat'), findsOneWidget);
    expect(find.text('8 x 40 kg'), findsOneWidget);
    expect(find.text('Set: 1/3'), findsOneWidget);
    expect(find.text('1:05'), findsOneWidget);
    await emit(tester, events.first, {
      'exercise': {'currentSetCount': 2},
    });
    await emit(tester, events.last, {
      'exercise': {'weight': 45},
    });
    expect(find.text('Set: 2/3'), findsOneWidget);
    expect(find.text('8 x 45 kg'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    await tester.pump();
    expect(wakelocks, [true, false]);
    expect(canceledStreams, unorderedEquals(listenedStreams));
    await emit(tester, events.first, {
      'exercise': {'exerciseName': 'After disposal'},
    });
    expect(tester.takeException(), isNull);
  });

  testWidgets('absent and malformed messages are harmless on a small face', (tester) async {
    tester.view.physicalSize = const Size(180, 180);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await mount(tester);
    expect(find.text('No data (yet)'), findsOneWidget);
    for (final payload in [
      null,
      'invalid',
      <String, dynamic>{},
      {
        'exercise': 5,
        'timer': {'endTimeISO8601': 'not-a-date'},
      },
      {
        'exercise': {'weight': []},
        'timer': {'endTimeISO8601': 123},
      },
      {'timer': null},
    ]) {
      await emit(tester, events.first, payload);
    }
    await emit(tester, events.last, {
      'exercise': {'exerciseName': 'A very long exercise name that wraps across the watch face'},
    });
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    await tester.pump();
  });

  testWidgets('countdown cues and distinct expiry occur once across duplicate updates', (
    tester,
  ) async {
    final timer = {
      'timer': {'endTimeISO8601': now.add(const Duration(seconds: 16)).toIso8601String()},
    };
    initialContext = timer;
    await mount(tester);
    expect(find.text('0:16'), findsOneWidget);
    await advance(tester, 1);
    expect(vibrationDurations, [75]);
    await advance(tester, 12);
    await advance(tester, 1);
    await advance(tester, 1);
    await advance(tester, 1);
    expect(find.text('0:00'), findsOneWidget);
    expect(vibrationDurations.where((duration) => duration == 1000), hasLength(1));
    await emit(tester, events.first, timer);
    await emit(tester, events.last, timer);
    await advance(tester, 5);
    expect(vibrationDurations.where((duration) => duration == 1000), hasLength(1));
    await emit(tester, events.first, {'timer': null});
    final later = {
      'timer': {'endTimeISO8601': now.add(const Duration(seconds: 1)).toIso8601String()},
    };
    await emit(tester, events.last, later);
    await advance(tester, 1);
    expect(vibrationDurations.where((duration) => duration == 1000), hasLength(2));
    await tester.pumpWidget(const SizedBox());
    await tester.pump();
    expect(tester.takeException(), isNull);
  });

  testWidgets('phone clear at the deadline before local tick expires exactly once', (tester) async {
    final deadline = now.add(const Duration(seconds: 1));
    final timer = {
      'timer': {'endTimeISO8601': deadline.toIso8601String()},
    };
    initialContext = timer;
    await mount(tester);
    now = deadline;
    await emit(tester, events.first, {
      'timer': {'endTimeISO8601': null},
    });
    expect(find.text('Rest Time'), findsNothing);
    expect(vibrationDurations, [1000]);
    await emit(tester, events.last, {'timer': null});
    await emit(tester, events.first, {
      'timer': {'endTimeISO8601': null},
    });
    await emit(tester, events.first, timer);
    await emit(tester, events.last, timer);
    await emit(tester, events.last, {'timer': null});
    await advance(tester, 2);
    expect(vibrationDurations, [1000]);
    await tester.pumpWidget(const SizedBox());
    await tester.pump();
  });

  testWidgets('phone cancellation before deadline has no expiry haptic', (tester) async {
    initialContext = {
      'timer': {'endTimeISO8601': now.add(const Duration(seconds: 2)).toIso8601String()},
    };
    await mount(tester);
    now = now.add(const Duration(seconds: 1));
    await emit(tester, events.first, {
      'timer': {'endTimeISO8601': null},
    });
    await emit(tester, events.last, {'timer': null});
    await advance(tester, 3);
    expect(find.text('Rest Time'), findsNothing);
    expect(vibrationDurations, isEmpty);
    await tester.pumpWidget(const SizedBox());
    await tester.pump();
  });

  testWidgets('pending local expiry survives a phone clear during capability check', (
    tester,
  ) async {
    final capability = Completer<bool>();
    customVibrationSupport = capability.future;
    initialContext = {
      'timer': {'endTimeISO8601': now.add(const Duration(seconds: 1)).toIso8601String()},
    };
    await mount(tester);
    await advance(tester, 1);
    expect(vibrationDurations, isEmpty);
    await emit(tester, events.first, {'timer': null});
    await emit(tester, events.last, {'timer': null});
    capability.complete(true);
    await tester.pump();
    expect(vibrationDurations, [1000]);
    await tester.pumpWidget(const SizedBox());
    await tester.pump();
  });

  for (final dispose in [false, true]) {
    testWidgets(
      'pending phone expiry is suppressed after ${dispose ? 'disposal' : 'a new timer'}',
      (
        tester,
      ) async {
        final capability = Completer<bool>();
        customVibrationSupport = capability.future;
        final deadline = now.add(const Duration(seconds: 1));
        initialContext = {
          'timer': {'endTimeISO8601': deadline.toIso8601String()},
        };
        await mount(tester);
        now = deadline;
        await emit(tester, events.first, {'timer': null});
        expect(vibrationDurations, isEmpty);
        if (dispose) {
          await tester.pumpWidget(const SizedBox());
        } else {
          await emit(tester, events.last, {
            'timer': {'endTimeISO8601': now.add(const Duration(seconds: 10)).toIso8601String()},
          });
          await emit(tester, events.first, {'timer': null});
        }
        capability.complete(true);
        await tester.pump();
        expect(vibrationDurations, isEmpty);
        await tester.pumpWidget(const SizedBox());
        await tester.pump();
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets('unsupported vibration and disposal cancel active countdown safely', (tester) async {
    hasVibrator = false;
    initialContext = {
      'timer': {'endTimeISO8601': now.add(const Duration(seconds: 2)).toIso8601String()},
    };
    await mount(tester);
    await advance(tester, 1);
    expect(vibrationDurations, isEmpty);
    await advance(tester, 1);
    expect(find.text('0:00'), findsOneWidget);
    expect(vibrationDurations, isEmpty);
    await emit(tester, events.first, {
      'timer': {'endTimeISO8601': now.add(const Duration(seconds: 5)).toIso8601String()},
    });
    await tester.pumpWidget(const SizedBox());
    await advance(tester, 10);
    expect(vibrationDurations, isEmpty);
    expect(wakelocks, [true, false]);
    expect(tester.takeException(), isNull);
  });

  testWidgets('live updates win over delayed initial context', (tester) async {
    final context = Completer<Map<String, dynamic>>();
    mockWatch((call) async {
      if (call.method == 'isSupported') {
        return true;
      }
      if (call.method == 'applicationContext') {
        return context.future;
      }
      return [];
    });
    await mount(tester);
    await emit(tester, events.first, {
      'exercise': {'exerciseName': 'New exercise'},
    });
    context.complete({
      'exercise': {'exerciseName': 'Old exercise', 'weight': 10},
    });
    await tester.pumpAndSettle();
    expect(find.text('New exercise'), findsOneWidget);
    expect(find.text('Old exercise'), findsNothing);
    expect(find.text('- x 10 kg'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    await tester.pump();
  });

  testWidgets('late initialization after disposal does not throw', (tester) async {
    final context = Completer<Map<String, dynamic>>();
    mockWatch((call) async {
      if (call.method == 'isSupported') {
        return true;
      }
      if (call.method == 'applicationContext') {
        return context.future;
      }
      throw MissingPluginException();
    });
    messenger.setMockDecodedMessageHandler<Object?>(wakeChannel, null);
    messenger.setMockMethodCallHandler(_ChannelVibration.channel, null);
    await mount(tester);
    await tester.pumpWidget(const SizedBox());
    context.complete({
      'exercise': {'exerciseName': 'Too late'},
    });
    await tester.pump();
    expect(tester.takeException(), isNull);
  });

  testWidgets('missing connectivity and lifecycle plugins are harmless', (tester) async {
    mockWatch(null);
    for (final channel in events) {
      messenger.setMockMethodCallHandler(MethodChannel(channel), null);
    }
    messenger.setMockDecodedMessageHandler<Object?>(wakeChannel, null);
    messenger.setMockMethodCallHandler(_ChannelVibration.channel, null);
    await mount(tester);
    expect(find.text('No data (yet)'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    await tester.pump();
    expect(tester.takeException(), isNull);
  });
}
