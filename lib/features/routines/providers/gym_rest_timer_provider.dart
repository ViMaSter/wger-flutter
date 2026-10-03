import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vibration/vibration.dart';
import 'package:wger/core/watch_companion.dart';
import 'package:wger/features/routines/providers/gym_state_notifier.dart';
import 'package:wger/features/routines/services/gym_rest_timer.dart';

final gymRestTimerWatchUpdateProvider = Provider<Future<void> Function(Map<String, dynamic>)>(
  (ref) => sendWatchUpdate,
);
final gymRestTimerAlertProvider = Provider<Future<void> Function()>(
  (ref) =>
      () => notifyRestTimerExpired(),
);

final gymRestTimerProvider = Provider<GymRestTimer>((ref) {
  final timer = GymRestTimer(
    sendUpdate: ref.read(gymRestTimerWatchUpdateProvider),
    alert: ref.read(gymRestTimerAlertProvider),
    alertsEnabled: () => ref.read(gymStateProvider).alertOnCountdownEnd,
  );
  ref.listen(gymStateProvider, (previous, next) {
    if (previous != null &&
        (previous.workoutStart != next.workoutStart ||
            previous.isInitialized != next.isInitialized ||
            (previous.isInitialized && next.isInitialized && previous.dayId != next.dayId))) {
      timer.clear();
    }
  });
  ref.onDispose(timer.dispose);
  return timer;
});

Future<void> notifyRestTimerExpired({
  Future<bool> Function()? hasVibrator,
  Future<bool> Function()? hasCustomVibrationsSupport,
  Future<void> Function({int duration, List<int> pattern})? vibrate,
  Future<void> Function()? sound,
}) async {
  try {
    if (await (hasVibrator ?? Vibration.hasVibrator)()) {
      if (await (hasCustomVibrationsSupport ?? Vibration.hasCustomVibrationsSupport)()) {
        await (vibrate ?? Vibration.vibrate)(duration: 700, pattern: [0, 300, 150, 600]);
      } else {
        await (vibrate ?? Vibration.vibrate)(duration: 700, pattern: []);
      }
    }
  } on PlatformException {
    return _playExpirySound(sound);
  } on MissingPluginException {
    return _playExpirySound(sound);
  }
  await _playExpirySound(sound);
}

Future<void> _playExpirySound(Future<void> Function()? sound) async {
  try {
    await (sound ?? () => SystemSound.play(SystemSoundType.alert))();
  } on PlatformException {
    return;
  } on MissingPluginException {
    return;
  }
}
