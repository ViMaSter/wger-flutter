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
import 'package:wger/features/exercises/models/category.dart';
import 'package:wger/features/exercises/models/exercise.dart';
import 'package:wger/features/exercises/models/muscle.dart';
import 'package:wger/features/exercises/muscle_mapping.dart';

const _arms = ExerciseCategory(id: 1, name: 'Arms');
const _cardio = ExerciseCategory(id: 2, name: cardioCategoryName);

Muscle _muscle(int id, String nameEn) =>
    Muscle(id: id, name: 'Latin $id', nameEn: nameEn, isFront: true);

Exercise _exercise({
  String uuid = 'not-overridden',
  ExerciseCategory category = _arms,
  List<Muscle> muscles = const [],
}) => Exercise(id: 1, uuid: uuid, category: category, muscles: muscles);

void main() {
  test('takes the English names of the primary muscles, never the secondary ones', () {
    final exercise = Exercise(
      id: 1,
      uuid: 'x',
      category: _arms,
      muscles: [_muscle(1, 'Biceps'), _muscle(2, 'Biceps'), _muscle(3, '')],
      musclesSecondary: [_muscle(4, 'Brachialis')],
    );

    expect(overloadMuscles(exercise), ['Biceps', 'Latin 3']);
  });

  test('falls back to the category without primary muscles', () {
    expect(overloadMuscles(_exercise()), ['Arms']);
  });

  test('replaces wrong wger tags with a replacing override', () {
    final overheadTricepsExtension = _exercise(
      uuid: 'c5797bdf-1aa1-4d51-9775-c929ec5a2aaf',
      muscles: [_muscle(1, 'Trapezius')],
    );

    expect(overloadMuscles(overheadTricepsExtension), ['Triceps']);
  });

  test('keeps wger tags over a filling override once wger has some', () {
    const pecDeckRearDeltFly = 'e797ca42-f9fc-480a-8f48-7f6905978c72';

    expect(overloadMuscles(_exercise(uuid: pecDeckRearDeltFly)), ['Shoulders']);
    expect(
      overloadMuscles(_exercise(uuid: pecDeckRearDeltFly, muscles: [_muscle(1, 'Trapezius')])),
      ['Trapezius'],
    );
  });

  test('leaves out cardio and exercises training more than four muscle groups', () {
    final rowingMachine = _exercise(
      category: _cardio,
      muscles: [_muscle(1, 'Lats'), _muscle(2, 'Quads')],
    );
    final everything = _exercise(
      muscles: [for (var i = 0; i < 5; i++) _muscle(i, 'Muscle $i')],
    );
    final four = _exercise(muscles: [for (var i = 0; i < 4; i++) _muscle(i, 'Muscle $i')]);

    expect(overloadMuscles(rowingMachine), isEmpty);
    expect(overloadMuscles(everything), isEmpty);
    expect(overloadMuscles(four), hasLength(4));
  });
}
