import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:wger/core/network/wger_base.dart';
import 'package:wger/core/widgets/core.dart';
import 'package:wger/features/routines/models/day.dart';
import 'package:wger/features/routines/models/day_data.dart';
import 'package:wger/features/routines/models/set_config_data.dart';
import 'package:wger/features/routines/models/slot_data.dart';
import 'package:wger/features/routines/widgets/day.dart';
import 'package:wger/l10n/generated/app_localizations.dart';
import 'package:wger/l10n/localizations_delegates.dart';

import '../../../../test_data/exercises.dart';

void main() {
  DayData dayData(String description, {List<SlotData> slots = const []}) => DayData(
    iteration: 1,
    date: DateTime(2024, 1, 1),
    day: Day(id: 1, routineId: 1, name: 'Training', description: description),
    slots: slots,
  );

  Future<void> pumpDay(WidgetTester tester, DayData day) => tester.pumpWidget(
    MaterialApp(
      locale: const Locale('en'),
      localizationsDelegates: appLocalizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: ProviderScope(
        overrides: [mediaUrlBuilderProvider.overrideWithValue((_) => null)],
        child: Scaffold(body: RoutineDayWidget(day, 1, true)),
      ),
    ),
  );

  testWidgets('empty and whitespace descriptions have no subtitle or extra height', (tester) async {
    await pumpDay(tester, dayData(''));
    final emptyHeight = tester.getSize(find.byType(DayHeader)).height;
    expect(tester.widget<ListTile>(find.byType(ListTile)).subtitle, isNull);
    await pumpDay(tester, dayData(' \n\t '));
    expect(tester.widget<ListTile>(find.byType(ListTile)).subtitle, isNull);
    expect(tester.getSize(find.byType(DayHeader)).height, emptyHeight);
    await pumpDay(tester, dayData('Keep this description'));
    expect(find.text('Keep this description'), findsOneWidget);
    expect(tester.widget<ListTile>(find.byType(ListTile)).subtitle, isNotNull);
  });

  testWidgets('groups differing sets by exercise and places slot comment after all rows', (
    tester,
  ) async {
    final exercises = getTestExercises();
    final slot = SlotData(
      isSuperset: true,
      comment: 'After the superset',
      exerciseIds: [exercises[0].id, exercises[1].id],
      setConfigs: [
        SetConfigData(
          exerciseId: exercises[0].id,
          exercise: exercises[0],
          slotEntryId: 1,
          textRepr: '10 reps',
        ),
        SetConfigData(
          exerciseId: exercises[1].id,
          exercise: exercises[1],
          slotEntryId: 2,
          textRepr: '8 reps',
        ),
        SetConfigData(
          exerciseId: exercises[0].id,
          exercise: exercises[0],
          slotEntryId: 1,
          textRepr: '6 reps',
        ),
      ],
    );
    await pumpDay(tester, dayData('', slots: [slot]));
    expect(find.byType(SetConfigDataWidget), findsNWidgets(2));
    final firstRow = find.byType(SetConfigDataWidget).first;
    expect(find.descendant(of: firstRow, matching: find.text('10 reps')), findsOneWidget);
    expect(find.descendant(of: firstRow, matching: find.text('6 reps')), findsOneWidget);
    expect(
      tester.getTopLeft(find.text('After the superset')).dy,
      greaterThanOrEqualTo(tester.getBottomLeft(find.byType(SetConfigDataWidget).last).dy),
    );
    expect(find.byType(MutedText), findsOneWidget);
  });
}
