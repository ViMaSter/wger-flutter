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

import 'dart:convert';

import 'package:logging/logging.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:wger/core/shared_preferences.dart';
import 'package:wger/features/routines/models/weight_profile.dart';
import 'package:wger/features/routines/providers/available_weights_notifier.dart';

part 'weight_profiles_notifier.g.dart';

const PREFS_WEIGHT_PROFILES = 'weightProfilesPrefs';

/// The [WeightProfile]s of the user's equipment and which exercise uses
/// which. Used for the progressive overload suggestions.
///
/// Stored on this device only. Without stored profiles yet, the weights of
/// the older per-exercise list ([PREFS_AVAILABLE_WEIGHTS]) become one fixed
/// profile per exercise, that key itself stays as it is.
@Riverpod(keepAlive: true)
class WeightProfilesNotifier extends _$WeightProfilesNotifier {
  final _logger = Logger('WeightProfilesNotifier');

  @override
  Future<WeightProfilesState> build() async {
    final stored = await PreferenceHelper.asyncPref.getString(PREFS_WEIGHT_PROFILES);
    if (stored == null) {
      return _migrateAvailableWeights();
    }

    try {
      return WeightProfilesState.fromJson(json.decode(stored) as Map<String, dynamic>);
    } catch (e) {
      _logger.warning('Discarding unreadable weight profiles: $e');
      return const WeightProfilesState();
    }
  }

  /// Adds [profile], or replaces the one with its ID
  Future<void> upsertProfile(WeightProfile profile) async {
    final current = await future;
    final index = current.profiles.indexWhere((p) => p.id == profile.id);
    final profiles = [...current.profiles];
    if (index == -1) {
      profiles.add(profile);
    } else {
      profiles[index] = profile;
    }
    await _save(current.copyWith(profiles: profiles));
  }

  /// Removes the profile with [profileId] and its assignments
  Future<void> deleteProfile(String profileId) async {
    final current = await future;
    await _save(
      current.copyWith(
        profiles: current.profiles.where((p) => p.id != profileId).toList(),
        assignments: {
          for (final e in current.assignments.entries)
            if (e.value != profileId) e.key: e.value,
        },
      ),
    );
  }

  /// Lets [exerciseId] use the profile with [profileId], null for none
  Future<void> assign(int exerciseId, String? profileId) async {
    final current = await future;
    final assignments = {...current.assignments};
    if (profileId == null) {
      assignments.remove(exerciseId);
    } else {
      assignments[exerciseId] = profileId;
    }
    await _save(current.copyWith(assignments: assignments));
  }

  /// The profile assigned to [exerciseId], null without one
  Future<WeightProfile?> profileFor(int exerciseId) async => (await future).profileFor(exerciseId);

  Future<void> _save(WeightProfilesState updated) async {
    state = AsyncData(updated);
    await PreferenceHelper.asyncPref.setString(
      PREFS_WEIGHT_PROFILES,
      json.encode(updated.toJson()),
    );
  }

  /// One fixed profile per exercise of the older per-exercise weights, stored
  /// right away so it happens once
  Future<WeightProfilesState> _migrateAvailableWeights() async {
    final legacy = await PreferenceHelper.asyncPref.getString(PREFS_AVAILABLE_WEIGHTS);
    if (legacy == null) {
      return const WeightProfilesState();
    }

    final Map<int, List<num>> weights;
    try {
      final decoded = json.decode(legacy) as Map<String, dynamic>;
      weights = {
        for (final MapEntry(:key, :value) in decoded.entries)
          int.parse(key): (value as List).cast<num>(),
      };
    } catch (e) {
      _logger.warning('Not migrating unreadable available weights: $e');
      return const WeightProfilesState();
    }

    final migrated = WeightProfilesState(
      profiles: [
        for (final MapEntry(key: exerciseId, value: fixed) in weights.entries)
          WeightProfile(
            id: 'exercise-$exerciseId',
            name: 'Exercise $exerciseId',
            kind: WeightProfileKind.fixed,
            fixed: fixed,
          ),
      ],
      assignments: {for (final exerciseId in weights.keys) exerciseId: 'exercise-$exerciseId'},
    );
    _logger.info('Migrated the available weights of ${weights.length} exercises to profiles');
    await PreferenceHelper.asyncPref.setString(
      PREFS_WEIGHT_PROFILES,
      json.encode(migrated.toJson()),
    );
    return migrated;
  }
}
