/*
 * This file is part of wger Workout Manager <https://github.com/wger-project>.
 * Copyright (C) 2020, 2021 wger Team
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
import 'dart:async';

import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';
import 'package:vibration/vibration.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:watch_connectivity/watch_connectivity.dart';

class WatchScreen extends StatefulWidget {
  const WatchScreen({super.key, this.now});

  final DateTime Function()? now;

  @override
  State<WatchScreen> createState() => _WatchScreenState();
}

class _WatchScreenState extends State<WatchScreen> {
  final _watch = WatchConnectivity();
  final _subscriptions = <StreamSubscription<Map<String, dynamic>>>[];
  final _bufferedUpdates = <Map<String, dynamic>>[];
  final _exercise = <String, String>{};
  bool _loadingContext = true;
  String? _remainingTimeText;
  DateTime? _endTime;
  DateTime? _lastExpiredEndTime;
  int _timerGeneration = 0;
  int? _lastRemainingSeconds;
  Timer? _countdownTask;
  Future<void> _wakeOperation = Future<void>.value();

  DateTime get _now => widget.now?.call() ?? DateTime.now();

  @override
  void initState() {
    super.initState();
    _wakeOperation = _setWakelock(true);
    unawaited(_connect());
  }

  Future<void> _connect() async {
    try {
      if (!await _watch.isSupported || !mounted) {
        return;
      }
    } catch (_) {
      return;
    }
    for (final stream in [_watch.messageStream, _watch.contextStream]) {
      _subscriptions.add(stream.listen(_receive, onError: (Object _) {}));
    }
    await _loadContext();
  }

  Future<void> _setWakelock(bool enabled) async {
    try {
      await WakelockPlus.toggle(enable: enabled);
    } catch (_) {}
  }

  Future<void> _loadContext() async {
    try {
      final context = await _watch.applicationContext;
      _apply(context);
    } catch (_) {}
    try {
      final contexts = await _watch.receivedApplicationContexts;
      contexts.forEach(_apply);
    } catch (_) {}
    if (!mounted) {
      return;
    }
    _loadingContext = false;
    _bufferedUpdates.forEach(_apply);
    _bufferedUpdates.clear();
  }

  void _receive(Map<String, dynamic> update) {
    if (!mounted) {
      return;
    }
    if (_loadingContext) {
      _bufferedUpdates.add(update);
    }
    _apply(update);
  }

  void _apply(Map<String, dynamic> update) {
    if (!mounted) {
      return;
    }
    final exercise = update['exercise'];
    if (exercise is Map) {
      setState(() {
        for (final key in [
          'exerciseName',
          'repetitions',
          'weight',
          'currentSetCount',
          'totalSetCount',
        ]) {
          if (!exercise.containsKey(key)) {
            continue;
          }
          final value = exercise[key];
          if (value == null) {
            _exercise.remove(key);
          } else if (value is String || value is num) {
            _exercise[key] = value.toString();
          }
        }
      });
    }
    if (!update.containsKey('timer')) {
      return;
    }
    final timer = update['timer'];
    if (timer == null || (timer is Map && timer['endTimeISO8601'] == null)) {
      if (_endTime != null && !_endTime!.isAfter(_now)) {
        _tick();
      }
      _countdownTask?.cancel();
      _endTime = null;
      _lastRemainingSeconds = null;
      setState(() => _remainingTimeText = null);
      return;
    }
    if (timer is! Map || timer['endTimeISO8601'] is! String) {
      return;
    }
    final endTime = DateTime.tryParse(timer['endTimeISO8601'] as String);
    if (endTime == null || endTime == _endTime) {
      return;
    }
    _countdownTask?.cancel();
    _timerGeneration++;
    _endTime = endTime;
    _lastRemainingSeconds = null;
    _tick(notify: false);
    if (endTime.isAfter(_now)) {
      _countdownTask = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
    }
  }

  void _tick({bool notify = true}) {
    if (!mounted || _endTime == null) {
      return;
    }
    final endTime = _endTime!;
    final milliseconds = endTime.difference(_now).inMilliseconds;
    final remaining = milliseconds > 0 ? (milliseconds / 1000).ceil() : 0;
    setState(() {
      _remainingTimeText = '${remaining ~/ 60}:${(remaining % 60).toString().padLeft(2, '0')}';
    });
    if (remaining == 0) {
      _countdownTask?.cancel();
      if (_lastExpiredEndTime != endTime) {
        _lastExpiredEndTime = endTime;
        if (notify) {
          unawaited(_vibrate(endTime, expiry: true));
        }
      }
    } else if (notify &&
        remaining != _lastRemainingSeconds &&
        (remaining == 15 || remaining <= 3)) {
      unawaited(_vibrate(endTime));
    }
    _lastRemainingSeconds = remaining;
  }

  Future<void> _vibrate(DateTime endTime, {bool expiry = false}) async {
    final generation = _timerGeneration;
    try {
      if (!await Vibration.hasVibrator()) {
        return;
      }
      final custom = await Vibration.hasCustomVibrationsSupport();
      if (!mounted || generation != _timerGeneration) {
        return;
      }
      if (_endTime != endTime && !(expiry && _endTime == null && _lastExpiredEndTime == endTime)) {
        return;
      }
      if (!expiry && _lastRemainingSeconds == 0) {
        return;
      }
      if (custom) {
        await Vibration.vibrate(duration: expiry ? 1000 : 75);
      } else if (expiry) {
        await Vibration.vibrate();
      } else {
        await HapticFeedback.selectionClick();
      }
    } catch (_) {}
  }

  Future<void> _cancelVibration() async {
    try {
      await Vibration.cancel();
    } catch (_) {}
  }

  @override
  void dispose() {
    _countdownTask?.cancel();
    for (final subscription in _subscriptions) {
      unawaited(subscription.cancel());
    }
    unawaited(_wakeOperation.then((_) => _setWakelock(false)));
    unawaited(_cancelVibration());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hasExercise = _exercise.isNotEmpty;
    final hasTimer = _remainingTimeText != null;
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final contentWidth = constraints.maxWidth * 0.7;
            return Center(
              child: SizedBox(
                width: contentWidth,
                height: constraints.maxHeight * 0.7,
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: SizedBox(
                    width: contentWidth,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (!hasExercise && !hasTimer)
                          const Text(
                            'No data (yet)',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.white),
                          ),
                        if (hasExercise) ...[
                          const Icon(Icons.fitness_center, color: Colors.white70, size: 16),
                          const SizedBox(height: 4),
                          Text(
                            _exercise['exerciseName'] ?? '-',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${_exercise['repetitions'] ?? '-'} x ${_exercise['weight'] ?? '-'} kg',
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: Colors.white, fontSize: 14),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Set: ${_exercise['currentSetCount'] ?? '-'}/${_exercise['totalSetCount'] ?? '-'}',
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: Colors.white70, fontSize: 12),
                          ),
                        ],
                        if (hasTimer) ...[
                          const SizedBox(height: 8),
                          const Text(
                            'Rest Time',
                            style: TextStyle(color: Colors.white70, fontSize: 12),
                          ),
                          Text(
                            _remainingTimeText!,
                            style: const TextStyle(color: Colors.white, fontSize: 28),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
