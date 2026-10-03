import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';
import 'package:watch_connectivity/watch_connectivity.dart';
import 'package:wger/screens/watch_screen.dart';

Future<bool> detectWearDevice() async {
  if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) {
    return false;
  }
  try {
    final isWear = await const MethodChannel('wear').invokeMethod<bool>('isWear');
    if (isWear != null) {
      return isWear;
    }
  } catch (_) {}
  try {
    final info = await DeviceInfoPlugin().androidInfo;
    return info.systemFeatures.contains('android.hardware.type.watch');
  } catch (_) {
    return false;
  }
}

class ApplicationRoot extends StatelessWidget {
  const ApplicationRoot({super.key, required this.isWear, required this.phoneApp});

  final bool isWear;
  final Widget phoneApp;

  @override
  Widget build(BuildContext context) {
    if (!isWear) {
      return phoneApp;
    }
    return MaterialApp(
      title: 'wger',
      theme: ThemeData.dark(),
      home: const WatchScreen(),
    );
  }
}

final _watchCompanion = WatchCompanion();

Future<void> sendWatchUpdate(Map<String, dynamic> update) => _watchCompanion.send(update);

class WatchCompanion {
  WatchCompanion() : _watch = WatchConnectivity();

  final WatchConnectivity _watch;
  Future<void> _pending = Future<void>.value();
  Map<String, dynamic> _context = {};

  Future<void> send(Map<String, dynamic> update) {
    final snapshot = _merge({}, update);
    _pending = _pending.then((_) => _send(snapshot));
    return _pending;
  }

  Future<void> _send(Map<String, dynamic> update) async {
    _context = _merge(_context, update);
    try {
      if (!await _watch.isSupported) {
        return;
      }
    } catch (_) {
      return;
    }

    try {
      _context = _merge(await _watch.applicationContext, _context);
    } catch (_) {}

    try {
      await _watch.sendMessage(_context);
    } catch (_) {}
    try {
      await _watch.updateApplicationContext(_context);
    } catch (_) {}
  }

  static Map<String, dynamic> _merge(Map<String, dynamic> previous, Map<String, dynamic> update) {
    final result = Map<String, dynamic>.from(previous);
    for (final entry in update.entries) {
      final value = entry.value;
      final oldValue = result[entry.key];
      result[entry.key] = value is Map && value.keys.every((key) => key is String)
          ? _merge(
              oldValue is Map && oldValue.keys.every((key) => key is String)
                  ? Map<String, dynamic>.from(oldValue)
                  : {},
              Map<String, dynamic>.from(value),
            )
          : value;
    }
    return result;
  }
}
