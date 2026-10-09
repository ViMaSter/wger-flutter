/*
 * This file is part of wger Workout Manager <https://github.com/wger-project>.
 * Copyright (c) 2025 - 2026 wger Team
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

import 'dart:async';

import 'package:flutter/gestures.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:wger/core/widgets/error.dart';
import 'package:wger/features/exercises/models/exercise.dart';
import 'package:wger/features/routines/models/day_data.dart';
import 'package:wger/features/routines/models/log.dart';
import 'package:wger/features/routines/models/routine.dart';
import 'package:wger/features/routines/models/set_config_data.dart';
import 'package:wger/features/routines/models/slot_data.dart';
import 'package:wger/features/routines/providers/gym_log_notifier.dart';
import 'package:wger/features/routines/providers/gym_state.dart';
import 'package:wger/features/routines/providers/gym_state_notifier.dart';
import 'package:wger/features/routines/providers/workout_logs_repository.dart';
import 'package:wger/features/routines/widgets/gym_mode/linkified_comment.dart';
import 'package:wger/features/routines/widgets/gym_mode/log_page.dart';
import 'package:wger/l10n/generated/app_localizations.dart';
import 'package:wger/l10n/localizations_delegates.dart';

import '../../../../../test_data/exercises.dart';
import '../../../../../test_data/routines.dart' as testdata;
import 'log_page_test.mocks.dart';

/// Strips the exercise off a fixture log, watchLogsByExerciseDrift only joins the units
Log asDriftLog(Log log) =>
    Log(
        id: log.id,
        exerciseId: log.exerciseId,
        iteration: log.iteration,
        slotEntryId: log.slotEntryId,
        routineId: log.routineId,
        sessionId: log.sessionId,
        repetitions: log.repetitions,
        rir: log.rir,
        weight: log.weight,
        date: log.date,
      )
      ..repetitionUnit = log.repetitionsUnitObj
      ..weightUnit = log.weightUnitObj;

@GenerateMocks([WorkoutLogRepository])
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('LogPage tests', () {
    late List<Exercise> testExercises;
    late ProviderContainer container;
    late MockWorkoutLogRepository mockWorkoutLogRepo;
    late List<Map<String, dynamic>> watchUpdates;

    setUp(() {
      watchUpdates = [];
      SharedPreferencesAsyncPlatform.instance = InMemorySharedPreferencesAsync.empty();
      testExercises = getTestExercises();
      mockWorkoutLogRepo = MockWorkoutLogRepository();
      when(mockWorkoutLogRepo.addLocalDrift(any)).thenAnswer((_) async {});
      // Past logs on the page come from this stream (per exercise); reuse the
      // test routine's logs so the previous-entries assertions keep working.
      when(
        mockWorkoutLogRepo.watchLogsByExerciseDrift(
          routineId: anyNamed('routineId'),
          exerciseId: anyNamed('exerciseId'),
        ),
      ).thenAnswer((invocation) {
        final exerciseId = invocation.namedArguments[#exerciseId] as int;
        return Stream.value(
          testdata.getTestRoutine().filterLogsByExercise(exerciseId).map(asDriftLog).toList(),
        );
      });
      container = ProviderContainer.test(
        overrides: [workoutLogRepositoryProvider.overrideWithValue(mockWorkoutLogRepo)],
      );
    });

    /// Seeds the gym state with [routine] and navigates to the first log page
    /// (index 2: start -> exercise overview -> log). [setCurrentPage] also
    /// seeds gymLogProvider with the log template for that slot.
    void seedLogPage(Routine routine) {
      final notifier = container.read(gymStateProvider.notifier);
      notifier.initData(routine, routine.days.first.id!, 1);
      notifier.setCurrentPage(2);
    }

    Future<void> pumpLogPage(WidgetTester tester, {String? uuid}) async {
      // The widget resolves its own slot now, so hand it the uuid of the slot
      // the gym state was seeded on (via setCurrentPage above).
      final slotUuid = uuid ?? container.read(gymStateProvider).getSlotEntryPageByIndex()!.uuid;
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            locale: const Locale('en'),
            localizationsDelegates: appLocalizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(
              // A PageView gives LogPage's PageController something to attach to.
              body: Builder(
                builder: (context) {
                  final controller = PageController();
                  return PageView(
                    controller: controller,
                    children: [
                      LogPage(
                        controller,
                        slotUuid,
                        watchUpdate: (update) async {
                          watchUpdates.add(update);
                        },
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('counts only log pages after indices are recalculated', (tester) async {
      seedLogPage(testdata.getTestRoutine());
      final notifier = container.read(gymStateProvider.notifier);
      notifier.recalculateIndices();
      final logs = notifier.state.pages
          .firstWhere((page) => page.type == PageType.set)
          .slotPages
          .where((page) => page.type == SlotPageType.log)
          .toList();
      expect(logs.length, greaterThan(1));
      notifier.setCurrentPage(logs[1].pageIndex);
      await pumpLogPage(tester);

      expect(find.text('2 / ${logs.length}'), findsOneWidget);
      expect(watchUpdates.single['exercise'], {
        'exerciseName': logs[1].setConfigData!.exercise.getTranslation('en').name,
        'repetitions': logs[1].setConfigData!.repetitions,
        'weight': logs[1].setConfigData!.weight,
        'currentSetCount': 2,
        'totalSetCount': logs.length,
      });
    });

    testWidgets('shows the routine slot comment on the phone log page only', (tester) async {
      const comment = 'Warm up: 4 Sets - https://www.youtube.com/watch?v=htDXu61MPio';
      final routine = testdata.getTestRoutine();
      routine.dayDataGym.first.slots.first.comment = comment;
      seedLogPage(routine);
      await pumpLogPage(tester);

      final linkifiedComment = tester.widget<LinkifiedComment>(find.byType(LinkifiedComment));
      expect(linkifiedComment.text, comment);
      expect((watchUpdates.single['exercise'] as Map).containsKey('comment'), isFalse);
    });

    testWidgets('prebuilt inactive log page sends nothing until it becomes current', (
      tester,
    ) async {
      seedLogPage(testdata.getTestRoutine());
      final notifier = container.read(gymStateProvider.notifier);
      final logs = notifier.state.pages
          .firstWhere((page) => page.type == PageType.set)
          .slotPages
          .where((page) => page.type == SlotPageType.log)
          .toList();
      await pumpLogPage(tester, uuid: logs[1].uuid);
      expect(watchUpdates, isEmpty);

      notifier.setCurrentPage(logs[1].pageIndex);
      await tester.pumpAndSettle();
      expect(watchUpdates, hasLength(1));
      expect((watchUpdates.single['exercise'] as Map)['currentSetCount'], 2);

      notifier.setCurrentPage(logs[0].pageIndex);
      await tester.pumpAndSettle();
      expect(watchUpdates, hasLength(1));
      notifier.setCurrentPage(logs[1].pageIndex);
      await tester.pumpAndSettle();
      expect(watchUpdates, hasLength(2));
    });

    testWidgets('superset count preserves alternating exercise and differing set order', (
      tester,
    ) async {
      final routine = testdata.getTestRoutine();
      final template = routine.dayDataGym.first.slots.first.setConfigs.first;
      routine.dayDataGym.first.slots = [
        SlotData(
          isSuperset: true,
          exerciseIds: [testExercises[0].id, testExercises[1].id],
          setConfigs: [
            template.copyWith(
              exerciseId: testExercises[0].id,
              exercise: testExercises[0],
              repetitions: 10,
            ),
            template.copyWith(
              exerciseId: testExercises[1].id,
              exercise: testExercises[1],
              repetitions: 8,
            ),
            template.copyWith(
              exerciseId: testExercises[0].id,
              exercise: testExercises[0],
              repetitions: 6,
            ),
          ],
        ),
      ];
      seedLogPage(routine);
      final notifier = container.read(gymStateProvider.notifier);
      notifier.recalculateIndices();
      final logs = notifier.state.pages
          .firstWhere((page) => page.type == PageType.set)
          .slotPages
          .where((page) => page.type == SlotPageType.log)
          .toList();
      expect(logs.map((page) => page.setConfigData!.exerciseId), [
        testExercises[0].id,
        testExercises[1].id,
        testExercises[0].id,
      ]);
      notifier.setCurrentPage(logs[1].pageIndex);
      await pumpLogPage(tester);
      expect(find.text('2 / 3'), findsOneWidget);
      expect((watchUpdates.last['exercise'] as Map)['repetitions'], 8);
      notifier.setCurrentPage(logs[2].pageIndex);
      await pumpLogPage(tester);
      expect(find.text('3 / 3'), findsOneWidget);
      expect((watchUpdates.last['exercise'] as Map)['repetitions'], 6);
    });

    testWidgets('page change before frame dispatch cancels stale watch update', (tester) async {
      seedLogPage(testdata.getTestRoutine());
      WidgetsBinding.instance.addPostFrameCallback((_) {
        container.read(gymStateProvider.notifier).setCurrentPage(0);
      });
      await pumpLogPage(tester);
      expect(watchUpdates, isEmpty);
    });

    testWidgets('exercise change sends the new exercise with its slot set count', (tester) async {
      seedLogPage(testdata.getTestRoutine());
      await pumpLogPage(tester);
      final notifier = container.read(gymStateProvider.notifier);
      final currentExercise = notifier.state.getSlotEntryPageByIndex()!.setConfigData!.exerciseId;
      final next = notifier.state.pages
          .expand((page) => page.slotPages)
          .firstWhere(
            (page) =>
                page.type == SlotPageType.log && page.setConfigData!.exerciseId != currentExercise,
          );
      notifier.setCurrentPage(next.pageIndex);
      await pumpLogPage(tester);
      final exercise = watchUpdates.last['exercise'] as Map;
      expect(exercise['exerciseName'], next.setConfigData!.exercise.getTranslation('en').name);
      expect(exercise['currentSetCount'], 1);
      expect(exercise['repetitions'], next.setConfigData!.repetitions);
      expect(exercise['weight'], next.setConfigData!.weight);
    });

    testWidgets('watch tracks edited repetitions and weight without rebuild duplicates', (
      tester,
    ) async {
      seedLogPage(testdata.getTestRoutine());
      await pumpLogPage(tester);
      container.read(gymLogProvider.notifier).setRepetitions(12);
      container.read(gymLogProvider.notifier).setWeight(34);
      await tester.pumpAndSettle();
      expect((watchUpdates.last['exercise'] as Map)['repetitions'], 12);
      expect((watchUpdates.last['exercise'] as Map)['weight'], 34);
      final count = watchUpdates.length;
      await tester.pump();
      expect(watchUpdates, hasLength(count));
    });

    testWidgets('handles null reps/weight without crashing', (tester) async {
      final notifier = container.read(gymStateProvider.notifier);
      final routine = testdata.getTestRoutine();
      routine.dayDataGym = [
        DayData(
          iteration: 1,
          date: DateTime(2024, 11, 01),
          label: '',
          day: routine.dayDataGym.first.day,
          slots: [
            SlotData(
              isSuperset: false,
              exerciseIds: [testExercises[0].id],
              setConfigs: [
                SetConfigData(
                  exerciseId: testExercises[0].id,
                  exercise: testExercises[0],
                  slotEntryId: 1,
                  nrOfSets: 1,
                  repetitions: null,
                  repetitionsUnit: null,
                  weight: null,
                  weightUnit: null,
                  restTime: 120,
                  rir: 1.5,
                  rpe: 8,
                  textRepr: '3x100kg',
                ),
              ],
            ),
          ],
        ),
      ];
      notifier.initData(routine, routine.days.first.id!, 1);
      notifier.setCurrentPage(2);

      expect(notifier.state.getSlotEntryPageByIndex()!.type, SlotPageType.log);
      await pumpLogPage(tester);
      expect(find.byType(LogPage), findsOneWidget);
    });

    testWidgets('renders without crashing for the default slot entry page', (tester) async {
      seedLogPage(testdata.getTestRoutine());
      await pumpLogPage(tester);

      expect(find.byType(LogPage), findsOneWidget);
    });

    testWidgets('copy from past log updates form fields and shows a SnackBar', (tester) async {
      seedLogPage(testdata.getTestRoutine());
      await pumpLogPage(tester);

      final pastLogTile = find.byWidgetPredicate(
        (w) => w.key is ValueKey && '${(w.key as ValueKey).value}'.startsWith('past-log-'),
      );
      expect(pastLogTile, findsWidgets);
      await tester.tap(pastLogTile.first);
      await tester.pumpAndSettle();

      final editableFields = find.byType(EditableText);
      expect(editableFields, findsWidgets);
      final repText = tester.widget<EditableText>(editableFields.at(0)).controller.text;
      final weightText = tester.widget<EditableText>(editableFields.at(1)).controller.text;
      // `contains` would also pass on the prefilled weight of 100
      expect(repText, '10');
      expect(weightText, '10');
      expect(find.byType(SnackBar), findsOneWidget);
    });

    testWidgets('shows an error indicator when past logs fail to load', (tester) async {
      // Error via a stream event (not a build throw), so riverpod surfaces it
      // as state instead of scheduling a retry timer.
      final controller = StreamController<List<Log>>();
      addTearDown(controller.close);
      when(
        mockWorkoutLogRepo.watchLogsByExerciseDrift(
          routineId: anyNamed('routineId'),
          exerciseId: anyNamed('exerciseId'),
        ),
      ).thenAnswer((_) => controller.stream);

      seedLogPage(testdata.getTestRoutine());
      await pumpLogPage(tester);

      controller.addError(Exception('boom'));
      await tester.pumpAndSettle();

      expect(find.byType(StreamErrorIndicator), findsOneWidget);
    });

    testWidgets('save button persists the entered reps/weight with slot/routine/iteration', (
      tester,
    ) async {
      seedLogPage(testdata.getTestRoutine());
      await pumpLogPage(tester);

      // Overwrite the pre-filled values so the assertion proves the user's
      // edits flow through, not just the set-config defaults.
      final fields = find.byType(TextFormField);
      await tester.enterText(fields.at(0), '12'); // reps
      await tester.enterText(fields.at(1), '34'); // weight
      await tester.pump();

      await tester.tap(find.byKey(const ValueKey('save-log-button')));
      await tester.pumpAndSettle();

      final gymState = container.read(gymStateProvider);
      final captured = verify(
        mockWorkoutLogRepo.addLocalDrift(captureAny, dayId: captureAnyNamed('dayId')),
      ).captured;
      final saved = captured[0] as Log;
      expect(saved.repetitions, 12);
      expect(saved.weight, 34);
      expect(saved.slotEntryId, gymState.getSlotEntryPageByIndex()!.setConfigData!.slotEntryId);
      expect(saved.routineId, gymState.routine.id);
      expect(saved.iteration, gymState.iteration);
      // The lazy session needs the day, otherwise days that need logs to
      // advance can't see it (issue wger#2460)
      expect(captured[1], gymState.dayId);
    });

    testWidgets('reps quick buttons increment and decrement the value', (tester) async {
      final routine = testdata.getTestRoutine();
      routine.dayDataGym[0].slots[0].setConfigs[0].repetitions = 0;
      seedLogPage(routine);
      await pumpLogPage(tester);

      final repsWidget = find.byKey(const ValueKey('logs-reps-widget'));
      expect(repsWidget, findsOneWidget);
      final addBtn = find.descendant(of: repsWidget, matching: find.byIcon(Icons.add));
      final removeBtn = find.descendant(of: repsWidget, matching: find.byIcon(Icons.remove));

      await tester.tap(addBtn);
      await tester.pumpAndSettle();
      expect(find.descendant(of: repsWidget, matching: find.text('1')), findsOneWidget);

      await tester.tap(addBtn);
      await tester.pumpAndSettle();
      expect(find.descendant(of: repsWidget, matching: find.text('2')), findsOneWidget);

      await tester.tap(removeBtn);
      await tester.pumpAndSettle();
      expect(find.descendant(of: repsWidget, matching: find.text('1')), findsOneWidget);
    });

    testWidgets('weight quick buttons increment and decrement the value', (tester) async {
      final routine = testdata.getTestRoutine();
      routine.dayDataGym[0].slots[0].setConfigs[0].weight = 0;
      seedLogPage(routine);
      await pumpLogPage(tester);

      final weightWidget = find.byKey(const ValueKey('logs-weight-widget'));
      expect(weightWidget, findsOneWidget);
      final addBtn = find.descendant(of: weightWidget, matching: find.byIcon(Icons.add));
      final removeBtn = find.descendant(of: weightWidget, matching: find.byIcon(Icons.remove));

      await tester.tap(addBtn);
      await tester.pumpAndSettle();
      expect(find.descendant(of: weightWidget, matching: find.text('1.25')), findsOneWidget);

      await tester.tap(addBtn);
      await tester.pumpAndSettle();
      expect(find.descendant(of: weightWidget, matching: find.text('2.5')), findsOneWidget);

      await tester.tap(removeBtn);
      await tester.pumpAndSettle();
      expect(find.descendant(of: weightWidget, matching: find.text('1.25')), findsOneWidget);
    });
  });

  group('HTTP(S) comments', () {
    List<TextSpan> links(WidgetTester tester) {
      final text = tester.widget<Text>(
        find.descendant(
          of: find.byType(LinkifiedComment),
          matching: find.byType(Text),
        ),
      );
      return (text.textSpan as TextSpan?)?.children
              ?.whereType<TextSpan>()
              .where((span) => span.recognizer != null)
              .toList() ??
          [];
    }

    Future<void> pumpComment(
      WidgetTester tester,
      String text,
      Future<bool> Function(Uri, {LaunchMode mode}) launch,
    ) => tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: LinkifiedComment(text, launch: launch),
        ),
      ),
    );

    testWidgets('only valid HTTP(S) links launch externally and retain punctuation', (
      tester,
    ) async {
      final launched = <Uri>[];
      final modes = <LaunchMode>[];
      const comment =
          'See (https://example.com/path?q=1). http://example.org '
          'ftp://example.com mailto:a@example.com https:// https:///path '
          'javascript:https://example.net https://bad%20host https://example.com:99999';
      await pumpComment(tester, comment, (uri, {mode = LaunchMode.platformDefault}) async {
        launched.add(uri);
        modes.add(mode);
        return true;
      });
      final spans = links(tester);
      expect(spans, hasLength(2));
      expect(spans.first.text, 'https://example.com/path?q=1');
      for (final span in spans) {
        (span.recognizer as TapGestureRecognizer).onTap!();
        await tester.pump();
      }
      expect(launched.map((uri) => uri.scheme), ['https', 'http']);
      expect(modes, everyElement(LaunchMode.externalApplication));
      expect(tester.widget<Text>(find.byType(Text)).textSpan!.toPlainText(), comment);
    });

    for (final throws in [false, true]) {
      testWidgets('failed launch (${throws ? 'exception' : 'false'}) leaves readable plain text', (
        tester,
      ) async {
        const comment = 'Read https://example.com/help.';
        await pumpComment(tester, comment, (uri, {mode = LaunchMode.platformDefault}) async {
          if (throws) {
            throw StateError('unavailable');
          }
          return false;
        });
        (links(tester).single.recognizer as TapGestureRecognizer).onTap!();
        await tester.pumpAndSettle();
        expect(links(tester), isEmpty);
        expect(tester.widget<Text>(find.byType(Text)).textSpan!.toPlainText(), comment);
        expect(tester.takeException(), isNull);
      });
    }

    testWidgets('non-link comments stay ordinary readable text', (tester) async {
      const comment = 'No link: ftp://example.com https://';
      await pumpComment(tester, comment, (uri, {mode = LaunchMode.platformDefault}) async {
        fail('Non-HTTP(S) text must not launch');
      });
      expect(find.text(comment), findsOneWidget);
      expect(links(tester), isEmpty);
    });
  });
}
