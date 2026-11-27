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

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:wger/core/exceptions/http_exception.dart';
import 'package:wger/core/network/base_provider.dart';
import 'package:wger/features/routines/models/weight_profile.dart';
import 'package:wger/features/routines/providers/weight_profiles_repository.dart';

void main() {
  const rack = WeightProfile(
    id: 'rack',
    name: 'Dumbbells',
    kind: WeightProfileKind.fixed,
    fixed: [20, 30],
    pair: true,
  );
  const state = WeightProfilesState(profiles: [rack], assignments: {7: 'rack'});

  final requests = <http.Request>[];

  WeightProfilesRepository repositoryAnswering(int status, Object body, {String? server}) {
    requests.clear();
    return WeightProfilesRepository(
      WgerBaseProvider(
        serverUrl: server ?? 'https://fitness.example',
        client: MockClient((request) async {
          requests.add(request);
          return http.Response(json.encode(body), status);
        }),
      ),
    );
  }

  test('sends the whole state under data, to the endpoint next to wger', () async {
    final repository = repositoryAnswering(200, {
      'updatedAt': '2026-11-26T03:00:00.000Z',
      'data': state.toJson(),
    });

    final storedAt = await repository.push(state);

    expect(storedAt.isAtSameMomentAs(DateTime.utc(2026, 11, 26, 3)), isTrue);
    final request = requests.single;
    expect(request.method, 'PUT');
    expect(request.url.toString(), 'https://fitness.example/app/v1/equipment');
    final data = (json.decode(request.body) as Map<String, dynamic>)['data'];
    expect(data['assignments'], {'7': 'rack'});
    expect(data['profiles'].single['pair'], isTrue);
    expect(data['profiles'].single['fixed'], [20, 30]);
  });

  test('reads back what it sent', () async {
    final sent = json.decode(json.encode(state.toJson()));
    final repository = repositoryAnswering(200, {
      'updatedAt': '2026-11-26T03:00:00.000Z',
      'data': sent,
    });

    final stored = (await repository.fetch())!;

    expect(stored.state, state);
    expect(stored.updatedAt!.isAtSameMomentAs(DateTime.utc(2026, 11, 26, 3)), isTrue);
  });

  test('nothing stored yet', () async {
    final repository = repositoryAnswering(200, {'updatedAt': null, 'data': null});

    final stored = (await repository.fetch())!;

    expect(stored.state, isNull);
    expect(stored.updatedAt, isNull);
  });

  test('a server without the endpoint is not supported, not an error', () async {
    expect(await repositoryAnswering(404, {'detail': 'Not found'}).fetch(), isNull);
  });

  test('other failures are reported', () async {
    expect(
      repositoryAnswering(403, {'code': 'token_not_valid'}).fetch(),
      throwsA(isA<WgerHttpException>()),
    );
  });

  test('keeps a path the server lives under', () async {
    final repository = repositoryAnswering(200, {
      'updatedAt': null,
      'data': null,
    }, server: 'https://example.org/wger/');

    await repository.fetch();

    expect(requests.single.url.toString(), 'https://example.org/wger/app/v1/equipment');
  });
}
