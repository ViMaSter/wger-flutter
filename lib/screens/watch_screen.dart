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

  // register a dictionary of string, function named `contextActions` to handle incoming messages
  final Map<String, Function(Map<String, dynamic>)> contextActions = {};

  void onWorkoutChange(Map<String, dynamic> context) {
    setState(() {
      _exerciseName = context['exerciseName'] as String;
      _weight = context['weight'] as String;
      _repetitions = context['repetitions'] as String;
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

  @override
  void initState() {
    super.initState();
    contextActions['exercise'] = onWorkoutChange;
    contextActions['timer'] = onTimerChange;

    final watch = WatchConnectivity();
    _logger.info('[WATCH CONNECTIVITY] Listening for context updates...');
    watch.contextStream.listen((context) {
      _logger.fine('Parsed watch context: $context');
      if (!context.containsKey('state')) {
        _logger.fine('No state key in context: $context');
        return;
      }

      final action = contextActions[context['state']];
      if (action == null) {
        _logger.warning('No action found for context key: ${context["state"]}');
        return;
      }

      try {
        final raw = context['data'];
        if (raw is Map) {
          final data = raw.map<String, dynamic>((k, v) => MapEntry(k.toString(), v));
          action(data);
        } else {
          _logger.warning('Context "data" is not a Map: $raw');
        }
      } catch (e, st) {
        _logger.severe('Failed to convert context "data" to Map<String,dynamic>: $e', e, st);
      }
    });
  }

  Timer? _countdownTask;
  void _startCountdown(DateTime endTime) {
    _countdownTask?.cancel();
    _countdownTask = Timer.periodic(const Duration(seconds: 1), (timer) {
      final remainingSeconds = endTime.difference(DateTime.now()).inSeconds;
      final minutes = (remainingSeconds ~/ 60).toString();
      final seconds = (remainingSeconds % 60).toString().padLeft(2, '0');
      if (remainingSeconds > 0) {
        setState(() {
          _remainingTimeText = '$minutes:$seconds';
        });
        return;
      }

      setState(() {
        _remainingTimeText = '0:00';
      });
      HapticFeedback.vibrate();
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
      child: WatchShape(
        builder: (BuildContext context, WearShape shape, Widget? child) {
          return AmbientMode(
            builder: (context, mode, child) {
              final weightStr = _weight;
              final hasExercise = _exerciseName != '-';
              final hasTimer = _remainingTimeText != '-';

              // Neither exercise nor timer
              if (!hasExercise && !hasTimer) {
                return const Center(
                  child: Text(
                  'No exercise selected\n\nNo timer set',
                  textAlign: TextAlign.center,
                  ),
                );
              }

              // No exercise but timer exists
              if (!hasExercise && hasTimer) {
                return Center(
                  child: Text(
                  'No exercise selected\n\nTimer: $_remainingTimeText',
                  textAlign: TextAlign.center,
                  ),
                );
              }

              // Exercise exists but no timer
              if (hasExercise && !hasTimer) {
                return Center(
                  child: Text(
                  '$_exerciseName\n$_repetitions x $weightStr kg\n\nNo timer set',
                  textAlign: TextAlign.center,
                  ),
                );
              }

              // Both exercise and timer exist
              return Center(
                child: Text(
                  '$_exerciseName\n$_repetitions x $weightStr kg\n\nTimer: $_remainingTimeText',
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