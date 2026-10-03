import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wger/features/routines/services/gym_rest_timer.dart';

void main() {
  test('deadline survives time passing, adjusts, expires once and can restart', () {
    fakeAsync((time) {
      final start = DateTime.utc(2026);
      final updates = <Map<String, dynamic>>[];
      var alerts = 0;
      final timer = GymRestTimer(
        now: () => start.add(time.elapsed),
        sendUpdate: (update) async => updates.add(update),
        alert: () async => alerts++,
        alertsEnabled: () => true,
      );
      timer.ensureStarted(60);
      time.elapse(const Duration(seconds: 10));
      timer.ensureStarted(60);
      expect(timer.remainingSeconds, 50);
      timer.adjust(15);
      expect(timer.remainingSeconds, 65);
      timer.adjust(-15);
      time.elapse(const Duration(seconds: 50));
      expect(timer.endTime, isNull);
      expect(alerts, 1);
      expect(updates.last, {
        'timer': {'endTimeISO8601': null},
      });
      time.elapse(const Duration(seconds: 60));
      expect(alerts, 1);
      timer.ensureStarted(30);
      expect(timer.remainingSeconds, 30);
      timer.dispose();
    });
  });

  test('disabled alerts still clear timer and watch state', () {
    fakeAsync((time) {
      final updates = <Map<String, dynamic>>[];
      var alerts = 0;
      final timer = GymRestTimer(
        now: () => DateTime.utc(2026).add(time.elapsed),
        sendUpdate: (update) async => updates.add(update),
        alert: () async => alerts++,
        alertsEnabled: () => false,
      );
      timer.resetTo(15);
      time.elapse(const Duration(seconds: 15));
      expect(timer.endTime, isNull);
      expect(alerts, 0);
      expect(updates.last, {
        'timer': {'endTimeISO8601': null},
      });
      timer.dispose();
    });
  });

  test('reset cancels old expiry and shortening past zero expires immediately', () {
    fakeAsync((time) {
      var alerts = 0;
      final timer = GymRestTimer(
        now: () => DateTime.utc(2026).add(time.elapsed),
        sendUpdate: (_) async {},
        alert: () async => alerts++,
        alertsEnabled: () => true,
      );
      timer.resetTo(10);
      timer.resetTo(90);
      time.elapse(const Duration(seconds: 10));
      expect(timer.remainingSeconds, 80);
      expect(alerts, 0);
      timer.adjust(-90);
      expect(timer.endTime, isNull);
      expect(alerts, 1);
      timer.dispose();
    });
  });
}
