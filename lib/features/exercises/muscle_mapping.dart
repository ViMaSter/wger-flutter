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

import 'package:wger/features/exercises/models/exercise.dart';

/// More primary muscles than this and an exercise trains "everything", e.g.
/// the rowing machine, and says nothing about a single muscle group
const maxOverloadMuscles = 4;

/// The category of whole-body conditioning exercises, skipped like those with
/// too many muscles
const cardioCategoryName = 'Cardio';

/// Primary muscles for exercises whose wger tags are missing or wrong, keyed
/// by exercise UUID, with wger's English muscle names.
///
/// Mirrors `muscleOverrides` in reports-by-vincent
/// (`jobs/workers/muscle_overrides.go`), keep both in sync so the app and the
/// calendar score the same muscle groups. `replace` entries win over wger's
/// tags, the others only fill in while wger lists none.
const muscleOverrides = <String, ({List<String> primary, bool replace})>{
  // Pec deck rear delt fly: posterior deltoid
  'e797ca42-f9fc-480a-8f48-7f6905978c72': (primary: ['Shoulders'], replace: false),
  // Rear Delt Raises
  '3f93459a-d06e-465c-85db-2137da759440': (primary: ['Shoulders'], replace: false),
  // Deficit Deadlift
  'e7a964cd-e68e-4926-bc7c-577065137e18': (
    primary: ['Glutes', 'Hamstrings', 'Lower back', 'Quads'],
    replace: false,
  ),
  // Extreme Pec Stretch
  '3c33c9fd-20cc-4dff-ac88-c992bb9b2e33': (primary: ['Chest'], replace: false),
  // Extreme Lat Stretch
  'ab808c2c-2e84-42bb-a65d-287a06ca7aa2': (primary: ['Lats'], replace: false),
  // Overhead Triceps Extension: wger tags it Trapezius only
  'c5797bdf-1aa1-4d51-9775-c929ec5a2aaf': (primary: ['Triceps'], replace: true),
};

/// The muscle groups an exercise counts towards for overload per muscle
/// group: its primary muscles (wger's English names), the category without
/// any, never the secondary ones.
///
/// Empty for exercises that train everything at once, cardio and those with
/// more than [maxOverloadMuscles] primary muscles: they are left out.
List<String> overloadMuscles(Exercise exercise) {
  final override = muscleOverrides[exercise.uuid];
  if (override != null && (override.replace || exercise.muscles.isEmpty)) {
    return override.primary;
  }
  if (exercise.category.name == cardioCategoryName ||
      exercise.muscles.length > maxOverloadMuscles) {
    return const [];
  }

  final names = {for (final muscle in exercise.muscles) _nameOf(muscle.nameEn, muscle.name)};
  if (names.isNotEmpty) {
    return names.toList();
  }
  return [_nameOf(exercise.category.name, 'Other')];
}

/// [preferred], [fallback] when it is empty
String _nameOf(String preferred, String fallback) => preferred.isNotEmpty ? preferred : fallback;
