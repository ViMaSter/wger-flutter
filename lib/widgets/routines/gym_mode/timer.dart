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
import 'package:intl/intl.dart';
import 'package:watch_connectivity/watch_connectivity.dart';
import 'package:wger/l10n/generated/app_localizations.dart';
import 'package:wger/models/exercises/exercise.dart';
import 'package:wger/theme/theme.dart';
import 'package:wger/widgets/routines/gym_mode/navigation.dart';

/// Singleton service to keep the gym mode rest timer running while the
/// countdown widget is not visible. It stores only the current end time.
class GymModeRestTimerService {
  GymModeRestTimerService._();
  static final GymModeRestTimerService instance = GymModeRestTimerService._();

  DateTime? _endTime;

  bool get isActive => _endTime != null;
  bool get isExpired => _endTime != null && DateTime.now().isAfter(_endTime!);
  DateTime get endTime => _endTime!;

  void start(DateTime endTime) {
    _endTime = endTime;
  }

  void reset() {
    _endTime = null;
  }
}

class TimerWidget extends StatefulWidget {
  final PageController _controller;
  final double _ratioCompleted;
  final Map<Exercise, int> _exercisePages;
  final _totalPages;

  const TimerWidget(this._controller, this._ratioCompleted, this._exercisePages, this._totalPages);

  @override
  _TimerWidgetState createState() => _TimerWidgetState();
}

class _TimerWidgetState extends State<TimerWidget> {
  late DateTime _startTime;
  final _maxSeconds = 600;
  late Timer _uiTimer;

  @override
  void initState() {
    super.initState();
    _startTime = DateTime.now();

    _uiTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      // ignore: no-empty-block, avoid-empty-setstate
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _uiTimer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final elapsed = DateTime.now().difference(_startTime).inSeconds;
    final displaySeconds = elapsed > _maxSeconds ? _maxSeconds : elapsed;
    final displayTime = DateTime(2000, 1, 1, 0, 0, 0).add(Duration(seconds: displaySeconds));

    return Column(
      children: [
        NavigationHeader(
          AppLocalizations.of(context).pause,
          widget._controller,
          totalPages: widget._totalPages,
          exercisePages: widget._exercisePages,
        ),
        Expanded(
          child: Center(
            child: Text(
              DateFormat('m:ss').format(displayTime),
              style: Theme.of(context).textTheme.displayLarge!.copyWith(color: wgerPrimaryColor),
            ),
          ),
        ),
        NavigationFooter(widget._controller, widget._ratioCompleted),
      ],
    );
  }
}

class TimerCountdownWidget extends StatefulWidget {
  final PageController _controller;
  final double _ratioCompleted;
  final int _seconds;
  final int? _maxSeconds;
  final Map<Exercise, int> _exercisePages;
  final int _totalPages;

  const TimerCountdownWidget(
    this._controller,
    this._seconds,
    this._maxSeconds,
    this._ratioCompleted,
    this._exercisePages,
    this._totalPages,
  );

  @override
  _TimerCountdownWidgetState createState() => _TimerCountdownWidgetState();
}

class _TimerCountdownWidgetState extends State<TimerCountdownWidget> {
  late DateTime _endTime;
  late Timer _uiTimer;

  @override
  void initState() {
    super.initState();
    updateTimer();

    _uiTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      // ignore: no-empty-block, avoid-empty-setstate
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _uiTimer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final remaining = _endTime.difference(DateTime.now());
    final remainingSeconds = remaining.inSeconds <= 0 ? 0 : remaining.inSeconds;
    final displayTime = DateTime(2000, 1, 1, 0, 0, 0).add(Duration(seconds: remainingSeconds));

    // If expired, allow a subsequent re-entry to restart by clearing service.
    if (remainingSeconds == 0) {
      final service = GymModeRestTimerService.instance;
      if (service.isExpired) {
        service.reset();
      }
    }

    return Column(
      children: [
        NavigationHeader(
          AppLocalizations.of(context).pause,
          widget._controller,
          totalPages: widget._totalPages,
          exercisePages: widget._exercisePages,
        ),
        Expanded(
          child: Center(
            child: Text(
              DateFormat('m:ss').format(displayTime),
              style: Theme.of(context).textTheme.displayLarge!.copyWith(color: wgerPrimaryColor),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  OutlinedButton.icon(
                    onPressed: () => _changeSeconds(-15),
                    icon: const Icon(Icons.remove_circle_outline),
                    label: Text('-15s', style: Theme.of(context).textTheme.labelLarge),
                  ),
                  const SizedBox(width: 24),
                  OutlinedButton.icon(
                    onPressed: () => _changeSeconds(15),
                    icon: const Icon(Icons.add_circle_outline),
                    label: Text('+15s', style: Theme.of(context).textTheme.labelLarge),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (widget._seconds > 0)
                    OutlinedButton(
                      onPressed: () => _resetTo(widget._seconds),
                      child: Text(
                        'Reset to ${widget._seconds}s',
                        style: Theme.of(context).textTheme.labelLarge,
                      ),
                    ),
                  if (widget._seconds > 0 && widget._maxSeconds != null)
                    const SizedBox(width: 16),
                  if (widget._maxSeconds != null)
                    OutlinedButton(
                      onPressed: () => _resetTo(widget._maxSeconds!),
                      child: Text(
                        'Reset to ${widget._maxSeconds!.toString()}s',
                        style: Theme.of(context).textTheme.labelLarge,
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
        NavigationFooter(widget._controller, widget._ratioCompleted),
      ],
    );
  }

  void updateTimer() {
    final service = GymModeRestTimerService.instance;
    // Reuse running timer if still active and not expired; otherwise start new.
    if (service.isActive && !service.isExpired) {
      _endTime = service.endTime;
      return;
    }

    _endTime = DateTime.now().add(Duration(seconds: widget._seconds));
    service.start(_endTime);

    final watch = WatchConnectivity();
    watch.updateApplicationContext({
      'state': 'timer',
      'data': {
        'endTimeISO8601': _endTime.toIso8601String(),
      },
    });
    print('[WATCH CONNECTIVITY] Sent timer end time: ${_endTime.toIso8601String()}');
  }

  void _changeSeconds(int delta) {
    final service = GymModeRestTimerService.instance;
    // If already expired, ignore increases until restarted via navigation.
    if (!service.isActive || service.isExpired) {
      return; // Timer needs restart via normal flow.
    }

    final now = DateTime.now();
    var newEnd = _endTime.add(Duration(seconds: delta));

    // Subtraction can push before now. If so, end immediately.
    if (newEnd.isBefore(now)) {
      // Set remaining to zero and end timer.
      _endTime = now;
      service.reset();
      setState(() {});
      return;
    }

    _endTime = newEnd;
    service.start(_endTime); // Persist new end time.

    // Update watch context with new end time.
    final watch = WatchConnectivity();
    watch.updateApplicationContext({
      'state': 'timer',
      'data': {
        'endTimeISO8601': _endTime.toIso8601String(),
      },
    });
    setState(() {});
  }

  void _resetTo(int seconds) {
    final service = GymModeRestTimerService.instance;

    _endTime = DateTime.now().add(Duration(seconds: seconds));
    service.start(_endTime);

    final watch = WatchConnectivity();
    watch.updateApplicationContext({
      'state': 'timer',
      'data': {
        'endTimeISO8601': _endTime.toIso8601String(),
      },
    });
    setState(() {});
  }
}