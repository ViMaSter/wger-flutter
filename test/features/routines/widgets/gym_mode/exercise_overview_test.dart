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
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';
import 'package:wger/features/routines/providers/gym_state.dart';
import 'package:wger/features/routines/providers/gym_state_notifier.dart';
import 'package:wger/features/routines/providers/workout_logs_repository.dart';
import 'package:wger/features/routines/widgets/gym_mode/exercise_overview.dart';
import 'package:wger/features/routines/widgets/gym_mode/progressive_overload_card.dart';
import 'package:wger/l10n/generated/app_localizations.dart';
import 'package:wger/l10n/localizations_delegates.dart';

import '../../../../../test_data/routines.dart' as testdata;
import 'exercise_overview_test.mocks.dart';

@GenerateMocks([WorkoutLogRepository])
void main() {
  late ProviderContainer container;
  late MockWorkoutLogRepository logRepo;

  setUp(() {
    SharedPreferencesAsyncPlatform.instance = InMemorySharedPreferencesAsync.empty();
    logRepo = MockWorkoutLogRepository();
    when(
      logRepo.getDistinctWeightsByExercise(any, weightUnitId: anyNamed('weightUnitId')),
    ).thenAnswer((_) async => []);
    when(
      logRepo.getLastSessionLogsByExercise(any, before: anyNamed('before')),
    ).thenAnswer((_) async => []);
    container = ProviderContainer.test(
      overrides: [workoutLogRepositoryProvider.overrideWithValue(logRepo)],
    );
    final routine = testdata.getTestRoutine();
    container.read(gymStateProvider.notifier)
      ..initData(routine, routine.days.first.id!, 1)
      ..calculatePages();
  });

  Future<void> pumpOverview(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final overview = container
        .read(gymStateProvider)
        .pages
        .expand((p) => p.slotPages)
        .firstWhere((p) => p.type == SlotPageType.exerciseOverview);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          locale: const Locale('en'),
          localizationsDelegates: appLocalizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: Builder(
              builder: (context) {
                final controller = PageController();
                return PageView(
                  controller: controller,
                  children: [ExerciseOverview(controller, overview.key)],
                );
              },
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('shows the progressive overload card', (tester) async {
    await pumpOverview(tester);

    expect(find.byType(ProgressiveOverloadCard), findsOneWidget);
    expect(find.text('No previous session yet, log as planned'), findsOneWidget);
  });

  testWidgets('shows no card when the setting is off', (tester) async {
    container.read(gymStateProvider.notifier).setProgressiveOverload(false);
    await pumpOverview(tester);

    expect(find.byType(ProgressiveOverloadCard), findsNothing);
  });
}
