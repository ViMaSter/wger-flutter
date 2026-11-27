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

import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:wger/features/routines/models/muscle_overload_plan.dart';
import 'package:wger/features/routines/widgets/gym_mode/programme_switch_card.dart';
import 'package:wger/l10n/generated/app_localizations.dart';
import 'package:wger/l10n/localizations_delegates.dart';

void main() {
  testWidgets('shows the compared session, the reached muscle groups and the gaps', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1080, 1920);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final plan = MuscleOverloadPlan(
      baselineDate: DateTime.utc(2026, 11, 21, 17),
      options: const {},
      targets: const [
        MuscleTarget(muscle: 'Quads', baseline: 2725, start: 96, planned: 192),
        MuscleTarget(muscle: 'Chest', baseline: 1285, start: 1140, planned: 1335),
      ],
    );

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: appLocalizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(body: ProgrammeSwitchCard(plan)),
      ),
    );

    expect(find.text('Programme switch'), findsOneWidget);
    expect(find.textContaining('11/21/2026'), findsOneWidget);
    expect(find.text('Chest: 1,335 vs 1,285'), findsOneWidget);
    expect(find.text('Quads: 2,533 short within the planned ranges'), findsOneWidget);
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('muscle-target-Quads')),
        matching: find.byIcon(Icons.warning_amber),
      ),
      findsOneWidget,
    );
  });
}
