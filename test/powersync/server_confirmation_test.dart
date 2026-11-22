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

import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:wger/powersync/server_confirmation.dart';

void main() {
  late StreamController<SyncSnapshot> statuses;
  late SyncSnapshot current;
  late int pending;

  SyncSnapshot status({
    bool connected = true,
    bool uploading = false,
    bool downloading = false,
    DateTime? lastSyncedAt,
  }) => (
    connected: connected,
    uploading: uploading,
    downloading: downloading,
    lastSyncedAt: lastSyncedAt,
  );

  setUp(() {
    statuses = StreamController<SyncSnapshot>.broadcast();
    pending = 0;
    current = status(lastSyncedAt: DateTime.now());
  });

  tearDown(() => statuses.close());

  Future<bool> wait({Duration timeout = const Duration(seconds: 2)}) => waitForServerConfirmation(
    statuses: statuses.stream,
    currentStatus: () => current,
    pendingUploads: () async => pending,
    timeout: timeout,
    pollInterval: const Duration(milliseconds: 10),
  );

  test('confirms right away when synced with nothing to upload', () async {
    expect(await wait(), isTrue);
  });

  test('waits for the uploads and a sync after them', () async {
    pending = 2;
    current = status(
      uploading: true,
      lastSyncedAt: DateTime.now().subtract(const Duration(minutes: 1)),
    );
    var done = false;
    final result = wait().then((value) => done = value);

    await Future<void>.delayed(const Duration(milliseconds: 50));
    expect(done, isFalse);

    // Uploaded, but the sync that would remove a refused row is older
    pending = 0;
    current = status(lastSyncedAt: DateTime.now().subtract(const Duration(minutes: 1)));
    statuses.add(current);
    await Future<void>.delayed(const Duration(milliseconds: 50));
    expect(done, isFalse);

    current = status(lastSyncedAt: DateTime.now());
    statuses.add(current);
    await result;
    expect(done, isTrue);
  });

  test('does not confirm while downloading', () async {
    current = status(downloading: true, lastSyncedAt: DateTime.now());

    expect(await wait(timeout: const Duration(milliseconds: 100)), isFalse);
  });

  test('gives up while offline or never synced', () async {
    current = status(connected: false, lastSyncedAt: DateTime.now());
    expect(await wait(timeout: const Duration(milliseconds: 100)), isFalse);

    current = status();
    expect(await wait(timeout: const Duration(milliseconds: 100)), isFalse);
  });
}
