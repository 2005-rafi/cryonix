import 'dart:convert';
import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:flutter/foundation.dart';

import 'tables/classrooms_table.dart';
import 'tables/students_table.dart';
import 'tables/sessions_table.dart';
import 'tables/records_table.dart';
import 'tables/sync_queue_table.dart';
import 'tables/sync_metadata_table.dart';
import 'tables/users_credentials_table.dart';
import '../core/i_database.dart';
import 'migration_strategy.dart';

part 'app_database.g.dart';

@DriftDatabase(
  tables: [
    ClassroomsTable,
    StudentsTable,
    AttendanceSessionsTable,
    AttendanceRecordsTable,
    SyncQueueTable,
    SyncMetadataTable,
    UsersCredentialsTable,
  ],
)
class AppDatabase extends _$AppDatabase implements IDatabase {
  AppDatabase() : super(_openConnection());
  AppDatabase.forTesting(super.e);

  @override
  int get schemaVersion => 16;

  @override
  MigrationStrategy get migration => AppMigrationStrategy.build(this);

  // ── Classroom Queries ─────────────────────────────────────────────────────
  @override
  Future<void> insertClassroom(ClassroomsTableCompanion companion) =>
      into(classroomsTable).insert(companion);

  @override
  Future<bool> checkIfClassroomExists(String classroomId) async =>
      (select(classroomsTable)..where((t) => t.id.equals(classroomId)))
          .getSingleOrNull()
          .then((row) => row != null);

  @override
  Future<int> batchInsertClassrooms(
    List<ClassroomsTableCompanion> companions,
  ) async {
    var insertedCount = 0;
    await transaction(() async {
      for (final companion in companions) {
        final id = companion.id.value;
        final existing = await getClassroomById(id);
        if (existing == null) {
          await into(classroomsTable).insert(companion);
          insertedCount++;
        } else {
          final cloudUpdatedAt = companion.updatedAt.value;
          final localUpdatedAt = existing.updatedAt;
          if (cloudUpdatedAt.isAfter(localUpdatedAt)) {
            await (update(
              classroomsTable,
            )..where((t) => t.id.equals(id))).write(companion);
            insertedCount++;
          }
        }
      }
    });
    return insertedCount;
  }

  @override
  Stream<List<Classroom>> watchClassrooms(String userId) =>
      (select(classroomsTable)
            ..where((t) => t.userId.equals(userId) & t.deletedAt.isNull())
            ..orderBy([
              (t) => OrderingTerm(
                expression: t.createdAt,
                mode: OrderingMode.desc,
              ),
            ]))
          .watch();

  @override
  Future<Classroom?> getClassroomById(String id) => (select(
    classroomsTable,
  )..where((t) => t.id.equals(id))).getSingleOrNull();

  @override
  Future<void> updateClassroom(
    String id,
    String name,
    String subject,
    String? description,
  ) {
    final now = DateTime.now();
    return (update(classroomsTable)..where((t) => t.id.equals(id))).write(
      ClassroomsTableCompanion(
        name: Value(name),
        subject: Value(subject),
        description: Value(description),
        updatedAt: Value(now),
      ),
    );
  }

  @override
  Future<void> incrementStudentCount(String classroomId, {int by = 1}) async {
    final now = DateTime.now();
    await (update(
      classroomsTable,
    )..where((t) => t.id.equals(classroomId))).write(
      ClassroomsTableCompanion.custom(
        studentCount: classroomsTable.studentCount + Constant(by),
        updatedAt: Variable(now),
      ),
    );
  }

  @override
  Future<void> decrementStudentCount(String classroomId, {int by = 1}) async {
    final now = DateTime.now();
    await (update(
      classroomsTable,
    )..where((t) => t.id.equals(classroomId))).write(
      ClassroomsTableCompanion.custom(
        studentCount: classroomsTable.studentCount - Constant(by),
        updatedAt: Variable(now),
      ),
    );
  }

  /// T 6.2 — Recalculate studentCount for a single classroom from ground truth.
  @override
  Future<void> recalculateStudentCount(String classroomId) async {
    final count =
        await (selectOnly(studentsTable)
              ..addColumns([studentsTable.id.count()])
              ..where(
                studentsTable.classroomId.equals(classroomId) &
                    studentsTable.isActive.equals(true),
              ))
            .map((row) => row.read(studentsTable.id.count()) ?? 0)
            .getSingle();
    await (update(
      classroomsTable,
    )..where((t) => t.id.equals(classroomId))).write(
      ClassroomsTableCompanion(
        studentCount: Value(count),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  /// T 6.2 — Self-heal all classrooms at startup. Runs a single query to get
  /// all classroom IDs then recalculates each count.
  Future<void> recalculateAllStudentCounts() async {
    final classrooms =
        await (selectOnly(classroomsTable)..addColumns([classroomsTable.id]))
            .map((row) => row.read(classroomsTable.id)!)
            .get();
    for (final id in classrooms) {
      await recalculateStudentCount(id);
    }
    debugPrint(
      '[DB] Student counts recalculated for ${classrooms.length} classrooms.',
    );
  }

  // ── Student Queries ───────────────────────────────────────────────────────
  @override
  Future<void> insertStudent(StudentsTableCompanion companion) =>
      into(studentsTable).insert(companion);

  @override
  Future<bool> checkIfStudentExists(String studentId) async =>
      (select(studentsTable)..where((t) => t.id.equals(studentId)))
          .getSingleOrNull()
          .then((row) => row != null);

  @override
  Future<void> insertStudentsBatch(
    List<StudentsTableCompanion> companions,
  ) async {
    await batch((batch) {
      batch.insertAll(studentsTable, companions);
    });
  }

  @override
  Future<int> batchInsertStudents(
    List<StudentsTableCompanion> companions,
  ) async {
    var insertedCount = 0;
    await transaction(() async {
      for (final companion in companions) {
        final id = companion.id.value;
        final existing = await (select(
          studentsTable,
        )..where((t) => t.id.equals(id))).getSingleOrNull();
        if (existing == null) {
          await into(studentsTable).insert(companion);
          insertedCount++;
        } else {
          final cloudUpdatedAt = companion.updatedAt.value;
          final localUpdatedAt = existing.updatedAt;
          if (cloudUpdatedAt.isAfter(localUpdatedAt)) {
            await (update(
              studentsTable,
            )..where((t) => t.id.equals(id))).write(companion);
            insertedCount++;
          }
        }
      }
    });
    return insertedCount;
  }

  @override
  Stream<List<Student>> watchActiveStudentsByClassroom(String classroomId) {
    return (select(studentsTable)
          ..where((t) => t.classroomId.equals(classroomId))
          ..where((t) => t.isActive.equals(true))
          ..orderBy([
            (t) =>
                OrderingTerm(expression: t.rollNumber, mode: OrderingMode.asc),
          ]))
        .watch();
  }

  @override
  Future<List<Student>> getActiveStudentsByClassroom(String classroomId) {
    return (select(studentsTable)
          ..where((t) => t.classroomId.equals(classroomId))
          ..where((t) => t.isActive.equals(true)))
        .get();
  }

  @override
  Future<void> updateStudent(String id, String rollNumber, String name) {
    final now = DateTime.now();
    return (update(studentsTable)..where((t) => t.id.equals(id))).write(
      StudentsTableCompanion(
        rollNumber: Value(rollNumber),
        name: Value(name),
        updatedAt: Value(now), // Phase 4: always update timestamp
      ),
    );
  }

  @override
  Future<void> softDeleteStudent(String id, String classroomId) async {
    await transaction(() async {
      final now = DateTime.now();
      final student =
          await (select(studentsTable)..where(
                (t) => t.id.equals(id) & t.classroomId.equals(classroomId),
              ))
              .getSingleOrNull();
      if (student == null) return;

      final records = await (select(
        attendanceRecordsTable,
      )..where((t) => t.studentId.equals(id))).get();
      final sessionIds = records.map((r) => r.sessionId).toSet();

      final deletedRoll =
          '${student.rollNumber}_del_${now.millisecondsSinceEpoch}';

      await (update(studentsTable)
            ..where((t) => t.id.equals(id) & t.classroomId.equals(classroomId)))
          .write(
            StudentsTableCompanion(
              isActive: const Value(false),
              rollNumber: Value(deletedRoll),
              deletedAt: Value(now),
              updatedAt: Value(now), // Phase 4
            ),
          );

      for (final sessionId in sessionIds) {
        await recalculateSessionCounts(sessionId);
      }
    });
  }

  Future<Set<String>> getSameClassroomStudentIds(String classroomId) async {
    final students = await getActiveStudentsByClassroom(classroomId);
    return students.map((s) => s.id).toSet();
  }

  // ── Session Queries ───────────────────────────────────────────────────────
  @override
  Future<void> insertSession(AttendanceSessionsTableCompanion companion) =>
      into(attendanceSessionsTable).insert(companion);

  @override
  Future<int> batchInsertSessions(
    List<AttendanceSessionsTableCompanion> companions,
  ) async {
    var insertedCount = 0;
    await transaction(() async {
      for (final companion in companions) {
        final id = companion.id.value;
        final existing = await getSessionById(id);
        if (existing == null) {
          await into(attendanceSessionsTable).insert(companion);
          insertedCount++;
        } else {
          final cloudUpdatedAt = companion.updatedAt.value;
          final localUpdatedAt = existing.updatedAt;
          if (cloudUpdatedAt.isAfter(localUpdatedAt)) {
            (update(
              attendanceSessionsTable,
            )..where((t) => t.id.equals(id))).write(companion);
            insertedCount++;
          }
        }
      }
    });
    return insertedCount;
  }

  Future<void> deleteSession(String sessionId) async {
    await (delete(
      attendanceRecordsTable,
    )..where((t) => t.sessionId.equals(sessionId))).go();
    await (delete(
      attendanceSessionsTable,
    )..where((t) => t.id.equals(sessionId))).go();
  }

  @override
  Stream<List<AttendanceSession>> watchSessionsByClassroom(
    String classroomId, {
    int limit = 60,
  }) {
    return (select(attendanceSessionsTable)
          ..where((t) => t.classroomId.equals(classroomId))
          ..where((t) => t.isDeleted.equals(false))
          ..orderBy([
            (t) => OrderingTerm(expression: t.date, mode: OrderingMode.desc),
            (t) =>
                OrderingTerm(expression: t.createdAt, mode: OrderingMode.asc),
          ])
          ..limit(limit))
        .watch();
  }

  Future<List<AttendanceSession>> getSessionsForClassroomPage(
    String classroomId,
    int offset, {
    int limit = 60,
  }) {
    return (select(attendanceSessionsTable)
          ..where((t) => t.classroomId.equals(classroomId))
          ..where((t) => t.isDeleted.equals(false))
          ..orderBy([
            (t) => OrderingTerm(expression: t.date, mode: OrderingMode.desc),
            (t) =>
                OrderingTerm(expression: t.createdAt, mode: OrderingMode.asc),
          ])
          ..limit(limit, offset: offset))
        .get();
  }

  /// T 6.3 — Cursor-based pagination. [cursor] is exclusive (sessions before
  /// this date). Pass null to start from the most recent session.
  @override
  Future<List<AttendanceSession>> getSessionsPageCursor(
    String classroomId, {
    DateTime? cursor,
    int limit = 20,
  }) {
    final query = select(attendanceSessionsTable)
      ..where((t) => t.classroomId.equals(classroomId))
      ..where((t) => t.isDeleted.equals(false));
    if (cursor != null) {
      query.where((t) => t.date.isSmallerThanValue(cursor));
    }
    query
      ..orderBy([
        (t) => OrderingTerm(expression: t.date, mode: OrderingMode.desc),
        (t) => OrderingTerm(expression: t.createdAt, mode: OrderingMode.asc),
      ])
      ..limit(limit);
    return query.get();
  }

  Future<List<AttendanceSession>> getSessionsByClassroom(String classroomId) =>
      (select(attendanceSessionsTable)
            ..where((t) => t.classroomId.equals(classroomId))
            ..where((t) => t.isDeleted.equals(false)))
          .get();

  Stream<List<AttendanceSession>> watchDeletedSessionsByClassroom(
    String classroomId,
  ) {
    return (select(attendanceSessionsTable)
          ..where((t) => t.classroomId.equals(classroomId))
          ..where((t) => t.isDeleted.equals(true))
          ..orderBy([
            (t) =>
                OrderingTerm(expression: t.deletedAt, mode: OrderingMode.desc),
          ]))
        .watch();
  }

  @override
  Future<AttendanceSession?> getSessionById(String sessionId) {
    return (select(
      attendanceSessionsTable,
    )..where((t) => t.id.equals(sessionId))).getSingleOrNull();
  }

  @override
  Future<void> recalculateSessionCounts(String sessionId) async {
    final session = await getSessionById(sessionId);
    if (session == null) return;

    final records = await getRecordsBySession(sessionId);
    int pCount = 0, aCount = 0, oCount = 0;

    for (final r in records) {
      switch (r.status) {
        case 'present':
          pCount++;
          break;
        case 'absent':
          aCount++;
          break;
        case 'onDuty':
          oCount++;
          break;
      }
    }

    await (update(
      attendanceSessionsTable,
    )..where((t) => t.id.equals(sessionId))).write(
      AttendanceSessionsTableCompanion(
        presentCount: Value(pCount),
        absentCount: Value(aCount),
        onDutyCount: Value(oCount),
        totalStudents: Value(records.length),
        updatedAt: Value(DateTime.now()), // Phase 4
      ),
    );
  }

  // ── Record Queries ────────────────────────────────────────────────────────
  @override
  Future<void> insertRecordsBatch(
    List<AttendanceRecordsTableCompanion> companions,
  ) async {
    await batch((b) {
      b.insertAllOnConflictUpdate(attendanceRecordsTable, companions);
    });
  }

  @override
  Future<int> batchInsertRecords(
    List<AttendanceRecordsTableCompanion> companions,
  ) async {
    var insertedCount = 0;
    await transaction(() async {
      for (final companion in companions) {
        final id = companion.id.value;
        final existing = await (select(
          attendanceRecordsTable,
        )..where((t) => t.id.equals(id))).getSingleOrNull();
        if (existing == null) {
          await into(attendanceRecordsTable).insert(companion);
          insertedCount++;
        } else {
          final cloudMarkedAt = companion.markedAt.value;
          final localMarkedAt = existing.markedAt;
          if (cloudMarkedAt.isAfter(localMarkedAt)) {
            await (update(
              attendanceRecordsTable,
            )..where((t) => t.id.equals(id))).write(companion);
            insertedCount++;
          }
        }
      }
    });
    return insertedCount;
  }

  @override
  Future<List<AttendanceRecord>> getRecordsBySession(String sessionId) =>
      (select(
        attendanceRecordsTable,
      )..where((t) => t.sessionId.equals(sessionId))).get();

  @override
  Stream<List<AttendanceRecord>> watchRecordsBySession(String sessionId) =>
      (select(
        attendanceRecordsTable,
      )..where((t) => t.sessionId.equals(sessionId))).watch();

  Future<int> getRecordCountForSession(String sessionId) async {
    final countExpr = attendanceRecordsTable.id.count();
    final result =
        await (selectOnly(attendanceRecordsTable)
              ..addColumns([countExpr])
              ..where(attendanceRecordsTable.sessionId.equals(sessionId)))
            .getSingle();
    return result.read(countExpr) ?? 0;
  }

  Future<List<TypedResult>> getClassroomStats(
    String classroomId,
    DateTime startDate,
    DateTime endDate,
  ) {
    final statusCount = attendanceRecordsTable.id.count();
    final query = selectOnly(attendanceRecordsTable).join([
      innerJoin(
        attendanceSessionsTable,
        attendanceSessionsTable.id.equalsExp(attendanceRecordsTable.sessionId),
      ),
    ]);
    query.addColumns([attendanceRecordsTable.status, statusCount]);
    query.where(
      attendanceRecordsTable.classroomId.equals(classroomId) &
          attendanceSessionsTable.isDeleted.equals(false) &
          attendanceRecordsTable.markedAt.isBetweenValues(startDate, endDate),
    );
    query.groupBy([attendanceRecordsTable.status]);
    return query.get();
  }

  @override
  Future<List<AttendanceRecord>> getStudentAttendanceSummary(
    String studentId,
    String classroomId,
    DateTime enrolledAt,
  ) {
    final query = select(attendanceRecordsTable).join([
      innerJoin(
        attendanceSessionsTable,
        attendanceSessionsTable.id.equalsExp(attendanceRecordsTable.sessionId),
      ),
    ]);

    query.where(
      attendanceRecordsTable.studentId.equals(studentId) &
          attendanceRecordsTable.classroomId.equals(classroomId) &
          attendanceSessionsTable.date.isBiggerOrEqualValue(enrolledAt),
    );

    return query.map((row) => row.readTable(attendanceRecordsTable)).get();
  }

  @override
  Future<void> reconcileRecentSessionCounts() async {
    final sessions =
        await (select(attendanceSessionsTable)
              ..orderBy([
                (t) =>
                    OrderingTerm(expression: t.date, mode: OrderingMode.desc),
                (t) => OrderingTerm(
                  expression: t.createdAt,
                  mode: OrderingMode.desc,
                ),
              ])
              ..limit(30))
            .get();

    for (final session in sessions) {
      final records = await getRecordsBySession(session.id);
      int pCount = 0, aCount = 0, oCount = 0;

      for (final r in records) {
        if (r.status == 'present') {
          pCount++;
        } else if (r.status == 'absent') {
          aCount++;
        } else if (r.status == 'onDuty') {
          oCount++;
        }
      }

      if (session.presentCount != pCount ||
          session.absentCount != aCount ||
          session.onDutyCount != oCount ||
          session.totalStudents != records.length) {
        debugPrint(
          '[Database] Reconciling counts for session ${session.id} on ${session.date}',
        );
        await (update(
          attendanceSessionsTable,
        )..where((t) => t.id.equals(session.id))).write(
          AttendanceSessionsTableCompanion(
            presentCount: Value(pCount),
            absentCount: Value(aCount),
            onDutyCount: Value(oCount),
            totalStudents: Value(records.length),
          ),
        );
      }
    }
  }

  Future<void> permanentlyDeleteOldSessions() async {
    final threshold = DateTime.now().subtract(const Duration(days: 30));
    final oldSessions =
        await (select(attendanceSessionsTable)
              ..where((t) => t.isDeleted.equals(true))
              ..where((t) => t.deletedAt.isSmallerThanValue(threshold)))
            .get();

    for (final s in oldSessions) {
      await deleteSession(s.id);
    }
  }

  Future<void> auditSessionDates() async {
    final sessions = await select(attendanceSessionsTable).get();
    for (final s in sessions) {
      if (s.date.hour != 0 ||
          s.date.minute != 0 ||
          s.date.second != 0 ||
          s.date.millisecond != 0 ||
          s.date.microsecond != 0 ||
          !s.date.isUtc) {
        debugPrint(
          '[Startup] Audit Warning: Session ${s.id} has non-midnight date: ${s.date}',
        );
      }
    }
  }

  // ── Sync Queue Queries ────────────────────────────────────────────────────
  @override
  Future<T> writeAndEnqueue<T>(
    Future<T> Function() writeAction,
    List<SyncQueueTableCompanion> syncEntries,
  ) {
    return transaction(() async {
      final result = await writeAction();
      for (final entry in syncEntries) {
        SyncQueueTableCompanion updatedEntry = entry;
        if (entry.operation.value == 'upsert') {
          String? jsonPayload;
          final entityId = entry.entityId.value;
          final type = entry.entityType.value;

          if (type == 'classroom') {
            final row = await (select(
              classroomsTable,
            )..where((t) => t.id.equals(entityId))).getSingleOrNull();
            if (row != null) {
              final newVer = row.syncVersion + 1;
              await (update(classroomsTable)
                    ..where((t) => t.id.equals(entityId)))
                  .write(ClassroomsTableCompanion(syncVersion: Value(newVer)));
              final updated = await (select(
                classroomsTable,
              )..where((t) => t.id.equals(entityId))).getSingle();
              jsonPayload = jsonEncode(updated.toJson());
            }
          } else if (type == 'student') {
            final row = await (select(
              studentsTable,
            )..where((t) => t.id.equals(entityId))).getSingleOrNull();
            if (row != null) {
              final newVer = row.syncVersion + 1;
              await (update(studentsTable)..where((t) => t.id.equals(entityId)))
                  .write(StudentsTableCompanion(syncVersion: Value(newVer)));
              final updated = await (select(
                studentsTable,
              )..where((t) => t.id.equals(entityId))).getSingle();
              jsonPayload = jsonEncode(updated.toJson());
            }
          } else if (type == 'session') {
            final row = await (select(
              attendanceSessionsTable,
            )..where((t) => t.id.equals(entityId))).getSingleOrNull();
            if (row != null) {
              final newVer = row.syncVersion + 1;
              await (update(
                attendanceSessionsTable,
              )..where((t) => t.id.equals(entityId))).write(
                AttendanceSessionsTableCompanion(syncVersion: Value(newVer)),
              );
              final updated = await (select(
                attendanceSessionsTable,
              )..where((t) => t.id.equals(entityId))).getSingle();
              jsonPayload = jsonEncode(updated.toJson());
            }
          } else if (type == 'record') {
            final row = await (select(
              attendanceRecordsTable,
            )..where((t) => t.id.equals(entityId))).getSingleOrNull();
            if (row != null) {
              final newVer = row.syncVersion + 1;
              await (update(
                attendanceRecordsTable,
              )..where((t) => t.id.equals(entityId))).write(
                AttendanceRecordsTableCompanion(syncVersion: Value(newVer)),
              );
              final updated = await (select(
                attendanceRecordsTable,
              )..where((t) => t.id.equals(entityId))).getSingle();
              jsonPayload = jsonEncode(updated.toJson());
            }
          }

          if (jsonPayload != null) {
            updatedEntry = entry.copyWith(pendingPayload: Value(jsonPayload));
          }
        }
        await enqueueSyncEntry(updatedEntry);
      }
      return result;
    });
  }

  @override
  Future<void> enqueueSyncEntry(SyncQueueTableCompanion companion) async {
    // Offline mode: NO-OP
  }

  /// Returns pending entries whose `nextRetryAt` is in the past (or zero).
  /// This is how exponential backoff filtering works — entries in their
  /// backoff window are excluded (Phase 3 — Task 3.1).
  @override
  Future<List<SyncQueueEntry>> getPendingSyncEntries(int limit) {
    final nowMs = DateTime.now().millisecondsSinceEpoch;
    return (select(syncQueueTable)
          ..where(
            (t) =>
                t.status.equals('pending') &
                t.nextRetryAt.isSmallerOrEqualValue(nowMs),
          )
          ..orderBy([
            (t) =>
                OrderingTerm(expression: t.enqueuedAt, mode: OrderingMode.asc),
          ])
          ..limit(limit))
        .get();
  }

  Future<List<SyncQueueEntry>> getPendingSyncEntriesByType(
    String type,
    int limit,
  ) {
    final nowMs = DateTime.now().millisecondsSinceEpoch;
    return (select(syncQueueTable)
          ..where(
            (t) =>
                t.status.equals('pending') &
                t.entityType.equals(type) &
                t.nextRetryAt.isSmallerOrEqualValue(nowMs),
          )
          ..orderBy([
            (t) =>
                OrderingTerm(expression: t.enqueuedAt, mode: OrderingMode.asc),
          ])
          ..limit(limit))
        .get();
  }

  Future<List<SyncQueueEntry>> getPermanentErrorEntries() {
    return (select(
      syncQueueTable,
    )..where((t) => t.status.equals('permanent_error'))).get();
  }

  @override
  Future<int> getPermanentErrorCount() async {
    final countExpr = syncQueueTable.id.count();
    final result =
        await (selectOnly(syncQueueTable)
              ..addColumns([countExpr])
              ..where(syncQueueTable.status.equals('permanent_error')))
            .getSingle();
    return result.read(countExpr) ?? 0;
  }

  /// Resets all permanent_error entries to pending so they are retried.
  Future<void> retryAllPermanentErrors() {
    return (update(
      syncQueueTable,
    )..where((t) => t.status.equals('permanent_error'))).write(
      SyncQueueTableCompanion(
        status: const Value('pending'),
        nextRetryAt: const Value(0),
        backoffLevel: const Value(0),
        failureCategory: const Value(null),
        lastAttemptAt: Value(null),
      ),
    );
  }

  @override
  Future<void> markSyncInProgress(String id, String sessionId) {
    return (update(syncQueueTable)..where((t) => t.id.equals(id))).write(
      SyncQueueTableCompanion(
        status: const Value('in_progress'),
        lastAttemptAt: Value(DateTime.now()),
        syncSessionId: Value(sessionId),
      ),
    );
  }

  @override
  Future<void> deleteSyncEntry(String id, {String? syncSessionId}) {
    final query = delete(syncQueueTable)..where((t) => t.id.equals(id));
    if (syncSessionId != null) {
      query.where((t) => t.syncSessionId.equals(syncSessionId));
    }
    return query.go();
  }

  /// Marks an entry as failed with exponential backoff (Phase 3 — Task 3.1).
  /// [isTransient]: true = network error (retry), false = permanent error.
  @override
  Future<void> markSyncFailed(
    String id, {
    bool isTransient = true,
    String? syncSessionId,
  }) async {
    final query = select(syncQueueTable)..where((t) => t.id.equals(id));
    if (syncSessionId != null) {
      query.where((t) => t.syncSessionId.equals(syncSessionId));
    }
    final entry = await query.getSingleOrNull();
    if (entry == null) return;

    final updateQuery = update(syncQueueTable)..where((t) => t.id.equals(id));
    if (syncSessionId != null) {
      updateQuery.where((t) => t.syncSessionId.equals(syncSessionId));
    }

    // Phase 4 Task 4.2: age-based permanent failure removed.
    // Entries live in the queue indefinitely until they succeed or receive
    // a true permanent Firestore error (permission-denied, invalid-argument).
    if (!isTransient) {
      // Permanent failure — do not retry.
      await updateQuery.write(
        SyncQueueTableCompanion(
          status: const Value('permanent_error'),
          failureCategory: const Value('permanent'),
          retryCount: Value(entry.retryCount + 1),
          lastAttemptAt: Value(DateTime.now()),
        ),
      );
      return;
    }

    // Transient failure — apply exponential backoff.
    final newLevel = entry.backoffLevel + 1;
    final backoffMs = _backoffDuration(newLevel);
    final jitterMs = (backoffMs * 0.2 * (DateTime.now().microsecond / 1000000))
        .round();
    final nextRetryAt =
        DateTime.now().millisecondsSinceEpoch + backoffMs + jitterMs;

    await updateQuery.write(
      SyncQueueTableCompanion(
        status: const Value('pending'),
        failureCategory: const Value('transient'),
        retryCount: Value(entry.retryCount + 1),
        backoffLevel: Value(newLevel),
        nextRetryAt: Value(nextRetryAt),
        lastAttemptAt: Value(DateTime.now()),
      ),
    );
  }

  /// Exponential backoff schedule in milliseconds (Phase 3 — Task 3.1):
  /// Level 0 → 0s, 1 → 30s, 2 → 2m, 3 → 10m, 4 → 30m, 5 → 2h, 6+ → 6h.
  static int _backoffDuration(int level) {
    const schedule = [0, 30, 120, 600, 1800, 7200, 21600];
    final seconds = schedule[level.clamp(0, schedule.length - 1)];
    return seconds * 1000;
  }

  /// Resets stale in_progress entries to pending on startup (Phase 3 — Task 3.3).
  /// Also resets entries stuck > 10 minutes.
  @override
  Future<int> resetStaleInProgress([String? currentSessionId]) async {
    final query = select(syncQueueTable)
      ..where((t) => t.status.equals('in_progress'));

    if (currentSessionId != null) {
      query.where(
        (t) =>
            t.syncSessionId.equals(currentSessionId).not() |
            t.syncSessionId.isNull(),
      );
    }

    final stale = await query.get();

    if (stale.isNotEmpty) {
      debugPrint(
        '[SyncQueue] Resetting ${stale.length} stale in_progress entries.',
      );
      final updateQuery = update(syncQueueTable)
        ..where((t) => t.status.equals('in_progress'));

      if (currentSessionId != null) {
        updateQuery.where(
          (t) =>
              t.syncSessionId.equals(currentSessionId).not() |
              t.syncSessionId.isNull(),
        );
      }

      await updateQuery.write(
        const SyncQueueTableCompanion(
          status: Value('pending'),
          syncSessionId: Value(null),
        ),
      );
    }

    return stale.length;
  }

  /// Resets all in-progress entries owned by the current sync session.
  /// Used when the app is paused mid-sync so those entries can retry cleanly
  /// on the next foreground or connectivity-driven sync attempt.
  Future<int> resetInProgressForSession(String sessionId) async {
    final stuckEntries =
        await (select(syncQueueTable)..where(
              (t) =>
                  t.status.equals('in_progress') &
                  t.syncSessionId.equals(sessionId),
            ))
            .get();

    if (stuckEntries.isEmpty) {
      return 0;
    }

    await (update(syncQueueTable)..where(
          (t) =>
              t.status.equals('in_progress') &
              t.syncSessionId.equals(sessionId),
        ))
        .write(
          const SyncQueueTableCompanion(
            status: Value('pending'),
            syncSessionId: Value(null),
          ),
        );

    return stuckEntries.length;
  }

  /// Phase 4 Task 4.2: Only purge permanent_error entries older than 30 days.
  /// Pending entries are NEVER age-purged — they live until success or a
  /// true permanent Firestore error.
  Future<void> purgeStaleFailedEntries() {
    final cutoff = DateTime.now().subtract(const Duration(days: 30));
    return (delete(syncQueueTable)..where(
          (t) =>
              t.status.equals('permanent_error') &
              t.enqueuedAt.isSmallerThanValue(cutoff),
        ))
        .go();
  }

  // ── Analytics Aggregate Queries ─────────────────────────────────────────

  /// Returns overall teaching stats for a user in **one SQL pass**.
  ///
  /// Replaces the previous O(C + S) N+1 loop approach — at 2-year data volumes
  /// (e.g. 20 classrooms × 200 sessions) this saves ~4 000 round-trips.

  // ── Legacy Analytics Query (kept for test compatibility) ─────────────────
  Future<List<AttendanceRecord>> getAttendanceSummaryForDateRange(
    String classroomId,
    DateTime startDate,
    DateTime endDate,
  ) {
    return (select(attendanceRecordsTable)
          ..where((t) => t.classroomId.equals(classroomId))
          ..where((t) => t.markedAt.isBetweenValues(startDate, endDate)))
        .get();
  }

  // ── Downward Sync (Phase 4 — Task 4.3) ───────────────────────────────────
  DateTime _parseDateTime(dynamic value, [DateTime? fallback]) {
    if (value == null) return fallback ?? DateTime.now();
    if (value is String) {
      return DateTime.tryParse(value) ?? fallback ?? DateTime.now();
    }
    if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
    // Handle Firestore Timestamp if available (without importing cloud_firestore here if possible,
    // but sync_service passes raw data which might contain it)
    if (value.runtimeType.toString() == 'Timestamp') {
      // Use dynamic to avoid explicit dependency on cloud_firestore in the database layer if not needed,
      // but we know it has a toDate() method.
      try {
        return (value as dynamic).toDate() as DateTime;
      } catch (_) {
        return fallback ?? DateTime.now();
      }
    }
    return fallback ?? DateTime.now();
  }

  /// Updates a local student row with data fetched from Firestore (conflict
  /// resolution where cloud version is newer than local).
  Future<void> applyCloudStudent(
    String studentId,
    Map<String, dynamic> cloudData, {
    bool isFromListener = false,
  }) async {
    final local = await (select(
      studentsTable,
    )..where((t) => t.id.equals(studentId))).getSingleOrNull();
    final cloudUpdatedAt = _parseDateTime(cloudData['updatedAt']);
    final cloudVer = cloudData['syncVersion'] as int? ?? 0;
    if (local != null) {
      final diffMs =
          (cloudUpdatedAt.millisecondsSinceEpoch -
                  local.updatedAt.millisecondsSinceEpoch)
              .abs();
      if (diffMs <= 1000) {
        if (local.syncVersion > cloudVer) {
          return;
        }
      } else if (!cloudUpdatedAt.isAfter(local.updatedAt)) {
        return;
      }
    }
    final isActiveVal = cloudData['isActive'];
    final isActiveBool = isActiveVal is bool
        ? isActiveVal
        : (isActiveVal == null
              ? true
              : (isActiveVal is int ? isActiveVal != 0 : true));

    final enrolledAtDate = _parseDateTime(
      cloudData['enrolledAt'],
      cloudUpdatedAt,
    );
    final createdAtDate = _parseDateTime(
      cloudData['createdAt'],
      cloudUpdatedAt,
    );

    await into(studentsTable).insertOnConflictUpdate(
      StudentsTableCompanion(
        id: Value(studentId),
        classroomId: Value(
          cloudData['classroomId'] as String? ?? local?.classroomId ?? '',
        ),
        name: Value(cloudData['name'] as String? ?? ''),
        rollNumber: Value(cloudData['rollNumber'] as String? ?? ''),
        isActive: Value(isActiveBool),
        enrolledAt: Value(enrolledAtDate),
        deletedAt: cloudData['deletedAt'] == null
            ? const Value.absent()
            : Value(_parseDateTime(cloudData['deletedAt'])),
        createdAt: Value(createdAtDate),
        updatedAt: Value(cloudUpdatedAt),
        syncVersion: Value(cloudVer),
      ),
    );
  }

  /// Updates a local classroom row with data fetched from Firestore.
  Future<void> applyCloudClassroom(
    String classroomId,
    Map<String, dynamic> cloudData, {
    bool isFromListener = false,
  }) async {
    final local = await (select(
      classroomsTable,
    )..where((t) => t.id.equals(classroomId))).getSingleOrNull();
    final cloudUpdatedAt = _parseDateTime(cloudData['updatedAt']);
    final cloudVer = cloudData['syncVersion'] as int? ?? 0;
    if (local != null) {
      final diffMs =
          (cloudUpdatedAt.millisecondsSinceEpoch -
                  local.updatedAt.millisecondsSinceEpoch)
              .abs();
      if (diffMs <= 1000) {
        if (local.syncVersion > cloudVer) {
          return;
        }
      } else if (!cloudUpdatedAt.isAfter(local.updatedAt)) {
        return;
      }
    }
    final studentCountVal = cloudData['studentCount'];
    final studentCountInt = studentCountVal is num
        ? studentCountVal.toInt()
        : 0;
    await into(classroomsTable).insertOnConflictUpdate(
      ClassroomsTableCompanion(
        id: Value(classroomId),
        userId: Value(cloudData['userId'] as String? ?? local?.userId ?? ''),
        name: Value(cloudData['name'] as String? ?? ''),
        subject: cloudData['subject'] == null
            ? const Value.absent()
            : Value(cloudData['subject'] as String?),
        description: cloudData['description'] == null
            ? const Value.absent()
            : Value(cloudData['description'] as String?),
        studentCount: Value(studentCountInt),
        createdAt: Value(
          _parseDateTime(cloudData['createdAt'], cloudUpdatedAt),
        ),
        updatedAt: Value(cloudUpdatedAt),
        deletedAt: cloudData['deletedAt'] == null
            ? const Value.absent()
            : Value(_parseDateTime(cloudData['deletedAt'])),
        syncVersion: Value(cloudVer),
      ),
    );
  }

  /// Updates a local session row with data fetched from Firestore.
  Future<void> applyCloudSession(
    String sessionId,
    Map<String, dynamic> cloudData, {
    bool isFromListener = false,
  }) async {
    final local = await (select(
      attendanceSessionsTable,
    )..where((t) => t.id.equals(sessionId))).getSingleOrNull();
    final cloudUpdatedAt = _parseDateTime(cloudData['updatedAt']);
    final cloudVer = cloudData['syncVersion'] as int? ?? 0;
    if (local != null) {
      final diffMs =
          (cloudUpdatedAt.millisecondsSinceEpoch -
                  local.updatedAt.millisecondsSinceEpoch)
              .abs();
      if (diffMs <= 1000) {
        if (local.syncVersion > cloudVer) {
          return;
        }
      } else {
        if (!cloudUpdatedAt.isAfter(local.updatedAt)) {
          return;
        }
      }
    }
    final isDeletedVal = cloudData['isDeleted'];
    final isDeletedBool = isDeletedVal is bool
        ? isDeletedVal
        : (isDeletedVal == null
              ? false
              : (isDeletedVal is int ? isDeletedVal != 0 : false));

    int toInt(dynamic v) => v is num ? v.toInt() : 0;

    await into(attendanceSessionsTable).insertOnConflictUpdate(
      AttendanceSessionsTableCompanion(
        id: Value(sessionId),
        classroomId: Value(
          cloudData['classroomId'] as String? ?? local?.classroomId ?? '',
        ),
        date: Value(_parseDateTime(cloudData['date'], cloudUpdatedAt)),
        totalStudents: Value(toInt(cloudData['totalStudents'])),
        presentCount: Value(toInt(cloudData['presentCount'])),
        absentCount: Value(toInt(cloudData['absentCount'])),
        onDutyCount: Value(toInt(cloudData['onDutyCount'])),
        label: Value(cloudData['label'] as String? ?? 'Full Day'),
        isDeleted: Value(isDeletedBool),
        deletedAt: cloudData['deletedAt'] == null
            ? const Value.absent()
            : Value(_parseDateTime(cloudData['deletedAt'])),
        createdAt: Value(
          _parseDateTime(cloudData['createdAt'], cloudUpdatedAt),
        ),
        updatedAt: Value(cloudUpdatedAt),
        syncVersion: Value(cloudVer),
      ),
    );
  }

  /// Updates a local record row with data fetched from Firestore.
  Future<void> applyCloudRecord(
    String recordId,
    Map<String, dynamic> cloudData, {
    bool isFromListener = false,
  }) async {
    final local = await (select(
      attendanceRecordsTable,
    )..where((t) => t.id.equals(recordId))).getSingleOrNull();
    final cloudMarkedAt = _parseDateTime(cloudData['markedAt']);
    final cloudVer = cloudData['syncVersion'] as int? ?? 0;
    if (local != null) {
      final diffMs =
          (cloudMarkedAt.millisecondsSinceEpoch -
                  local.markedAt.millisecondsSinceEpoch)
              .abs();
      if (diffMs <= 1000) {
        if (local.syncVersion > cloudVer) {
          return;
        }
      } else {
        if (!cloudMarkedAt.isAfter(local.markedAt)) {
          return;
        }
      }
    }
    await into(attendanceRecordsTable).insertOnConflictUpdate(
      AttendanceRecordsTableCompanion(
        id: Value(recordId),
        studentId: Value(cloudData['studentId'] as String? ?? ''),
        sessionId: Value(cloudData['sessionId'] as String? ?? ''),
        classroomId: Value(cloudData['classroomId'] as String? ?? ''),
        status: Value(cloudData['status'] as String? ?? 'present'),
        snapshotName: Value(cloudData['snapshotName'] as String? ?? ''),
        snapshotRoll: Value(cloudData['snapshotRoll'] as String? ?? ''),
        markedAt: Value(cloudMarkedAt),
        syncVersion: Value(cloudVer),
      ),
    );
  }

  @override
  Future<String?> getLastDownloadedAt(String collectionKey) async {
    final entry = await (select(
      syncMetadataTable,
    )..where((t) => t.collectionKey.equals(collectionKey))).getSingleOrNull();
    return entry?.lastDownloadedAt;
  }

  @override
  Future<void> setLastDownloadedAt(
    String collectionKey,
    String lastDownloadedAt,
  ) async {
    await into(syncMetadataTable).insertOnConflictUpdate(
      SyncMetadataTableCompanion(
        collectionKey: Value(collectionKey),
        lastDownloadedAt: Value(lastDownloadedAt),
      ),
    );
  }
}

QueryExecutor _openConnection() {
  return driftDatabase(
    name: 'cryonix',
    native: DriftNativeOptions(
      shareAcrossIsolates: true,
      setup: (db) {
        db.execute('PRAGMA busy_timeout = 5000;');
      },
    ),
  );
}
