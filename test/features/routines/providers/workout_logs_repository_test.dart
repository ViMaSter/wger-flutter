/*
 * This file is part of wger Workout Manager <https://github.com/wger-project>.
 * Copyright (c) 2026 - 2026 wger Team
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
import 'package:wger/database/powersync/database.dart';
import 'package:wger/features/routines/models/log.dart';
import 'package:wger/features/routines/models/session.dart';
import 'package:wger/features/routines/providers/workout_logs_repository.dart';

import '../../../helpers/in_memory_drift.dart';

void main() {
  late DriftPowersyncDatabase db;
  late WorkoutLogRepository repo;

  setUp(() async {
    db = await openTestDatabase();
    repo = WorkoutLogRepository(db);
  });

  tearDown(() async {
    await db.close();
  });

  Log makeLog({
    int exerciseId = 1,
    int? routineId = 100,
    String? sessionId,
    DateTime? date,
    num weight = 50,
    num repetitions = 10,
  }) {
    return Log(
      exerciseId: exerciseId,
      routineId: routineId,
      sessionId: sessionId,
      weight: weight,
      repetitions: repetitions,
      date: date ?? DateTime.utc(2026, 4, 15, 10, 30),
    );
  }

  Future<List<dynamic>> readLogs() => db.select(db.workoutLogTable).get();
  Future<List<dynamic>> readSessions() => db.select(db.workoutSessionTable).get();

  Future<void> seedUnits() async {
    await db
        .into(db.routineRepetitionUnitTable)
        .insert(RoutineRepetitionUnitTableCompanion.insert(id: 1, name: 'Repetitions'));
    await db
        .into(db.routineWeightUnitTable)
        .insert(RoutineWeightUnitTableCompanion.insert(id: 1, name: 'kg'));
  }

  group('addLocalDrift, log already has a sessionId', () {
    test('inserts the log without touching the session table', () async {
      final log = makeLog(sessionId: 'existing-session');

      await repo.addLocalDrift(log);

      final logs = await readLogs();
      expect(logs, hasLength(1));
      expect(logs.first.sessionId, 'existing-session');
      expect(await readSessions(), isEmpty);
    });
  });

  group('addLocalDrift, log without sessionId', () {
    test('reuses an open session within the window', () async {
      final existingSession = WorkoutSession(
        id: 'existing-session-1',
        routineId: 100,
        datetimeStart: DateTime.utc(2026, 4, 15, 16),
      );
      await db.into(db.workoutSessionTable).insert(existingSession.toCompanion());

      final log = makeLog(date: DateTime.utc(2026, 4, 15, 18));
      await repo.addLocalDrift(log);

      expect(await readSessions(), hasLength(1));
      expect(log.sessionId, existingSession.id);
      final logs = await readLogs();
      expect(logs.single.sessionId, existingSession.id);
    });

    test('reuses a closed session the log falls into', () async {
      final existingSession = WorkoutSession(
        id: 'existing-session-1',
        routineId: 100,
        datetimeStart: DateTime.utc(2026, 4, 15, 16),
        datetimeEnd: DateTime.utc(2026, 4, 15, 19),
      );
      await db.into(db.workoutSessionTable).insert(existingSession.toCompanion());

      final log = makeLog(date: DateTime.utc(2026, 4, 15, 18));
      await repo.addLocalDrift(log);

      expect(await readSessions(), hasLength(1));
      expect(log.sessionId, existingSession.id);
    });

    test('reuses a session that runs past midnight for a log after it', () async {
      // The session it belongs to started the day before, so a lookup by day
      // would put this log in one of its own (issue wger#2379)
      final existingSession = WorkoutSession(
        id: 'existing-session-1',
        routineId: 100,
        datetimeStart: DateTime.utc(2026, 4, 15, 23, 30),
        datetimeEnd: DateTime.utc(2026, 4, 16, 1),
      );
      await db.into(db.workoutSessionTable).insert(existingSession.toCompanion());

      final log = makeLog(date: DateTime.utc(2026, 4, 16, 0, 30));
      await repo.addLocalDrift(log);

      expect(await readSessions(), hasLength(1));
      expect(log.sessionId, existingSession.id);
    });

    test('does not reuse a closed session the log falls outside of', () async {
      await db
          .into(db.workoutSessionTable)
          .insert(
            WorkoutSession(
              routineId: 100,
              datetimeStart: DateTime.utc(2026, 4, 15, 16),
              datetimeEnd: DateTime.utc(2026, 4, 15, 17),
            ).toCompanion(),
          );

      await repo.addLocalDrift(makeLog(date: DateTime.utc(2026, 4, 15, 18)));

      expect(await readSessions(), hasLength(2));
    });

    test('creates a new session starting at the moment of the log', () async {
      // Without a start the lookups above could never find it again and every
      // further log would create one of its own.
      final log = makeLog(date: DateTime.utc(2026, 4, 15, 18, 30));

      await repo.addLocalDrift(log);

      final sessions = await readSessions();
      expect(sessions, hasLength(1));
      expect(sessions.single.datetimeStart, DateTime.utc(2026, 4, 15, 18, 30).toLocal());
      expect(log.sessionId, sessions.single.id);
    });

    test('stamps the new session with the day it was logged on', () async {
      // A session without a day is invisible to days that need logs to
      // advance, stalling the routine's date sequence (issue wger#2460)
      final log = makeLog();

      await repo.addLocalDrift(log, dayId: 42);

      final sessions = await readSessions();
      expect(sessions.single.dayId, 42);
    });

    test('starts a new session when the open one is older than the window', () async {
      await db
          .into(db.workoutSessionTable)
          .insert(
            WorkoutSession(
              routineId: 100,
              datetimeStart: DateTime.utc(2026, 4, 15, 8),
            ).toCompanion(),
          );

      await repo.addLocalDrift(makeLog(routineId: 100, date: DateTime.utc(2026, 4, 15, 18)));

      expect(await readSessions(), hasLength(2));
    });

    test('does not reuse a session from a different day', () async {
      await db
          .into(db.workoutSessionTable)
          .insert(
            WorkoutSession(routineId: 100, datetimeStart: DateTime.utc(2026, 4, 14)).toCompanion(),
          );

      await repo.addLocalDrift(makeLog(date: DateTime.utc(2026, 4, 15)));

      expect(await readSessions(), hasLength(2));
    });

    test('does not reuse a session from a different routine', () async {
      await db
          .into(db.workoutSessionTable)
          .insert(
            WorkoutSession(routineId: 999, datetimeStart: DateTime.utc(2026, 4, 15)).toCompanion(),
          );

      await repo.addLocalDrift(makeLog(routineId: 100, date: DateTime.utc(2026, 4, 15)));

      expect(await readSessions(), hasLength(2));
    });

    test('creates a session without a routine for a log without a routine', () async {
      final log = makeLog(routineId: null, date: DateTime.utc(2026, 4, 15, 18));

      await repo.addLocalDrift(log);

      final sessions = await readSessions();
      expect(sessions, hasLength(1));
      expect(sessions.single.routineId, isNull);
      expect(log.sessionId, sessions.single.id);
    });

    test('reuses an existing session without a routine for a log without a routine', () async {
      final existingSession = WorkoutSession(
        id: 'free-session',
        routineId: null,
        datetimeStart: DateTime.utc(2026, 4, 15, 16),
      );
      await db.into(db.workoutSessionTable).insert(existingSession.toCompanion());

      final log = makeLog(routineId: null, date: DateTime.utc(2026, 4, 15, 18));
      await repo.addLocalDrift(log);

      expect(await readSessions(), hasLength(1));
      expect(log.sessionId, existingSession.id);
    });

    test('does not attach a log without a routine to a session with one', () async {
      await db
          .into(db.workoutSessionTable)
          .insert(
            WorkoutSession(routineId: 100, datetimeStart: DateTime.utc(2026, 4, 15)).toCompanion(),
          );

      await repo.addLocalDrift(makeLog(routineId: null, date: DateTime.utc(2026, 4, 15)));

      expect(await readSessions(), hasLength(2));
    });
  });

  group('getLatestLogByExercise', () {
    test('returns null when the exercise was never logged', () async {
      await db.into(db.workoutLogTable).insert(makeLog(exerciseId: 2).toCompanion());

      expect(await repo.getLatestLogByExercise(1), isNull);
    });

    test('returns the newest log of the exercise across routines', () async {
      await seedUnits();
      await db
          .into(db.workoutLogTable)
          .insert(makeLog(date: DateTime.utc(2026, 4, 14), weight: 14).toCompanion());
      await db
          .into(db.workoutLogTable)
          .insert(
            makeLog(routineId: 999, date: DateTime.utc(2026, 4, 16), weight: 16).toCompanion(),
          );
      await db
          .into(db.workoutLogTable)
          .insert(makeLog(date: DateTime.utc(2026, 4, 15), weight: 15).toCompanion());
      // Newer, but a different exercise
      await db
          .into(db.workoutLogTable)
          .insert(
            makeLog(exerciseId: 2, date: DateTime.utc(2026, 4, 17), weight: 17).toCompanion(),
          );

      final log = await repo.getLatestLogByExercise(1);

      expect(log!.weight, 16);
      expect(log.weightUnitObj?.name, 'kg');
    });
  });

  group('getLastSessionLogsByExercise', () {
    Future<void> insert(Log log) => db.into(db.workoutLogTable).insert(log.toCompanion());

    test('is empty when the exercise was not logged before', () async {
      await insert(makeLog(sessionId: 's1', date: DateTime.utc(2026, 4, 10)));

      expect(
        await repo.getLastSessionLogsByExercise(1, before: DateTime.utc(2026, 4, 10)),
        isEmpty,
      );
    });

    test('with a routine, the newest session of that routine, only its sets', () async {
      // The previous run of the routine: 2 × 12
      await insert(
        makeLog(sessionId: 'run1', routineId: 4, date: DateTime.utc(2026, 7, 16), weight: 35),
      );
      await insert(
        makeLog(sessionId: 'run1', routineId: 4, date: DateTime.utc(2026, 7, 16, 0, 5), weight: 35),
      );
      // Newer, in another routine; a set without a routine logged into the same session
      await insert(
        makeLog(sessionId: 'heavy', routineId: 2, date: DateTime.utc(2026, 11, 21), weight: 55),
      );
      await insert(
        makeLog(sessionId: 'run1', routineId: null, date: DateTime.utc(2026, 7, 16, 0, 9)),
      );

      final before = DateTime.utc(2026, 11, 30);
      final inRoutine = await repo.getLastSessionLogsByExercise(1, before: before, routineId: 4);
      final any = await repo.getLastSessionLogsByExercise(1, before: before);

      expect(inRoutine.map((l) => l.weight), [35, 35]);
      expect(any.map((l) => l.weight), [55]);
    });

    test('returns the sets of the newest session before, oldest first', () async {
      await seedUnits();
      // An older session
      await insert(makeLog(sessionId: 's1', date: DateTime.utc(2026, 4, 10, 10), weight: 10));
      // The last session, logged out of order, with another exercise in it
      await insert(makeLog(sessionId: 's2', date: DateTime.utc(2026, 4, 12, 10, 5), weight: 22));
      await insert(makeLog(sessionId: 's2', date: DateTime.utc(2026, 4, 12, 10), weight: 21));
      await insert(
        makeLog(exerciseId: 2, sessionId: 's2', date: DateTime.utc(2026, 4, 12, 10, 3)),
      );
      // The running workout: starts exactly at `before`, so it doesn't count
      await insert(makeLog(sessionId: 's3', date: DateTime.utc(2026, 4, 15, 10), weight: 30));

      final logs = await repo.getLastSessionLogsByExercise(
        1,
        before: DateTime.utc(2026, 4, 15, 10),
      );

      expect(logs.map((l) => l.weight), [21, 22]);
      expect(logs.first.weightUnitObj?.name, 'kg');
    });

    test('groups logs without a session by calendar day', () async {
      await insert(makeLog(date: DateTime(2026, 4, 11, 23, 30), weight: 11));
      await insert(makeLog(date: DateTime(2026, 4, 12, 0, 15), weight: 12));
      await insert(makeLog(date: DateTime(2026, 4, 12, 18), weight: 13));
      // Same day, but in a session: not the same workout
      await insert(makeLog(sessionId: 's1', date: DateTime(2026, 4, 12, 9), weight: 99));

      final logs = await repo.getLastSessionLogsByExercise(1, before: DateTime(2026, 4, 13));

      expect(logs.map((l) => l.weight), [12, 13]);
    });
  });

  group('resubmitMissing', () {
    test('writes the missing logs again with their IDs, leaves the others alone', () async {
      final session = WorkoutSession(
        id: 'session-1',
        routineId: 100,
        datetimeStart: DateTime.utc(2026, 4, 15, 16),
      );
      await db.into(db.workoutSessionTable).insert(session.toCompanion());
      final kept = makeLog(sessionId: 'session-1', weight: 50)..id = 'kept';
      await db.into(db.workoutLogTable).insert(kept.toCompanion());
      final lost = makeLog(sessionId: 'session-1', weight: 55, repetitions: 8)..id = 'lost';

      final resent = await repo.resubmitMissing([kept, lost]);

      expect(resent.map((l) => l.id), ['lost']);
      final rows = {for (final row in await readLogs()) row.id: row};
      expect(rows.keys, unorderedEquals(['kept', 'lost']));
      expect(rows['lost']!.weight, 55);
      expect(rows['lost']!.repetitions, 8);
      expect(rows['lost']!.sessionId, 'session-1');
      expect(await readSessions(), hasLength(1));
    });

    test('a lost session is replaced by one for the day', () async {
      final lost = makeLog(sessionId: 'gone-session', date: DateTime.utc(2026, 4, 15, 18))
        ..id = 'lost';

      await repo.resubmitMissing([lost]);

      final row = (await readLogs()).single;
      expect(row.id, 'lost');
      expect(row.sessionId, isNot('gone-session'));
      expect((await readSessions()).single.id, row.sessionId);
    });

    test('nothing to do without IDs', () async {
      expect(await repo.resubmitMissing([makeLog()]), isEmpty);
      expect(await readLogs(), isEmpty);
    });
  });

  group('updateLocalDrift', () {
    test('overwrites the row with matching id', () async {
      final log = makeLog(sessionId: 'session-1', weight: 50);
      await repo.addLocalDrift(log);

      log.weight = 75;
      await repo.updateLocalDrift(log);

      final rows = await readLogs();
      expect(rows, hasLength(1));
      expect(rows.single.weight, 75);
    });

    test('clears values that were nulled', () async {
      final log = makeLog(sessionId: 'session-1', weight: 50);
      log.rir = 2;
      await repo.addLocalDrift(log);

      // The user clears the RiR and the weight in the log edit dialog
      log.rir = null;
      log.weight = null;
      await repo.updateLocalDrift(log);

      final rows = await readLogs();
      expect(rows.single.rir, isNull);
      expect(rows.single.weight, isNull);
    });
  });

  group('deleteSessionIfEmpty', () {
    Future<String> createSession() async {
      final row = await db
          .into(db.workoutSessionTable)
          .insertReturning(
            WorkoutSession(routineId: 100, datetimeStart: DateTime.utc(2026, 4, 15)).toCompanion(),
          );
      return row.id!;
    }

    test('deletes a session without logs', () async {
      final sessionId = await createSession();
      final log = makeLog(sessionId: sessionId);
      await repo.addLocalDrift(log);
      await repo.deleteLocalDrift(log.id!);

      expect(await repo.deleteSessionIfEmpty(sessionId), isTrue);
      expect(await readSessions(), isEmpty);
    });

    test('keeps a session with logs left, also of another exercise', () async {
      final sessionId = await createSession();
      final other = await createSession();
      await repo.addLocalDrift(makeLog(sessionId: sessionId, exerciseId: 2));

      expect(await repo.deleteSessionIfEmpty(sessionId), isFalse);
      expect((await readSessions()).map((s) => s.id), unorderedEquals([sessionId, other]));
      expect(await readLogs(), hasLength(1));
    });
  });

  group('deleteLocalDrift', () {
    test('removes the row with matching id', () async {
      final log = makeLog(sessionId: 'session-1');
      await repo.addLocalDrift(log);

      await repo.deleteLocalDrift(log.id!);

      expect(await readLogs(), isEmpty);
    });

    test('on a non-existent id is a no-op', () async {
      final log = makeLog(sessionId: 'session-1');
      await repo.addLocalDrift(log);

      await repo.deleteLocalDrift('does-not-exist');

      expect(await readLogs(), hasLength(1));
    });
  });

  group('watchLogsByExerciseDrift', () {
    test('emits an empty list when nothing matches', () async {
      expect(await repo.watchLogsByExerciseDrift(routineId: 100, exerciseId: 1).first, isEmpty);
    });

    test('returns only logs for the given routine and exercise', () async {
      await seedUnits();
      await db
          .into(db.workoutLogTable)
          .insert(makeLog(exerciseId: 1, routineId: 100).toCompanion());
      // Different exercise, same routine.
      await db
          .into(db.workoutLogTable)
          .insert(makeLog(exerciseId: 2, routineId: 100).toCompanion());
      // Same exercise, different routine.
      await db
          .into(db.workoutLogTable)
          .insert(makeLog(exerciseId: 1, routineId: 999).toCompanion());

      final logs = await repo.watchLogsByExerciseDrift(routineId: 100, exerciseId: 1).first;

      expect(logs, hasLength(1));
      expect(logs.single.exerciseId, 1);
      expect(logs.single.routineId, 100);
    });

    test('sorts by date descending', () async {
      await seedUnits();
      // Tag each row with a distinct weight so the order can be asserted without
      // depending on the timezone the date converter reads back in.
      await db
          .into(db.workoutLogTable)
          .insert(makeLog(date: DateTime.utc(2026, 4, 14), weight: 14).toCompanion());
      await db
          .into(db.workoutLogTable)
          .insert(makeLog(date: DateTime.utc(2026, 4, 16), weight: 16).toCompanion());
      await db
          .into(db.workoutLogTable)
          .insert(makeLog(date: DateTime.utc(2026, 4, 15), weight: 15).toCompanion());

      final logs = await repo.watchLogsByExerciseDrift(routineId: 100, exerciseId: 1).first;

      expect(logs.map((l) => l.weight).toList(), [16, 15, 14]);
    });

    test('attaches the repetition and weight unit to each log', () async {
      await seedUnits();
      await db.into(db.workoutLogTable).insert(makeLog().toCompanion());

      final logs = await repo.watchLogsByExerciseDrift(routineId: 100, exerciseId: 1).first;

      expect(logs.single.repetitionsUnitObj?.name, 'Repetitions');
      expect(logs.single.weightUnitObj?.name, 'kg');
    });

    test('returns logs without a routine, e.g. free logging on the server', () async {
      // The server allows logs without a routine. Such a row arrives via
      // PowerSync with routine_id = NULL and must map cleanly
      await seedUnits();
      await db.customStatement(
        'INSERT INTO manager_workoutlog (id, exercise_id, routine_id, weight, date) '
        "VALUES ('free-log', 1, NULL, 50.0, '2026-04-15T10:30:00.000Z')",
      );

      final logs = await repo.watchLogsByExerciseDrift(exerciseId: 1).first;

      expect(logs, hasLength(1));
      expect(logs.single.routineId, isNull);
    });

    test('returns the logs of every routine when no routine is given', () async {
      await seedUnits();
      await db
          .into(db.workoutLogTable)
          .insert(makeLog(exerciseId: 1, routineId: 100).toCompanion());
      await db
          .into(db.workoutLogTable)
          .insert(makeLog(exerciseId: 1, routineId: 999).toCompanion());
      await db
          .into(db.workoutLogTable)
          .insert(makeLog(exerciseId: 2, routineId: 100).toCompanion());

      final logs = await repo.watchLogsByExerciseDrift(exerciseId: 1).first;

      expect(logs.map((l) => l.routineId).toSet(), {100, 999});
    });

    test('only returns logs on or after the given date', () async {
      await seedUnits();
      await db
          .into(db.workoutLogTable)
          .insert(makeLog(date: DateTime.utc(2026, 4, 14), weight: 14).toCompanion());
      await db
          .into(db.workoutLogTable)
          .insert(makeLog(date: DateTime.utc(2026, 4, 16), weight: 16).toCompanion());

      final logs = await repo
          .watchLogsByExerciseDrift(
            routineId: 100,
            exerciseId: 1,
            since: DateTime.utc(2026, 4, 15),
          )
          .first;

      expect(logs.map((l) => l.weight).toList(), [16]);
    });

    test('compares a cutoff given in local time as an instant', () async {
      // Dates are stored as UTC text, a local cutoff is bound with its offset
      // appended. Both sides go through JULIANDAY, so the comparison happens on
      // the instant rather than on the raw string.
      await seedUnits();
      await db
          .into(db.workoutLogTable)
          .insert(makeLog(date: DateTime.utc(2026, 4, 15, 9)).toCompanion());

      final justBefore = await repo
          .watchLogsByExerciseDrift(
            routineId: 100,
            exerciseId: 1,
            since: DateTime.utc(2026, 4, 15, 8, 30).toLocal(),
          )
          .first;
      expect(justBefore, hasLength(1), reason: 'Cutoff half an hour before the log');

      final justAfter = await repo
          .watchLogsByExerciseDrift(
            routineId: 100,
            exerciseId: 1,
            since: DateTime.utc(2026, 4, 15, 9, 30).toLocal(),
          )
          .first;
      expect(justAfter, isEmpty, reason: 'Cutoff half an hour after the log');
    });

    test('re-emits when a matching log is added', () async {
      await seedUnits();
      final stream = repo.watchLogsByExerciseDrift(routineId: 100, exerciseId: 1);
      final emissions = <List<Log>>[];
      final sub = stream.listen(emissions.add);

      await db.into(db.workoutLogTable).insert(makeLog().toCompanion());
      await pumpEventQueue();

      expect(emissions.last, hasLength(1));
      await sub.cancel();
    });
  });

  group('getLogsByIds', () {
    test('returns the logs with the given ids, with their units', () async {
      await seedUnits();
      final logs = [
        for (final weight in [10, 20, 30]) makeLog(weight: weight, sessionId: 's'),
      ];
      for (final log in logs) {
        await repo.addLocalDrift(log);
      }

      final found = await repo.getLogsByIds([logs[0].id!, logs[2].id!, 'does-not-exist']);

      expect(found.map((l) => l.weight), unorderedEquals([10, 30]));
      expect(found.map((l) => l.weightUnitObj?.name), everyElement('kg'));
    });
  });

  group('getDistinctWeightsByExercise', () {
    test('returns each weight above zero once, ascending, only of that exercise', () async {
      for (final weight in [22.5, 17.5, 22.5, 0, 17.5]) {
        await repo.addLocalDrift(makeLog(weight: weight, sessionId: 's'));
      }
      await repo.addLocalDrift(
        Log(exerciseId: 1, sessionId: 's', repetitions: 10, weight: null, date: DateTime.utc(2026)),
      );
      await repo.addLocalDrift(makeLog(exerciseId: 2, weight: 40, sessionId: 's'));

      expect(await repo.getDistinctWeightsByExercise(1), [17.5, 22.5]);
    });

    test('with a weight unit, only the weights logged in that unit', () async {
      await repo.addLocalDrift(makeLog(weight: 20, sessionId: 's'));
      await repo.addLocalDrift(makeLog(weight: 45, sessionId: 's')..weightUnitId = 2);

      expect(await repo.getDistinctWeightsByExercise(1, weightUnitId: 1), [20]);
      expect(await repo.getDistinctWeightsByExercise(1, weightUnitId: 2), [45]);
      expect(await repo.getDistinctWeightsByExercise(1), [20, 45]);
    });
  });

  group('hasLogsForSlotEntries', () {
    // The routine starts on this calendar day, local midnight
    final start = DateTime(2026, 11, 29);
    final before = DateTime(2026, 12, 6, 18);

    Future<bool> trained() => repo.hasLogsForSlotEntries(100, [7, 8], since: start, before: before);

    test('is false for a day last trained the evening before the start', () async {
      await repo.addLocalDrift(
        makeLog(sessionId: 's', date: DateTime(2026, 11, 28, 23, 30))..slotEntryId = 7,
      );

      expect(await trained(), isFalse);
    });

    test('is true once one of the slot entries was logged on the start day', () async {
      await repo.addLocalDrift(
        makeLog(sessionId: 's', date: DateTime(2026, 11, 29, 0, 30))..slotEntryId = 8,
      );

      expect(await trained(), isTrue);
    });

    test('ignores other slot entries, other routines and the running workout', () async {
      final day = DateTime(2026, 12, 1, 18);
      await repo.addLocalDrift(makeLog(sessionId: 's1', date: day)..slotEntryId = 9);
      await repo.addLocalDrift(
        makeLog(sessionId: 's2', routineId: 101, date: day)..slotEntryId = 7,
      );
      await repo.addLocalDrift(makeLog(sessionId: 's3', date: before)..slotEntryId = 7);

      expect(await trained(), isFalse);
    });
  });

  group('getSessionsBefore', () {
    test('groups by session, newest session first and each oldest set first', () async {
      await seedUnits();
      await repo.addLocalDrift(makeLog(sessionId: 'old', date: DateTime.utc(2026, 11, 10, 18)));
      await repo.addLocalDrift(
        makeLog(sessionId: 'new', date: DateTime.utc(2026, 11, 20, 18), weight: 60),
      );
      await repo.addLocalDrift(
        makeLog(sessionId: 'new', date: DateTime.utc(2026, 11, 20, 18, 5), weight: 70),
      );
      await repo.addLocalDrift(makeLog(sessionId: 'later', date: DateTime.utc(2026, 11, 25)));

      final sessions = await repo.getSessionsBefore(before: DateTime.utc(2026, 11, 22));

      expect(sessions.map((s) => s.first.sessionId), ['new', 'old']);
      expect(sessions.first.map((l) => l.weight), [60, 70]);
      expect(sessions.first.first.weightUnitObj?.name, 'kg');
    });

    test('leaves out the current run of the routine, not its earlier one', () async {
      final start = DateTime(2026, 11, 29);
      await repo.addLocalDrift(
        makeLog(sessionId: 'earlier-run', routineId: 4, date: DateTime(2026, 7, 17, 18)),
      );
      await repo.addLocalDrift(
        makeLog(sessionId: 'other-routine', routineId: 2, date: DateTime(2026, 11, 22, 18)),
      );
      await repo.addLocalDrift(
        makeLog(sessionId: 'current-run', routineId: 4, date: DateTime(2026, 11, 29, 9)),
      );
      await repo.addLocalDrift(
        makeLog(sessionId: 'no-routine', routineId: null, date: DateTime(2026, 11, 30, 9)),
      );

      final sessions = await repo.getSessionsBefore(
        before: DateTime(2026, 12, 1),
        excludeRoutineId: 4,
        excludeSince: start,
      );

      expect(sessions.map((s) => s.first.sessionId), [
        'no-routine',
        'other-routine',
        'earlier-run',
      ]);
    });

    test('returns at most the given number of sessions', () async {
      for (var day = 1; day <= 5; day++) {
        await repo.addLocalDrift(makeLog(sessionId: 's$day', date: DateTime.utc(2026, 11, day)));
      }

      final sessions = await repo.getSessionsBefore(before: DateTime.utc(2026, 12), limit: 2);

      expect(sessions.map((s) => s.first.sessionId), ['s5', 's4']);
    });
  });
}
