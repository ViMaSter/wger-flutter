import 'dart:async';

import 'package:clock/clock.dart';
import 'package:flutter/foundation.dart';
import 'package:logging/logging.dart';

class GymRestTimer extends ChangeNotifier {
  final DateTime Function() now;
  final Future<void> Function(Map<String, dynamic>) sendUpdate;
  final Future<void> Function() alert;
  final bool Function() alertsEnabled;
  final _logger = Logger('GymRestTimer');
  Timer? _expiry;
  DateTime? _endTime;
  DateTime? _elapsedStart;

  GymRestTimer({
    DateTime Function()? now,
    required this.sendUpdate,
    required this.alert,
    required this.alertsEnabled,
  }) : now = now ?? clock.now;

  DateTime? get endTime => _endTime;
  int get remainingSeconds => _endTime == null
      ? 0
      : (_endTime!.difference(now()).inMilliseconds / 1000).ceil().clamp(0, 86400);
  int get elapsedSeconds =>
      _elapsedStart == null ? 0 : now().difference(_elapsedStart!).inSeconds.clamp(0, 600);

  void startElapsed() {
    _elapsedStart ??= now();
  }

  void ensureStarted(int seconds) {
    if (_endTime == null) {
      resetTo(seconds);
    }
  }

  void adjust(int seconds) {
    if (_endTime == null) {
      return;
    }
    _setDeadline(_endTime!.add(Duration(seconds: seconds)));
  }

  void resetTo(int seconds) {
    _setDeadline(now().add(Duration(seconds: seconds)));
  }

  void _setDeadline(DateTime deadline) {
    _expiry?.cancel();
    _endTime = deadline;
    _elapsedStart = null;
    final remaining = deadline.difference(now());
    if (remaining <= Duration.zero) {
      _expire();
      return;
    }
    _expiry = Timer(remaining, _expire);
    _publish();
    notifyListeners();
  }

  void _expire() {
    if (_endTime == null) {
      return;
    }
    _expiry?.cancel();
    _endTime = null;
    _publish();
    notifyListeners();
    if (alertsEnabled()) {
      unawaited(_attempt(alert));
    }
  }

  void clear() {
    _expiry?.cancel();
    final wasActive = _endTime != null;
    _endTime = null;
    _elapsedStart = null;
    if (wasActive) {
      _publish();
    }
    notifyListeners();
  }

  void _publish() {
    final update = <String, dynamic>{
      'timer': {'endTimeISO8601': _endTime?.toIso8601String()},
    };
    unawaited(_attempt(() => sendUpdate(update)));
  }

  Future<void> _attempt(Future<void> Function() operation) async {
    try {
      await operation();
    } catch (error, stackTrace) {
      _logger.fine('Rest timer platform operation unavailable', error, stackTrace);
    }
  }

  @override
  void dispose() {
    _expiry?.cancel();
    super.dispose();
  }
}
