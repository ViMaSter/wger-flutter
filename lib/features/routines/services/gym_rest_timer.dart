import 'dart:async';

import 'package:clock/clock.dart';
import 'package:logging/logging.dart';
import 'package:wger/features/routines/providers/gym_state.dart';

/// The end of the rest the user is currently in, null without a countdown.
///
/// The rest on the current page wins (so adjusting it is reflected right
/// away); on other pages, e.g. after swiping back to correct a set, it is the
/// most recently started rest.
DateTime? activeRestEnd(GymModeState state) {
  if (!state.isInitialized) {
    return null;
  }

  final current = state.getSlotEntryPageByIndex();
  SlotPageEntry? page;
  DateTime? startedAt;
  if (current?.type == SlotPageType.timer) {
    startedAt = state.progressOf(current!.key).timerStartedAt;
    page = startedAt == null ? null : current;
  }

  if (page == null) {
    for (final entry in state.pages) {
      for (final slotPage in entry.slotPages) {
        if (slotPage.type != SlotPageType.timer) {
          continue;
        }
        final start = state.progressOf(slotPage.key).timerStartedAt;
        if (start != null && (startedAt == null || start.isAfter(startedAt))) {
          startedAt = start;
          page = slotPage;
        }
      }
    }
  }

  if (page == null) {
    return null;
  }
  final duration = state.restDurationFor(page);
  return duration == null ? null : startedAt!.add(duration);
}

/// Follows the rest countdown kept in the gym state and does what the fork
/// adds on top: mirrors it to a paired watch and alerts once when it ends,
/// also while the user is on another gym mode page.
class GymRestTimer {
  final Future<void> Function(Map<String, dynamic>) sendUpdate;
  final Future<void> Function() alert;

  /// Whether an in-app alert is wanted right now (setting on, app in front)
  final bool Function() alertsEnabled;

  final _logger = Logger('GymRestTimer');

  Timer? _expiry;

  /// The end of the countdown that is still running, null if none is
  DateTime? _runningEnd;

  /// What the watch was last sent, to send changes only
  DateTime? _publishedEnd;

  GymRestTimer({
    required this.sendUpdate,
    required this.alert,
    required this.alertsEnabled,
  });

  DateTime? get endTime => _runningEnd;

  /// Re-evaluates the countdown after a gym state change
  void update(GymModeState state) {
    final end = activeRestEnd(state);
    if (end == _runningEnd) {
      return;
    }

    final wasRunning = _runningEnd != null;
    _expiry?.cancel();
    _expiry = null;

    final remaining = end?.difference(clock.now());
    if (end != null && remaining! > Duration.zero) {
      _runningEnd = end;
      _expiry = Timer(remaining, _expire);
      _publish();
      return;
    }

    _runningEnd = null;
    _publish();

    // Shortened past zero while running. Ends already over when first seen
    // (e.g. a restored workout) or rests that went away don't alert.
    if (wasRunning && end != null) {
      _alert();
    }
  }

  void _expire() {
    _expiry = null;
    if (_runningEnd == null) {
      return;
    }
    _runningEnd = null;
    _publish();
    _alert();
  }

  void _alert() {
    final enabled = alertsEnabled();
    _logger.fine('Rest ended, ${enabled ? 'alerting' : 'alert off or in background'}');
    if (enabled) {
      unawaited(_attempt(alert));
    }
  }

  void _publish() {
    if (_publishedEnd == _runningEnd) {
      return;
    }
    _publishedEnd = _runningEnd;
    final update = <String, dynamic>{
      'timer': {'endTimeISO8601': _runningEnd?.toIso8601String()},
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

  void dispose() {
    _expiry?.cancel();
  }
}
