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

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:watch_connectivity/watch_connectivity.dart';
import 'package:wear_plus/wear_plus.dart';
import 'package:wger/main.dart';
import 'package:logging/logging.dart';
import 'package:vibration/vibration.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

final Logger _logger = Logger('watch_screen');

class WatchScreen extends StatefulWidget {
  const WatchScreen();

  @override
  State<WatchScreen> createState() => _WatchScreenState();
}

class _WatchScreenState extends State<WatchScreen> {
  String _remainingTimeText = '-';
  String _exerciseName = '-';
  String _repetitions = '-';
  String _weight = '-';
  String _currentSetCount = '-';
  String _totalSetCount = '-';

  // register a dictionary of string, function named `contextActions` to handle incoming messages
  final Map<String, Function(Map<String, dynamic>)> contextActions = {};

  void onWorkoutChange(Map<String, dynamic> context) {
    setState(() {
      _exerciseName = (context['exerciseName']?.toString() ?? '-');
      _weight = (context['weight']?.toString() ?? '-');
      _repetitions = (context['repetitions']?.toString() ?? '-');
      _currentSetCount = (context['currentSetCount']?.toString() ?? '-');
      _totalSetCount = (context['totalSetCount']?.toString() ?? '-');
    });
  }

  void onTimerChange(Map<String, dynamic> context) {
    final endTimeISO8601 = context['endTimeISO8601'] as String;
    final now = DateTime.now();
    final endTime = DateTime.parse(endTimeISO8601);
    final inThePast = endTime.isBefore(now);
    if (inThePast) {
      _cancelCountdown();
      return;
    }

    _startCountdown(endTime);
  }

  void reactToUpdate(context) {
    if (context == null) {
      _logger.warning('No valid context found');
      return;
    }

    _logger.info('[WATCH CONNECTIVITY] Applying current state...');
    try {
      _logger.info('Last context to apply; applying for each key in: $context');

      context.forEach((key, value) {
        final action = contextActions[key];
        if (action == null) {
          _logger.warning('No action found for context key: $key');
          return;
        }

        try {
          if (value is! Map) {
            _logger.warning('Context value for key "$key" is not a Map: $value');
            return;
          }

          final data = value.map<String, dynamic>((k, v) => MapEntry(k.toString(), v));
          _logger.info('Applying context data for key "$key": $data');
          action(data);
        } catch (e, st) {
          _logger.severe(
            'Failed to convert context value for key "$key" to Map<String,dynamic>: $e',
            e,
            st,
          );
        }
      });
    } catch (e, st) {
      _logger.severe('Failed to get initial watch context: $e', e, st);
    }
  }

  @override
  void initState() {
    WakelockPlus.enable();
    super.initState();
    contextActions['exercise'] = onWorkoutChange;
    contextActions['timer'] = onTimerChange;

    (() async {
      final watch = WatchConnectivity();
      watch.messageStream.listen((message) {
        _logger.info('Watch message received: $message');
        reactToUpdate(message);
      });
    })();
  }

  Timer? _countdownTask;
  void _startCountdown(DateTime endTime) {
    _countdownTask?.cancel();
    _countdownTask = Timer.periodic(const Duration(seconds: 1), (timer) async {
      final remainingSeconds = endTime.difference(DateTime.now()).inSeconds;
      final minutes = (remainingSeconds ~/ 60).toString();
      final seconds = (remainingSeconds % 60).toString().padLeft(2, '0');

      if (remainingSeconds == 15) {
        await Vibration.vibrate(pattern: [0, 75, 25, 75], intensities: [0, 255, 0, 192]);
      }
      if (remainingSeconds == 3 || remainingSeconds == 2 || remainingSeconds == 1) {
        await Vibration.vibrate(
          pattern: [0, 75, 25, 75, 825, 75, 25, 75, 825, 75, 25, 75, 825],
          intensities: [0, 255, 0, 192, 0, 255, 0, 192, 0, 255, 0, 192, 0],
        );
      }
      if (remainingSeconds > 0) {
        setState(() {
          _remainingTimeText = '$minutes:$seconds';
        });
        return;
      }

      setState(() {
        _remainingTimeText = '0:00';
      });

      _logger.warning("Large notice");
      await Vibration.vibrate(duration: 1000);
      _countdownTask?.cancel();
    });
  }

  void _cancelCountdown() {
    _countdownTask?.cancel();
    setState(() {
      _remainingTimeText = '0:00';
    });
  }

  @override
  void dispose() {
    _cancelCountdown();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Builder(
        builder: (BuildContext context) {
          return AmbientMode(
            builder: (context, mode, child) {
              final finalStr = [];

              final weightStr = _weight;
              final hasExercise = _exerciseName != '-';
              final hasTimer = _remainingTimeText != '-';
              final hasSetInfo = _currentSetCount != '-' && _totalSetCount != '-';

              if(hasSetInfo) {
                finalStr.add('Set: $_currentSetCount/$_totalSetCount');
              }
              
              if (hasExercise) {
                finalStr.add('$_exerciseName\n$_repetitions x $weightStr kg');
              }

              if (hasTimer) {
                finalStr.add('Rest Time:\n$_remainingTimeText');
              }

              // Both exercise and timer exist
              return Center(
                child: Text(
                  finalStr.isNotEmpty ? finalStr.join('\n\n') : 'No data (yet)',
                  textAlign: TextAlign.center,
                ),
              );
            },
          );
        },
      ),
    );
  }
}
