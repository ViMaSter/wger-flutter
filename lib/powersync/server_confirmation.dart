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

import 'package:clock/clock.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:powersync/powersync.dart';
import 'package:wger/database/powersync/powersync.dart';

/// The part of PowerSync's `SyncStatus` that [waitForServerConfirmation]
/// needs, as plain values
typedef SyncSnapshot = ({
  bool connected,
  bool uploading,
  bool downloading,
  DateTime? lastSyncedAt,
});

SyncSnapshot snapshotOf(SyncStatus status) => (
  connected: status.connected,
  uploading: status.uploading,
  downloading: status.downloading,
  lastSyncedAt: status.lastSyncedAt,
);

/// Waits until the server has confirmed the local data, true once it has.
///
/// Confirmed means connected, synced, nothing left to upload and, when uploads
/// were pending meanwhile, a sync completed after they went out. A write the
/// server refused is then gone from the local data again, so a row that is
/// still there is on the server. False after [timeout], e.g. while offline.
///
/// [statuses] are checked as they come and, since the upload queue can change
/// without a new status, the [currentStatus] every [pollInterval].
Future<bool> waitForServerConfirmation({
  required Stream<SyncSnapshot> statuses,
  required SyncSnapshot Function() currentStatus,
  required Future<int> Function() pendingUploads,
  Duration timeout = const Duration(minutes: 5),
  Duration pollInterval = const Duration(seconds: 5),
}) async {
  final deadline = clock.now().add(timeout);
  final result = Completer<bool>();

  // When uploads were last seen pending, the confirming sync has to be newer
  DateTime? pendingSeenAt;

  Future<void> check(SyncSnapshot status) async {
    // Synced at least once, else there is nothing the server confirmed yet
    if (result.isCompleted || !status.connected || status.lastSyncedAt == null) {
      return;
    }
    final pending = await pendingUploads();
    if (pending > 0 || status.uploading) {
      pendingSeenAt = clock.now();
      return;
    }
    if (status.downloading) {
      return;
    }
    final lastSyncedAt = status.lastSyncedAt;
    final confirmed =
        pendingSeenAt == null || (lastSyncedAt != null && lastSyncedAt.isAfter(pendingSeenAt!));
    if (confirmed && !result.isCompleted) {
      result.complete(true);
    }
  }

  final subscription = statuses.listen(check);
  final ticker = Timer.periodic(pollInterval, (_) {
    if (clock.now().isAfter(deadline)) {
      if (!result.isCompleted) {
        result.complete(false);
      }
      return;
    }
    check(currentStatus());
  });
  unawaited(check(currentStatus()));

  try {
    return await result.future;
  } finally {
    ticker.cancel();
    await subscription.cancel();
  }
}

/// [waitForServerConfirmation] for the app's PowerSync database
final serverConfirmationProvider = Provider<Future<bool> Function()>((ref) {
  return () async {
    final db = await ref.read(powerSyncInstanceProvider.future);
    return waitForServerConfirmation(
      statuses: db.statusStream.map(snapshotOf),
      currentStatus: () => snapshotOf(db.currentStatus),
      pendingUploads: () async => (await db.getUploadQueueStats()).count,
    );
  };
});
