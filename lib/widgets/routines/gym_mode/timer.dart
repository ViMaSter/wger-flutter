/*
 * This file is part of wger Workout Manager <https://github.com/wger-project>.
 * Copyright (C) 2020, 2025 wger Team
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
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:watch_connectivity/watch_connectivity.dart';
import 'package:vibration/vibration.dart';
import 'package:wger/l10n/generated/app_localizations.dart';
import 'package:wger/providers/gym_state.dart';
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

  const TimerWidget(this._controller);

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
        ),
        Expanded(
          child: Center(
            child: Text(
              DateFormat('m:ss').format(displayTime),
              style: Theme.of(context).textTheme.displayLarge!.copyWith(color: wgerPrimaryColor),
            ),
          ),
        ),
        NavigationFooter(widget._controller),
      ],
    );
  }
}

class TimerCountdownWidget extends ConsumerStatefulWidget {
  final PageController _controller;
  final int _seconds;

  const TimerCountdownWidget(
    this._controller,
    this._seconds
  );

  @override
  _TimerCountdownWidgetState createState() => _TimerCountdownWidgetState();
}

class _TimerCountdownWidgetState extends ConsumerState<TimerCountdownWidget> {
  late DateTime _endTime;
  late Timer _uiTimer;
  bool _notifiedExpired = false;

  bool _hasNotified = false;

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
    final gymState = ref.watch(gymStateProvider);

    //  When countdown finishes, notify ONCE, and respect settings
    if (remainingSeconds == 0 && !_hasNotified) {
      if (gymState.alertOnCountdownEnd) {
        HapticFeedback.mediumImpact();

        // Not that this only works on desktop platforms
        SystemSound.play(SystemSoundType.alert);
      }
      setState(() {
        _hasNotified = true;
      });
    }

    // If expired, allow a subsequent re-entry to restart by clearing service.
    if (remainingSeconds == 0 && !_notifiedExpired) {
      _handleExpiry();
    }

    return Column(
      children: [
        NavigationHeader(
          AppLocalizations.of(context).pause,
          widget._controller,
        ),
        Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                DateFormat('m:ss').format(displayTime),
                style: Theme.of(context).textTheme.displayLarge!.copyWith(color: wgerPrimaryColor),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton.icon(
                    onPressed: () => _changeSeconds(-15),
                    icon: const Icon(Icons.remove),
                    label: const Text('-15s'),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    onPressed: () => _changeSeconds(15),
                    icon: const Icon(Icons.add),
                    label: const Text('+15s'),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Builder(builder: (context) {
                final gymState = ref.watch(gymStateProvider);
                final page = gymState.getSlotEntryPageByIndex();
                final minRest = page?.setConfigData?.restTime?.toInt();
                final maxRest = page?.setConfigData?.maxRestTime?.toInt();
                return Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ElevatedButton.icon(
                      onPressed: (minRest != null)
                          ? () => _resetTo(minRest)
                          : null,
                      icon: const Icon(Icons.timer),
                      label: Text(minRest != null ? 'Reset to ${minRest}s' : 'Reset to min'),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton.icon(
                      onPressed: (maxRest != null)
                          ? () => _resetTo(maxRest)
                          : null,
                      icon: const Icon(Icons.timer_outlined),
                      label: Text(maxRest != null ? 'Reset to ${maxRest}s' : 'Reset to max'),
                    ),
                  ],
                );
              }),
            ],
          ),
        ),
        NavigationFooter(widget._controller),
      ],
    );
  }

  Future<void> updateTimer() async {
    final service = GymModeRestTimerService.instance;
    // Reuse running timer if still active and not expired; otherwise start new.
    if (service.isActive && !service.isExpired) {
      _endTime = service.endTime;
      // Also refresh watch context with merged timer data
      await _updateWatchContext();
      return;
    }

    _endTime = DateTime.now().add(Duration(seconds: widget._seconds));
    service.start(_endTime);
    await _updateWatchContext();
  }

  Future<void> _changeSeconds(int delta) async {
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

    // Update watch context with merged timer data.
    await _updateWatchContext();
    setState(() {});
  }

  Future<void> _resetTo(int seconds) async {
    final service = GymModeRestTimerService.instance;
    _endTime = DateTime.now().add(Duration(seconds: seconds));
    service.start(_endTime);
    await _updateWatchContext();
    setState(() {});
  }

  /// Merges any existing watch contexts with current timer data, similar to the
  /// provided example, but focused on timer information.
  Future<void> _updateWatchContext() async {
    final watch = WatchConnectivity();
    Map<String, dynamic> existingContext = {};
    try {
      // Attempt to read existing context if the API provides it.
      final ctx = await watch.applicationContext;
      existingContext = Map<String, dynamic>.from(ctx);
    } catch (_) {
      // Ignore if not available on the current platform/API version.
    }

    final remaining = _endTime.difference(DateTime.now());
    final remainingSeconds = remaining.inSeconds <= 0 ? 0 : remaining.inSeconds;

    final mergedContext = <String, dynamic>{
      ...existingContext,
      'timer': {
        'endTimeISO8601': _endTime.toIso8601String(),
      },
    };

    await watch.updateApplicationContext(mergedContext);
    // Helpful log when developing/debugging
    print('[WATCH CONNECTIVITY] Merged timer context: $mergedContext');
  }

  Future<void> _handleExpiry() async {
    _notifiedExpired = true;
    final service = GymModeRestTimerService.instance;
    if (service.isExpired) {
      service.reset();
    }

    // Trigger vibration feedback (fall back silently if unavailable)
    try {
      if (await Vibration.hasVibrator()) {
        // Short pattern: vibrate, pause, vibrate longer
        if (await Vibration.hasCustomVibrationsSupport()) {
          await Vibration.vibrate(pattern: [0, 300, 150, 600]);
        } else {
          await Vibration.vibrate(duration: 700);
        }
      }
    } catch (_) {
      // ignore any vibration errors
    }
    // (Optional) Could schedule a local notification for background expiry here.
    setState(() {});
  }
}