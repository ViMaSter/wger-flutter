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
import 'package:wger/core/exceptions/http_exception.dart';
import 'package:wger/core/network/base_provider.dart';
import 'package:wger/core/network/wger_base.dart';
import 'package:wger/features/routines/models/weight_profile.dart';

/// Keeps the [WeightProfilesState] on the server, so it survives a reinstall.
///
/// wger itself has no place for it: the endpoint is served next to it by the
/// fitness-by-vincent deployment. Other servers answer 404, which counts as
/// "not supported" and is not an error.
class WeightProfilesRepository {
  final WgerBaseProvider _base;

  const WeightProfilesRepository(this._base);

  Uri get _uri {
    final server = Uri.parse(_base.serverUrl!);
    final prefix = server.path.endsWith('/')
        ? server.path.substring(0, server.path.length - 1)
        : server.path;
    return server.replace(path: '$prefix/app/v1/equipment');
  }

  /// Whether there is a server to talk to, i.e. someone is logged in
  bool get available => _base.serverUrl != null;

  /// What the server has, a null `state` if nothing yet. Null without the
  /// endpoint on this server.
  Future<({DateTime? updatedAt, WeightProfilesState? state})?> fetch() async {
    final Map<String, dynamic> body;
    try {
      body = await _base.fetch(_uri) as Map<String, dynamic>;
    } on WgerHttpException catch (e) {
      if (e.statusCode == 404) {
        return null;
      }
      rethrow;
    }
    final updatedAt = body['updatedAt'] as String?;
    final data = body['data'] as Map<String, dynamic>?;
    if (updatedAt == null || data == null) {
      return (updatedAt: null, state: null);
    }
    return (updatedAt: DateTime.parse(updatedAt), state: WeightProfilesState.fromJson(data));
  }

  /// Replaces what the server has with [state], returns when it stored it
  Future<DateTime> push(WeightProfilesState state) async {
    final body = await _base.put({'data': state.toJson()}, _uri);
    return DateTime.parse(body['updatedAt'] as String);
  }
}

final weightProfilesRepositoryProvider = Provider<WeightProfilesRepository>(
  (ref) => WeightProfilesRepository(ref.watch(wgerBaseProvider)),
);
