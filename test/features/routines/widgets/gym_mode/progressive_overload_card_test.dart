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
import 'package:wger/features/routines/models/log.dart';
import 'package:wger/features/routines/models/overload_option.dart';
import 'package:wger/features/routines/models/set_config_data.dart';
import 'package:wger/features/routines/models/weight_profile.dart';
import 'package:wger/features/routines/providers/gym_state.dart';
import 'package:wger/features/routines/providers/gym_state_notifier.dart';
import 'package:wger/features/routines/providers/weight_profiles_notifier.dart';
import 'package:wger/features/routines/providers/workout_logs_repository.dart';
import 'package:wger/features/routines/widgets/gym_mode/progressive_overload_card.dart';
import 'package:wger/features/routines/widgets/gym_mode/weight_profile_sheet.dart';
import 'package:wger/l10n/generated/app_localizations.dart';
import 'package:wger/l10n/localizations_delegates.dart';

import '../../../../../test_data/routines.dart' as testdata;
import 'progressive_overload_card_test.mocks.dart';

@GenerateMocks([WorkoutLogRepository])
void main() {
  late ProviderContainer container;
  late MockWorkoutLogRepository logRepo;
  late SetConfigData setConfig;

  void lastSessionWas(List<(num, num?)> sets) {
    when(logRepo.getLastSessionLogsByExercise(any, before: anyNamed('before'))).thenAnswer(
      (_) async => [
        for (final (reps, weight) in sets)
          Log(exerciseId: setConfig.exerciseId, repetitions: reps, weight: weight)
            ..weightUnit = testdata.testWeightUnit1,
      ],
    );
  }

  setUp(() {
    SharedPreferencesAsyncPlatform.instance = InMemorySharedPreferencesAsync.empty();
    logRepo = MockWorkoutLogRepository();
    when(
      logRepo.getDistinctWeightsByExercise(any, weightUnitId: anyNamed('weightUnitId')),
    ).thenAnswer((_) async => []);
    container = ProviderContainer.test(
      overrides: [workoutLogRepositoryProvider.overrideWithValue(logRepo)],
    );
    final routine = testdata.getTestRoutine();
    container.read(gymStateProvider.notifier)
      ..initData(routine, routine.days.first.id!, 1)
      ..calculatePages();
    setConfig = container
        .read(gymStateProvider)
        .pages
        .expand((p) => p.slotPages)
        .firstWhere((p) => p.type == SlotPageType.log)
        .setConfigData!;
    lastSessionWas([]);
  });

  Future<void> pumpCard(WidgetTester tester, {SetConfigData? config}) async {
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
          home: Scaffold(
            body: SingleChildScrollView(child: ProgressiveOverloadCard(config ?? setConfig)),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Map<int, OverloadOption> selected() => container.read(gymStateProvider).selectedOverload;

  testWidgets('without an earlier session there are no options', (tester) async {
    await pumpCard(tester);

    expect(find.text('No previous session yet, log as planned'), findsOneWidget);
    expect(find.byKey(const ValueKey('overload-option-planned')), findsNothing);
  });

  testWidgets('lists the options, choosing one and going back to planned', (tester) async {
    lastSessionWas([(10, 20), (10, 20)]);
    await pumpCard(tester);

    expect(find.text('Last time: 2 × (10 × 20 kg) = 400 kg'), findsOneWidget);
    expect(find.text('More repetitions'), findsOneWidget);
    expect(find.text('11 / 10 × 20 kg · Volume 420 kg'), findsOneWidget);
    expect(find.text('One more set'), findsOneWidget);
    expect(find.text('10 / 10 / 10 × 20 kg · Volume 600 kg'), findsOneWidget);
    expect(
      find.text('Add the weights your equipment offers to also get heavier options'),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const ValueKey('overload-option-1')));
    await tester.pump();
    expect(selected()[setConfig.slotEntryId]!.type, OverloadType.moreSets);

    await tester.tap(find.byKey(const ValueKey('overload-option-planned')));
    await tester.pump();
    expect(selected(), isEmpty);
  });

  testWidgets('offers the stored heavier weights', (tester) async {
    lastSessionWas([(10, 20), (10, 20)]);
    await _setWeights(container, setConfig.exerciseId, [
      22.5,
    ]);
    await pumpCard(tester);

    expect(find.text('Heavier weight'), findsOneWidget);
    expect(
      find.text(
        '9 / 9 × 22.5 kg · Volume 405 kg\n'
        'At least 18 repetitions in total (400 ÷ 22.5 = 17.8), split any way',
      ),
      findsOneWidget,
    );
    expect(
      find.text('Add the weights your equipment offers to also get heavier options'),
      findsNothing,
    );
  });

  testWidgets('explains the volume of a mixed session and what a heavier weight needs', (
    tester,
  ) async {
    final config = setConfig
      ..repetitions = 3
      ..maxRepetitions = 5;
    lastSessionWas([(5, 30), (5, 30), (5, 30), (5, 35), (5, 30)]);
    await _setWeights(container, setConfig.exerciseId, [
      30,
      32.5,
      35,
    ]);
    await pumpCard(tester, config: config);

    expect(
      find.text('Last time: 3 × (5 × 30 kg) + 5 × 35 kg + 5 × 30 kg = 775 kg'),
      findsOneWidget,
    );
    expect(
      find.text(
        '5 / 5 / 5 / 5 / 4 × 32.5 kg · Volume 780 kg\n'
        'At least 24 repetitions in total (775 ÷ 32.5 = 23.8), split any way',
      ),
      findsOneWidget,
    );
    expect(
      find.text(
        '5 / 5 / 5 / 4 / 4 × 35 kg · Volume 805 kg\n'
        'At least 23 repetitions in total (775 ÷ 35 = 22.1), split any way',
      ),
      findsOneWidget,
    );
  });

  testWidgets('says when every set is at the top of the range', (tester) async {
    final config = setConfig..maxRepetitions = 10;
    lastSessionWas([(10, 20)]);
    await pumpCard(tester, config: config);

    expect(find.text('More repetitions'), findsNothing);
    expect(
      find.text('Every set is at the top of the repetition range, time to go heavier'),
      findsOneWidget,
    );
  });

  testWidgets('the weights button opens the equipment weights sheet', (tester) async {
    lastSessionWas([(10, 20)]);
    await pumpCard(tester);

    await tester.tap(find.byKey(const ValueKey('progressive-overload-edit-weights')));
    await tester.pumpAndSettle();

    expect(find.byType(WeightProfileSheet), findsOneWidget);
  });

  testWidgets('volume without weight counts the repetitions', (tester) async {
    late BuildContext context;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (c) {
            context = c;
            return const SizedBox();
          },
        ),
      ),
    );
    const sets = [
      OverloadSet(weight: null, repetitions: 15),
      OverloadSet(weight: null, repetitions: 15),
      OverloadSet(weight: 0, repetitions: 12),
    ];

    expect(formatVolumeCalculation(context, sets, 'kg'), '2 × 15 + 12');
    expect(formatVolume(context, sets, 'kg'), '42');
  });

  group('formatOverloadSets', () {
    testWidgets('groups equal weights, lists different ones, leaves out none', (tester) async {
      late BuildContext context;
      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('de'),
          localizationsDelegates: appLocalizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Builder(
            builder: (c) {
              context = c;
              return const SizedBox();
            },
          ),
        ),
      );

      expect(
        formatOverloadSets(context, const [
          OverloadSet(weight: 22.5, repetitions: 9),
          OverloadSet(weight: 22.5, repetitions: 8),
        ], 'kg'),
        '9 / 8 × 22,5 kg',
      );
      expect(
        formatOverloadSets(context, const [
          OverloadSet(weight: 20, repetitions: 10),
          OverloadSet(weight: 22.5, repetitions: 8),
        ], 'kg'),
        '10 × 20 kg, 8 × 22,5 kg',
      );
      expect(
        formatOverloadSets(context, const [
          OverloadSet(weight: null, repetitions: 15),
          OverloadSet(weight: 0, repetitions: 12),
        ], 'kg'),
        '15 / 12',
      );
    });
  });
}

/// Assigns fixed equipment weights [weights] to the exercise [exerciseId]
Future<void> _setWeights(ProviderContainer container, int exerciseId, List<num> weights) async {
  final notifier = container.read(weightProfilesProvider.notifier);
  await container.read(weightProfilesProvider.future);
  await notifier.upsertProfile(
    WeightProfile(id: 'p$exerciseId', name: 'p', kind: WeightProfileKind.fixed, fixed: weights),
  );
  await notifier.assign(exerciseId, 'p$exerciseId');
}
