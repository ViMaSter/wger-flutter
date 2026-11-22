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

import 'package:clock/clock.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';
import 'package:wger/core/shared_preferences.dart';
import 'package:wger/features/exercises/models/translation.dart';
import 'package:wger/features/routines/models/log.dart';
import 'package:wger/features/routines/models/overload_option.dart';
import 'package:wger/features/routines/models/page_progress.dart';
import 'package:wger/features/routines/models/weight_profile.dart';
import 'package:wger/features/routines/providers/gym_state_notifier.dart';
import 'package:wger/features/routines/providers/weight_profiles_notifier.dart';
import 'package:wger/features/routines/providers/workout_logs_repository.dart';
import 'package:wger/features/routines/widgets/gym_mode/workout_list_page.dart';
import 'package:wger/l10n/generated/app_localizations.dart';
import 'package:wger/l10n/localizations_delegates.dart';

import '../../../../../test_data/routines.dart' as testdata;
import 'workout_list_page_test.mocks.dart';

@GenerateMocks([WorkoutLogRepository])
void main() {
  late ProviderContainer container;
  late MockWorkoutLogRepository logRepo;
  late List<Log> added;

  // The first exercise is planned with 3 × 3 at 100 kg, see the test routine
  late List<String> firstExerciseRows;

  setUp(() {
    SharedPreferencesAsyncPlatform.instance = InMemorySharedPreferencesAsync.empty();
    added = [];
    logRepo = MockWorkoutLogRepository();
    when(logRepo.getLatestLogByExercise(any)).thenAnswer((_) async => null);
    when(
      logRepo.getDistinctWeightsByExercise(any, weightUnitId: anyNamed('weightUnitId')),
    ).thenAnswer((_) async => []);
    when(logRepo.addLocalDrift(any, dayId: anyNamed('dayId'))).thenAnswer((invocation) async {
      added.add((invocation.positionalArguments[0] as Log)..id = 'log-${added.length + 1}');
    });
    // Last time: two sets of 3 at 100 kg for the first exercise, nothing else
    when(logRepo.getLastSessionLogsByExercise(any, before: anyNamed('before'))).thenAnswer(
      (invocation) async => invocation.positionalArguments[0] == 1
          ? [
              for (var i = 0; i < 2; i++)
                Log(exerciseId: 1, repetitions: 3, weight: 100)
                  ..weightUnit = testdata.testWeightUnit1,
            ]
          : [],
    );

    container = ProviderContainer.test(
      overrides: [workoutLogRepositoryProvider.overrideWithValue(logRepo)],
    );

    // The shared fixture uses one slot entry for everything, give the second
    // slot its own so the exercises get their own blocks
    final routine = testdata.getTestRoutine();
    for (final day in routine.dayDataGym) {
      for (final config in day.slots.skip(1).expand((slot) => slot.setConfigs)) {
        config.slotEntryId = 2;
      }
    }
    final notifier = container.read(gymStateProvider.notifier)
      ..initData(routine, routine.days.first.id!, 1)
      ..calculatePages();
    firstExerciseRows = notifier.state.logPagesBySlotEntry.first.map((p) => p.key).toList();
  });

  Future<void> pumpList(WidgetTester tester, {Size size = const Size(1080, 4000)}) async {
    tester.view.physicalSize = size;
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
            body: Builder(
              builder: (context) {
                final controller = PageController();
                return PageView(
                  controller: controller,
                  children: [WorkoutListPage(controller), const Text('session page')],
                );
              },
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Finder field(String row, String column) => find.byKey(ValueKey('$row-$column'));

  String textOf(WidgetTester tester, String row, String column) =>
      tester.widget<TextField>(field(row, column)).controller!.text;

  bool isGreen(WidgetTester tester, String row, String column) =>
      tester.widget<TextField>(field(row, column)).decoration!.fillColor != Colors.transparent;

  testWidgets('pre-fills the smallest overload and marks what beats last time', (tester) async {
    await pumpList(tester);
    final [first, second, third] = firstExerciseRows;

    expect(find.textContaining('600 kg'), findsNothing, reason: 'No volume sum');
    expect(find.textContaining('Last time'), findsNothing);
    expect(find.byKey(ValueKey('$first-previous')), findsOneWidget);
    expect(find.text('100 × 3'), findsNWidgets(2));

    // One more repetition on the first set
    expect((textOf(tester, first, 'weight'), textOf(tester, first, 'reps')), ('100', '4'));
    expect((textOf(tester, second, 'weight'), textOf(tester, second, 'reps')), ('100', '3'));
    expect(isGreen(tester, first, 'reps'), isTrue);
    expect(isGreen(tester, first, 'weight'), isFalse);
    expect(isGreen(tester, second, 'reps'), isFalse);
    expect(isGreen(tester, second, 'weight'), isFalse);

    // Not done last time: new, so all of it counts
    expect(tester.widget<Text>(find.byKey(ValueKey('$third-previous'))).data, '–');
    expect(isGreen(tester, third, 'weight'), isTrue);
    expect(isGreen(tester, third, 'reps'), isTrue);
  });

  testWidgets('entered values come back when the page is built again', (tester) async {
    await pumpList(tester);
    final second = firstExerciseRows[1];

    await tester.enterText(field(second, 'reps'), '7');
    await tester.enterText(field(second, 'weight'), '97.5');
    await tester.pumpWidget(const SizedBox());
    await pumpList(tester);

    expect((textOf(tester, second, 'weight'), textOf(tester, second, 'reps')), ('97.5', '7'));
    expect(container.read(gymStateProvider).rowDrafts[second], (weight: 97.5, repetitions: 7));
  });

  testWidgets('shows the planned sets and repetitions above the options', (tester) async {
    final firstBlock = container.read(gymStateProvider).logPagesBySlotEntry.first;
    final slotEntryId = firstBlock.first.setConfigData!.slotEntryId;
    await pumpList(tester);

    // Planned 3 repetitions, no maximum
    Text range() => tester.widget<Text>(find.byKey(ValueKey('rep-range-$slotEntryId')));
    expect(range().data, '3 sets of 3 reps');

    for (final page in firstBlock) {
      page.setConfigData!.maxRepetitions = 5;
    }
    await tester.pumpWidget(const SizedBox());
    await pumpList(tester);
    expect(range().data, '3 sets of 3–5 reps');
    expect(
      tester.getTopLeft(find.byKey(ValueKey('rep-range-$slotEntryId'))).dy,
      lessThan(tester.getTopLeft(find.text('As before').first).dy),
    );
  });

  testWidgets('a heavier weight typed in turns its cell green', (tester) async {
    await pumpList(tester);
    final second = firstExerciseRows[1];

    await tester.enterText(field(second, 'weight'), '102.5');
    await tester.pump();

    expect(isGreen(tester, second, 'weight'), isTrue);
    expect(isGreen(tester, second, 'reps'), isFalse);
  });

  testWidgets('"as before" copies last time, the sets beyond it repeat its last one', (
    tester,
  ) async {
    // Unlike the plan (3 × 100 kg): 5 × 95 kg, then 4 × 95 kg
    when(logRepo.getLastSessionLogsByExercise(1, before: anyNamed('before'))).thenAnswer(
      (_) async => [
        for (final reps in [5, 4])
          Log(exerciseId: 1, repetitions: reps, weight: 95)..weightUnit = testdata.testWeightUnit1,
      ],
    );
    await pumpList(tester);
    final [first, second, third] = firstExerciseRows;

    await tester.tap(find.text('As before').first);
    await tester.pumpAndSettle();

    expect((textOf(tester, first, 'weight'), textOf(tester, first, 'reps')), ('95', '5'));
    expect((textOf(tester, second, 'weight'), textOf(tester, second, 'reps')), ('95', '4'));
    expect((textOf(tester, third, 'weight'), textOf(tester, third, 'reps')), ('95', '4'));
    expect(isGreen(tester, first, 'reps'), isFalse);
    expect(isGreen(tester, second, 'weight'), isFalse);
    expect(find.text('As planned'), findsNothing);
  });

  testWidgets('shows every planned set although last time had fewer', (tester) async {
    await pumpList(tester);

    // Planned 3, done 2 last time
    expect(firstExerciseRows, hasLength(3));
    for (final row in firstExerciseRows) {
      expect(find.byKey(ValueKey('$row-done')), findsOneWidget);
    }
  });

  testWidgets('no repetitions-needed line for a heavier option', (tester) async {
    await _setWeights(container, 1, [110]);
    await pumpList(tester);

    await tester.tap(find.text('110 kg'));
    await tester.pumpAndSettle();

    expect(textOf(tester, firstExerciseRows.first, 'weight'), '110');
    expect(find.textContaining('repetitions in total'), findsNothing);
  });

  testWidgets('checking a set logs the values of its row and starts the rest', (tester) async {
    await pumpList(tester);
    final first = firstExerciseRows.first;
    expect(find.byKey(const ValueKey('rest-bar')), findsNothing);

    await tester.enterText(field(first, 'reps'), '5');
    await tester.tap(find.byKey(ValueKey('$first-done')));
    await tester.pumpAndSettle();

    expect(added.single.repetitions, 5);
    expect(added.single.weight, 100);
    expect(container.read(gymStateProvider).progressOf(first).done, isTrue);
    expect(tester.widget<TextField>(field(first, 'reps')).enabled, isFalse);
    expect(find.byKey(const ValueKey('rest-bar')), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('rest-bar-skip')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('rest-bar')), findsNothing);
  });

  testWidgets('the rest bar adjusts the countdown like the timer page', (tester) async {
    final now = DateTime.utc(2026, 11, 22, 10);
    await withClock(Clock.fixed(now), () async {
      // 120s rest from the test routine, plus a maximum for this test
      final firstBlock = container.read(gymStateProvider).logPagesBySlotEntry.first;
      for (final page in firstBlock) {
        page.setConfigData!.maxRestTime = 180;
      }
      await pumpList(tester);
      await tester.tap(find.byKey(ValueKey('${firstExerciseRows.first}-done')));
      await tester.pumpAndSettle();

      DateTime? endsAt() => container.read(gymStateProvider).restEndsAt;
      expect(endsAt(), now.add(const Duration(seconds: 120)));
      expect(find.text('Rest 2:00'), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('rest-bar-plus')));
      await tester.pump();
      expect(endsAt(), now.add(const Duration(seconds: 135)));
      expect(find.text('Rest 2:15'), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('rest-bar-minus')));
      await tester.tap(find.byKey(const ValueKey('rest-bar-minus')));
      await tester.pump();
      expect(endsAt(), now.add(const Duration(seconds: 105)));

      await tester.tap(find.byKey(const ValueKey('rest-bar-max')));
      await tester.pump();
      expect(endsAt(), now.add(const Duration(seconds: 180)));

      await tester.tap(find.byKey(const ValueKey('rest-bar-min')));
      await tester.pump();
      expect(endsAt(), now.add(const Duration(seconds: 120)));
    });
  });

  testWidgets('without a maximum rest its button is disabled', (tester) async {
    await pumpList(tester);
    await tester.tap(find.byKey(ValueKey('${firstExerciseRows.first}-done')));
    await tester.pumpAndSettle();

    expect(
      tester.widget<IconButton>(find.byKey(const ValueKey('rest-bar-max'))).onPressed,
      isNull,
    );
    expect(
      tester.widget<IconButton>(find.byKey(const ValueKey('rest-bar-min'))).onPressed,
      isNotNull,
    );
  });

  testWidgets('"add set" adds a row that logs an extra set', (tester) async {
    await pumpList(tester);
    final slotEntryId = container
        .read(gymStateProvider)
        .logPagesBySlotEntry
        .first
        .first
        .setConfigData!
        .slotEntryId;

    await tester.tap(find.byKey(ValueKey('add-set-$slotEntryId')));
    await tester.pumpAndSettle();
    final row = 'pending:$slotEntryId:0';
    expect(field(row, 'reps'), findsOneWidget);

    await tester.tap(find.byKey(ValueKey('$row-done')));
    await tester.pumpAndSettle();

    expect(added.single.slotEntryId, slotEntryId);
    expect(container.read(gymStateProvider).extraLogs[slotEntryId], hasLength(1));
    expect(field('extra:$slotEntryId:0', 'reps'), findsOneWidget);
    expect(field(row, 'reps'), findsNothing);
  });

  group('description, volume and totals', () {
    int slotEntryOf(int block) => container
        .read(gymStateProvider)
        .logPagesBySlotEntry[block]
        .first
        .setConfigData!
        .slotEntryId;

    void setDescription(int block, String description) {
      for (final page in container.read(gymStateProvider).logPagesBySlotEntry[block]) {
        final exercise = page.setConfigData!.exercise;
        final translation = exercise.translations.first;
        page.setConfigData!.exercise = exercise.copyWith(
          translations: [
            Translation(
              id: translation.id,
              uuid: translation.uuid,
              created: translation.created,
              name: translation.name,
              description: description,
              exerciseId: translation.exerciseId,
              language: translation.language,
            ),
          ],
        );
      }
    }

    testWidgets('shows the description above the planned sets, none when empty', (tester) async {
      setDescription(0, '<p>Keep <a href="https://example.com">the back</a> flat</p>');
      setDescription(1, '  ');
      await pumpList(tester);

      final description = find.byKey(ValueKey('exercise-description-${slotEntryOf(0)}'));
      expect(description, findsOneWidget);
      expect(
        find.descendant(
          of: description,
          matching: find.textContaining('the back', findRichText: true),
        ),
        findsOneWidget,
      );
      expect(
        tester.getBottomLeft(description).dy,
        lessThanOrEqualTo(
          tester.getTopLeft(find.byKey(ValueKey('rep-range-${slotEntryOf(0)}'))).dy,
        ),
      );
      expect(find.byKey(ValueKey('exercise-description-${slotEntryOf(1)}')), findsNothing);
    });

    testWidgets('planned volume of the targets, actual volume of the logged sets', (tester) async {
      await pumpList(tester);
      final slotEntryId = slotEntryOf(0);
      final [first, second, _] = firstExerciseRows;
      String volume() => tester.widget<Text>(find.byKey(ValueKey('volume-$slotEntryId'))).data!;

      // Pre-filled: 100 × 4, 100 × 3, 100 × 3
      expect(volume(), 'Planned 1,000 kg · Actual 0 kg');

      // Entered values count as the target of their set
      await tester.enterText(field(second, 'reps'), '5');
      await tester.pump();
      expect(volume(), 'Planned 1,200 kg · Actual 0 kg');

      // The logged values of a set, here more than pre-filled
      await tester.enterText(field(first, 'reps'), '6');
      await tester.tap(find.byKey(ValueKey('$first-done')));
      await tester.pumpAndSettle();
      expect(volume(), 'Planned 1,400 kg · Actual 600 kg');

      // An extra set only adds to what was done
      await tester.tap(find.byKey(ValueKey('add-set-$slotEntryId')));
      await tester.pumpAndSettle();
      await tester.enterText(field('pending:$slotEntryId:0', 'weight'), '50');
      await tester.enterText(field('pending:$slotEntryId:0', 'reps'), '2');
      await tester.tap(find.byKey(ValueKey('pending:$slotEntryId:0-done')));
      await tester.pumpAndSettle();
      // ... and with last time beaten, the set still to do shrinks to one rep
      expect(volume(), 'Planned 1,200 kg · Actual 700 kg');
    });

    testWidgets('totals of last time and today with the difference', (tester) async {
      await pumpList(tester);
      final slotEntryId = slotEntryOf(0);
      String text(String cell) =>
          tester.widget<Text>(find.byKey(ValueKey('total-$cell-$slotEntryId'))).data ??
          tester
              .widget<Text>(
                find.descendant(
                  of: find.byKey(ValueKey('total-$cell-$slotEntryId')),
                  matching: find.byType(Text),
                ),
              )
              .data!;
      Text diffText() => tester.widget<Text>(
        find.descendant(
          of: find.byKey(ValueKey('total-diff-$slotEntryId')),
          matching: find.byType(Text),
        ),
      );
      Color? diffBackground() =>
          (tester.widget<Container>(find.byKey(ValueKey('total-diff-$slotEntryId'))).decoration!
                  as BoxDecoration)
              .color;
      final context = tester.element(find.byKey(ValueKey('total-diff-$slotEntryId')));
      final scheme = Theme.of(context).colorScheme;

      // Last time 2 × 3 × 100 kg
      expect(text('previous'), 'Total 600');
      expect(text('current'), '0');
      expect(diffText().data, '−600');
      expect(diffText().style!.color, scheme.error);
      expect(diffBackground(), isNull);

      for (final row in firstExerciseRows) {
        await tester.tap(find.byKey(ValueKey('$row-done')));
        await tester.pumpAndSettle();
      }

      // 100 × 4 + 100 × 3 + 100 × 3
      expect(text('current'), '1,000');
      expect(diffText().data, '+400');
      expect(diffText().style!.color, isNot(scheme.error));
      expect(diffBackground(), progressionHighlight(context));

      // The totals line up under the header columns
      expect(
        tester.getCenter(find.byKey(ValueKey('total-current-$slotEntryId'))).dx,
        closeTo(tester.getCenter(field(firstExerciseRows.first, 'weight')).dx, 1),
      );
    });
  });

  group('adapting to what was logged', () {
    // Last time 3 × 8 at 100 kg in a range of 6–8, the equipment also has
    // 120 kg: the heavier option is 7 / 7 / 7 at 120 kg (2520 > 2400)
    setUp(() {
      when(logRepo.getLastSessionLogsByExercise(any, before: anyNamed('before'))).thenAnswer(
        (invocation) async => invocation.positionalArguments[0] == 1
            ? [
                for (var i = 0; i < 3; i++)
                  Log(exerciseId: 1, repetitions: 8, weight: 100)
                    ..weightUnit = testdata.testWeightUnit1,
              ]
            : [],
      );
      when(
        logRepo.getDistinctWeightsByExercise(any, weightUnitId: anyNamed('weightUnitId')),
      ).thenAnswer((invocation) async => invocation.positionalArguments[0] == 1 ? [100] : []);
      for (final page in container.read(gymStateProvider).logPagesBySlotEntry.first) {
        page.setConfigData!
          ..repetitions = 6
          ..maxRepetitions = 8;
      }
    });

    Future<void> logFirst(WidgetTester tester, String reps) async {
      final first = firstExerciseRows.first;
      await tester.enterText(field(first, 'reps'), reps);
      await tester.tap(find.byKey(ValueKey('$first-done')));
      await tester.pumpAndSettle();
    }

    testWidgets('more repetitions than planned shrink the sets still to do', (tester) async {
      await _setWeights(container, 1, [120]);
      await pumpList(tester);
      final [_, second, third] = firstExerciseRows;
      expect(textOf(tester, second, 'reps'), '7');
      expect(textOf(tester, third, 'reps'), '7');

      await logFirst(tester, '8');

      // 960 + 7 × 120 + 6 × 120 = 2520, the least still beating 2400
      expect((textOf(tester, second, 'weight'), textOf(tester, second, 'reps')), ('120', '7'));
      expect((textOf(tester, third, 'weight'), textOf(tester, third, 'reps')), ('120', '6'));
      expect(find.byKey(const ValueKey('fill-help-1')), findsNothing);
    });

    testWidgets('falling short offers extra sets with a lighter weight', (tester) async {
      await _setWeights(container, 1, [120]);
      await pumpList(tester);

      // 360 + 2 × 8 × 120 = 2280 can't beat 2400 anymore
      await logFirst(tester, '3');

      expect(find.byKey(const ValueKey('fill-help-1')), findsOneWidget);
      expect(find.textContaining('Fill with 100 kg'), findsOneWidget);
      // Only one lighter weight is known, so ask for more
      expect(find.byKey(const ValueKey('fill-need-weights-1')), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('fill-chip-1-0')));
      await tester.pumpAndSettle();

      expect(textOf(tester, 'pending:1:0', 'weight'), '100');
      expect(find.byKey(const ValueKey('fill-help-1')), findsNothing);
      expect(container.read(gymStateProvider).selectedOverload[1]!.type, OverloadType.fill);
    });

    testWidgets('a lighter weight typed into a set is fatigue too', (tester) async {
      await _setWeights(container, 1, [120]);
      await pumpList(tester);
      final [first, second, third] = firstExerciseRows;

      for (final row in [first, second, third]) {
        await tester.enterText(field(row, 'weight'), '100');
      }
      await tester.pumpAndSettle();

      // 3 × 8 × 100 = 2400 at most, not more than last time
      expect(find.byKey(const ValueKey('fill-help-1')), findsOneWidget);
    });

    testWidgets('plate math icon warns about a weight the equipment lacks', (tester) async {
      await _setWeights(container, 1, [120]);
      await pumpList(tester);
      final first = firstExerciseRows.first;
      IconData iconOf() => tester
          .widget<Icon>(
            find.descendant(
              of: find.byKey(ValueKey('$first-plates')),
              matching: find.byType(Icon),
            ),
          )
          .icon!;

      expect(iconOf(), Icons.fitness_center);
      await tester.enterText(field(first, 'weight'), '115');
      await tester.pump();
      expect(iconOf(), Icons.warning_amber_rounded);

      await tester.enterText(field(first, 'weight'), '120');
      await tester.pump();
      await tester.tap(find.byKey(ValueKey('$first-plates')));
      await tester.pumpAndSettle();
      expect(find.text('Take 120'), findsOneWidget);
    });
  });

  group('continuing a workout', () {
    void markDone(Iterable<String> keys) {
      final notifier = container.read(gymStateProvider.notifier);
      notifier.state = notifier.state.copyWith(
        progress: {for (final key in keys) key: const PageProgress(done: true)},
      );
    }

    testWidgets('scrolls the first open set to the middle', (tester) async {
      final blocks = container.read(gymStateProvider).logPagesBySlotEntry;
      // The first exercise is done, the second one is next
      final next = blocks[1].first.key;
      markDone(firstExerciseRows);

      await pumpList(tester, size: const Size(800, 500));

      final list = tester.getRect(find.byKey(const ValueKey('workout-list')));
      final row = tester.getRect(find.byKey(ValueKey('set-row-$next')));
      expect(list.contains(row.center), isTrue, reason: 'next set on screen');
      expect(row.center.dy, closeTo(list.center.dy, list.height * 0.15), reason: 'centred');
      expect(
        tester.getRect(find.byKey(ValueKey('set-row-${firstExerciseRows.first}'))).bottom,
        lessThan(list.top),
        reason: 'first set scrolled off',
      );
    });

    testWidgets('stays at the top when no set is logged yet', (tester) async {
      // Short enough that the first set sits below the middle
      await pumpList(tester, size: const Size(800, 400));

      final scrollable = tester.state<ScrollableState>(
        find
            .descendant(
              of: find.byKey(const ValueKey('workout-list')),
              matching: find.byType(Scrollable),
            )
            .first,
      );
      expect(scrollable.position.pixels, 0);
    });
  });

  group('finishing the workout', () {
    void markDone(Iterable<String> keys) {
      final notifier = container.read(gymStateProvider.notifier);
      notifier.state = notifier.state.copyWith(
        progress: {for (final key in keys) key: const PageProgress(done: true)},
      );
    }

    Future<String?> storedProgress(WidgetTester tester) => tester.runAsync<String?>(
      () => PreferenceHelper.asyncPref.getString(PREFS_WORKOUT_PROGRESS),
    );

    testWidgets('asks first, listing the exercises with sets left', (tester) async {
      final state = container.read(gymStateProvider);
      final blocks = state.logPagesBySlotEntry;
      final secondSlotEntry = blocks[1].first.setConfigData!.slotEntryId;
      final firstSlotEntry = blocks[0].first.setConfigData!.slotEntryId;
      markDone([...firstExerciseRows, blocks[1].first.key]);
      await pumpList(tester);

      await tester.tap(find.byKey(const ValueKey('finish-workout')));
      await tester.pumpAndSettle();

      expect(find.byType(FinishWorkoutDialog), findsOneWidget);
      expect(find.text('Finish with fewer sets?'), findsOneWidget);
      expect(find.byKey(ValueKey('finish-missing-$firstSlotEntry')), findsNothing);
      expect(
        find.descendant(
          of: find.byType(FinishWorkoutDialog),
          matching: find.text(
            blocks[1].first.setConfigData!.exercise.getTranslation('en').name,
          ),
        ),
        findsOneWidget,
      );
      expect(
        tester.widget<Text>(find.byKey(ValueKey('finish-planned-$secondSlotEntry'))).data,
        '3',
      );
      expect(tester.widget<Text>(find.byKey(ValueKey('finish-logged-$secondSlotEntry'))).data, '1');

      // Cancel keeps the workout
      await tester.tap(find.byKey(const ValueKey('finish-workout-cancel')));
      await tester.pumpAndSettle();
      expect(find.byType(FinishWorkoutDialog), findsNothing);
      expect(container.read(gymStateProvider).progressOf(blocks[1].first.key).done, isTrue);
      expect(find.text('session page'), findsNothing);

      await tester.tap(find.byKey(const ValueKey('finish-workout')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('finish-workout-confirm')));
      await tester.pumpAndSettle();

      expect(container.read(gymStateProvider).progress, isEmpty);
      expect(find.text('session page'), findsOneWidget);
    });

    testWidgets('finishes right away with every planned set logged', (tester) async {
      final blocks = container.read(gymStateProvider).logPagesBySlotEntry;
      markDone(blocks.expand((block) => block).map((p) => p.key));
      await pumpList(tester);
      // Something stored, so it can be seen to go
      container.read(gymStateProvider.notifier).setRowDraft('x', weight: 1, repetitions: 1);
      expect(await storedProgress(tester), isNotNull);

      await tester.tap(find.byKey(const ValueKey('finish-workout')));
      await tester.pumpAndSettle();

      expect(find.byType(FinishWorkoutDialog), findsNothing);
      expect(find.text('session page'), findsOneWidget);
      expect(await storedProgress(tester), isNull);
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
