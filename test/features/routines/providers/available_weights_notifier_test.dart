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
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';
import 'package:wger/core/shared_preferences.dart';
import 'package:wger/features/routines/providers/available_weights_notifier.dart';

void main() {
  setUp(() {
    SharedPreferencesAsyncPlatform.instance = InMemorySharedPreferencesAsync.empty();
  });

  test('stores the weights sorted and without duplicates and reads them back', () async {
    final container = ProviderContainer.test();
    await container.read(availableWeightsProvider.future);

    await container.read(availableWeightsProvider.notifier).setWeights(7, [
      3.75,
      1.25,
      1.875,
      3.75,
      0,
    ]);
    expect(container.read(availableWeightsProvider).value, {
      7: [1.25, 1.875, 3.75],
    });

    // A fresh container reads what the first one stored
    final reloaded = ProviderContainer.test();
    expect(await reloaded.read(availableWeightsProvider.future), {
      7: [1.25, 1.875, 3.75],
    });
  });

  test('an empty list removes the weights of the exercise', () async {
    final container = ProviderContainer.test();
    final notifier = container.read(availableWeightsProvider.notifier);
    await notifier.setWeights(7, [20, 22.5]);
    await notifier.setWeights(8, [5]);

    await notifier.setWeights(7, []);

    expect(container.read(availableWeightsProvider).value, {
      8: [5],
    });
    expect(await ProviderContainer.test().read(availableWeightsProvider.future), {
      8: [5],
    });
  });

  test('unreadable stored data starts over empty', () async {
    await PreferenceHelper.asyncPref.setString(PREFS_AVAILABLE_WEIGHTS, 'not json');

    expect(await ProviderContainer.test().read(availableWeightsProvider.future), isEmpty);
  });
}
