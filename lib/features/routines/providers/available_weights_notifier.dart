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

part 'available_weights_notifier.g.dart';

const PREFS_AVAILABLE_WEIGHTS = 'availableWeightsPrefs';

/// The weights the equipment of an exercise offers, by exercise ID, e.g. the
/// steps of a cable tower. Used for the progressive overload suggestions.
///
/// Stored on this device only, sorted and without duplicates.
@Riverpod(keepAlive: true)
class AvailableWeightsNotifier extends _$AvailableWeightsNotifier {
  final _logger = Logger('AvailableWeightsNotifier');

  @override
  Future<Map<int, List<num>>> build() async {
    final stored = await PreferenceHelper.asyncPref.getString(PREFS_AVAILABLE_WEIGHTS);
    if (stored == null) {
      return {};
    }

    try {
      final decoded = json.decode(stored) as Map<String, dynamic>;
      return {
        for (final MapEntry(:key, :value) in decoded.entries)
          int.parse(key): (value as List).cast<num>(),
      };
    } catch (e) {
      _logger.warning('Discarding unreadable available weights: $e');
      return {};
    }
  }

  /// Replaces the weights of [exerciseId], an empty list removes them
  Future<void> setWeights(int exerciseId, Iterable<num> weights) async {
    final current = await future;
    final cleaned = weights.where((w) => w > 0).toSet().toList()..sort();

    final updated = {...current};
    if (cleaned.isEmpty) {
      updated.remove(exerciseId);
    } else {
      updated[exerciseId] = cleaned;
    }

    state = AsyncData(updated);
    await PreferenceHelper.asyncPref.setString(
      PREFS_AVAILABLE_WEIGHTS,
      json.encode({for (final e in updated.entries) e.key.toString(): e.value}),
    );
  }
}
