/*
 * This file is part of wger Workout Manager <https://github.com/wger-project>.
 * Copyright (c)  2026 wger Team
 *
 * wger Workout Manager is free software: you can redistribute it and/or modify
 * it under the terms of the GNU Affero General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU Affero General Public License for more details.
 *
 * You should have received a copy of the GNU Affero General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';
import 'package:wger/features/routines/models/weight_profile.dart';
import 'package:wger/features/routines/providers/weight_profiles_notifier.dart';
import 'package:wger/features/routines/widgets/gym_mode/weight_profile_sheet.dart';
import 'package:wger/l10n/generated/app_localizations.dart';
import 'package:wger/l10n/localizations_delegates.dart';

const _stack = WeightProfile(
  id: 'stack',
  name: 'Pec deck stack',
  kind: WeightProfileKind.linear,
  base: 1.25,
  step: 2.5,
  max: 48.75,
  bonus: [0.625, 0.625],
);

void main() {
  late ProviderContainer container;

  setUp(() {
    SharedPreferencesAsyncPlatform.instance = InMemorySharedPreferencesAsync.empty();
    container = ProviderContainer.test();
  });

  Future<void> assignStack() async {
    final notifier = container.read(weightProfilesProvider.notifier);
    await container.read(weightProfilesProvider.future);
    await notifier.upsertProfile(_stack);
    await notifier.assign(7, 'stack');
  }

  Future<void> pumpSheet(WidgetTester tester, {num? weight}) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          locale: const Locale('en'),
          localizationsDelegates: appLocalizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Builder(
            builder: (context) => TextButton(
              onPressed: () =>
                  showWeightProfileSheet(context, exerciseId: 7, weight: weight, unit: 'kg'),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
  }

  testWidgets('shows the pin and the add-ons for a stack weight', (tester) async {
    await tester.runAsync(assignStack);
    await pumpSheet(tester, weight: 40);

    expect(find.text('Pin at 38.75'), findsOneWidget);
    expect(find.text('Add-ons: 0.625 + 0.625'), findsOneWidget);
  });

  testWidgets('flags a weight the equipment cannot be set to', (tester) async {
    await tester.runAsync(assignStack);
    await pumpSheet(tester, weight: 37);

    expect(find.byKey(const ValueKey('weight-profile-unreachable')), findsOneWidget);
    expect(find.textContaining('Pin at'), findsNothing);
  });

  testWidgets('plate math for a bar with plates', (tester) async {
    await tester.runAsync(() async {
      final notifier = container.read(weightProfilesProvider.notifier);
      await container.read(weightProfilesProvider.future);
      await notifier.upsertProfile(WeightProfile.defaultPlates(id: 'sz', name: 'SZ bar'));
      await notifier.assign(7, 'sz');
    });
    await pumpSheet(tester, weight: 22.5);

    expect(find.text('Bar 10'), findsOneWidget);
    expect(find.text('Per side: 5 + 1.25'), findsOneWidget);
  });

  testWidgets('creates a stack with repeated add-ons and assigns it', (tester) async {
    await pumpSheet(tester, weight: 40);
    expect(find.byKey(const ValueKey('weight-profile-none')), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('weight-profile-create')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const ValueKey('weight-profile-name')), 'Pec deck');
    await tester.tap(find.text('Weight stack'));
    await tester.pumpAndSettle();

    Finder field(String key) => find.descendant(
      of: find.byKey(ValueKey('weight-profile-$key-linear')),
      matching: find.byType(TextFormField),
    );
    await tester.enterText(field('base'), '1.25');
    await tester.enterText(field('step'), '2.5');
    await tester.enterText(field('max'), '48.75');
    for (var i = 0; i < 2; i++) {
      final input = find.descendant(
        of: find.byKey(const ValueKey('weight-profile-bonus')),
        matching: find.byType(TextFormField),
      );
      await tester.enterText(input, '0.625');
      await tester.tap(find.byKey(const ValueKey('weight-add')));
      await tester.pumpAndSettle();
    }
    await tester.tap(find.byKey(const ValueKey('weight-profile-save')));
    await tester.pumpAndSettle();

    final state = await tester.runAsync(() => container.read(weightProfilesProvider.future));
    final saved = state!.profileFor(7)!;
    expect(saved.name, 'Pec deck');
    expect(saved.kind, WeightProfileKind.linear);
    expect(saved.base, 1.25);
    expect(saved.step, 2.5);
    expect(saved.max, 48.75);
    expect(saved.bonus, [0.625, 0.625]);
    expect(find.text('Pin at 38.75'), findsOneWidget);
  });
}
