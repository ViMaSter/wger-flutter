import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wger/core/watch_companion.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channels = [
    MethodChannel('watch_connectivity'),
    MethodChannel('watch_connectivity/methods'),
  ];
  final messenger = TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

  void mock(Future<Object?> Function(MethodCall)? handler) {
    for (final channel in channels) {
      messenger.setMockMethodCallHandler(channel, handler);
    }
  }

  tearDown(() => mock(null));

  test('serializes updates and preserves existing and nested context', () async {
    final firstSend = Completer<void>();
    final enteredSend = Completer<void>();
    final sent = <Map<dynamic, dynamic>>[];
    final contexts = <Map<dynamic, dynamic>>[];
    mock((call) async {
      switch (call.method) {
        case 'isSupported':
          return true;
        case 'applicationContext':
          return {
            'unrelated': 'keep',
            'exercise': {'weight': 25},
          };
        case 'sendMessage':
          sent.add(Map<dynamic, dynamic>.from(call.arguments as Map));
          if (sent.length == 1) {
            enteredSend.complete();
            await firstSend.future;
          }
          return null;
        case 'updateApplicationContext':
          contexts.add(Map<dynamic, dynamic>.from(call.arguments as Map));
          return null;
      }
      return null;
    });
    final companion = WatchCompanion();
    final exercise = companion.send({
      'exercise': {'exerciseName': 'Squat'},
    });
    final timer = companion.send({
      'timer': {'endTimeISO8601': '2026-10-03T12:00:00Z'},
    });
    await enteredSend.future;
    expect(sent, hasLength(1));
    firstSend.complete();
    await Future.wait([exercise, timer]);
    expect(sent, hasLength(2));
    expect(sent.last['exercise'], {'weight': 25, 'exerciseName': 'Squat'});
    expect(sent.last['unrelated'], 'keep');
    expect(sent.last['timer'], isA<Map>());
    expect(contexts, sent);
  });

  test('failed message still updates context and the next send works', () async {
    var messages = 0;
    var contexts = 0;
    mock((call) async {
      if (call.method == 'isSupported') {
        return true;
      }
      if (call.method == 'applicationContext') {
        return {};
      }
      if (call.method == 'sendMessage') {
        messages++;
        throw PlatformException(code: 'disconnected', message: 'private payload');
      }
      if (call.method == 'updateApplicationContext') {
        contexts++;
      }
      return null;
    });
    final companion = WatchCompanion();
    await companion.send({
      'exercise': {'exerciseName': 'Squat'},
    });
    await companion.send({'timer': null});
    expect(messages, 2);
    expect(contexts, 2);
  });

  test('unsupported and missing plugins are harmless', () async {
    final calls = <String>[];
    mock((call) async {
      calls.add(call.method);
      return false;
    });
    await WatchCompanion().send({'timer': null});
    expect(calls, ['isSupported']);
    mock(null);
    await sendWatchUpdate({'timer': null});
  });
}
