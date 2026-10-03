import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:wger/core/watch_companion.dart';
import 'package:wger/screens/watch_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final messenger = TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  const wear = MethodChannel('wear');
  const device = MethodChannel('dev.fluttercommunity.plus/device_info');

  setUp(() => debugDefaultTargetPlatformOverride = TargetPlatform.android);
  tearDown(() {
    debugDefaultTargetPlatformOverride = null;
    messenger.setMockMethodCallHandler(wear, null);
    messenger.setMockMethodCallHandler(device, null);
    for (final channel in ['watch_connectivity/messages', 'watch_connectivity/context']) {
      messenger.setMockMethodCallHandler(MethodChannel(channel), null);
    }
  });

  Map<String, dynamic> androidInfo(List<String> features) => {
    'version': {'sdkInt': 30, 'release': '11', 'codename': '', 'incremental': ''},
    for (final key in [
      'board',
      'bootloader',
      'brand',
      'device',
      'display',
      'fingerprint',
      'hardware',
      'host',
      'id',
      'manufacturer',
      'product',
      'tags',
      'type',
    ])
      key: '',
    'model': 'A name containing Watch is not detection',
    'time': 0,
    'isPhysicalDevice': true,
    'isLowRamDevice': false,
    'freeDiskSize': 100,
    'totalDiskSize': 200,
    'physicalRamSize': 100,
    'availableRamSize': 50,
    'systemFeatures': features,
  };

  test('isWear channel result routes watches and ordinary phones', () async {
    messenger.setMockMethodCallHandler(wear, (call) async {
      expect(call.method, 'isWear');
      return true;
    });
    expect(await detectWearDevice(), isTrue);
    messenger.setMockMethodCallHandler(wear, (_) async => false);
    expect(await detectWearDevice(), isFalse);
  });

  test('older wear plugin falls back to Android watch feature, never model', () async {
    messenger.setMockMethodCallHandler(wear, (_) async => throw MissingPluginException());
    messenger.setMockMethodCallHandler(
      device,
      (_) async => androidInfo(['android.hardware.type.watch']),
    );
    expect(await detectWearDevice(), isTrue);
    messenger.setMockMethodCallHandler(
      device,
      (_) async => androidInfo(['android.hardware.touchscreen']),
    );
    expect(await detectWearDevice(), isFalse);
  });

  test('missing plugins, platform errors and non-Android platforms use phone', () async {
    expect(await detectWearDevice(), isFalse);
    messenger.setMockMethodCallHandler(
      wear,
      (_) async => throw PlatformException(code: 'unavailable'),
    );
    messenger.setMockMethodCallHandler(
      device,
      (_) async => throw PlatformException(code: 'unavailable'),
    );
    expect(await detectWearDevice(), isFalse);
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    messenger.setMockMethodCallHandler(wear, (_) async => fail('Must not query Wear on iOS'));
    expect(await detectWearDevice(), isFalse);
  });

  testWidgets('watch root opens companion without building the phone app', (tester) async {
    debugDefaultTargetPlatformOverride = null;
    for (final channel in ['watch_connectivity/messages', 'watch_connectivity/context']) {
      messenger.setMockMethodCallHandler(MethodChannel(channel), (_) async => null);
    }
    await tester.pumpWidget(const ApplicationRoot(isWear: true, phoneApp: Text('Phone')));
    await tester.pump();
    expect(find.byType(WatchScreen), findsOneWidget);
    expect(find.text('Phone'), findsNothing);
    await tester.pumpWidget(const SizedBox());
    await tester.pump();
    expect(tester.takeException(), isNull);
  });

  testWidgets('phone root retains the supplied phone app unchanged', (tester) async {
    debugDefaultTargetPlatformOverride = null;
    const phoneApp = MaterialApp(home: Text('Phone'));
    const root = ApplicationRoot(isWear: false, phoneApp: phoneApp);
    expect(identical(root.phoneApp, phoneApp), isTrue);
    await tester.pumpWidget(root);
    expect(find.text('Phone'), findsOneWidget);
    expect(find.byType(WatchScreen), findsNothing);
  });
}
