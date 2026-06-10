import 'package:drift/drift.dart';
import '../../auth/repository/i_auth_repository.dart';
import 'package:uuid/uuid.dart';
import '../../../core/constants.dart';
import '../../../core/result.dart';
import '../../../database/app_database.dart';
import '../../../models/session_summary.dart';
import '../../../models/record_with_student.dart';
import '../../classroom/repository/student_repository.dart';

import '../../../models/session_date_group.dart';
import '../../../core/utils.dart';
import 'package:flutter/foundation.dart';

class DuplicateSessionException implements Exception {
  final String sessionId;
  DuplicateSessionException(this.sessionId);
}

class InvalidStatusException implements Exception {
  final String studentId;
  final String status;
  InvalidStatusException(this.studentId, this.status);
}

class ClassroomOwnershipException implements Exception {
  final String message;
  ClassroomOwnershipException(this.message);
}

class AttendanceRepository {
  final AppDatabase _db;
  final StudentRepository _studentRepo;
  final IAuthRepository _auth;

  AttendanceRepository(this._db, this._studentRepo, {required IAuthRepository auth})
    : _auth = auth;

  Future<Result<String>> createSession(
    String classroomId,
    DateTime date, {
    String label = 'Full Day',
  }) async {
    try {
      final uid = _auth.currentUser?.uid;
      final ownerCheck =
          await (_db.selectOnly(_db.classroomsTable)
                ..addColumns([_db.classroomsTable.id])
                ..where(
                  _db.classroomsTable.id.equals(classroomId) &
                      _db.classroomsTable.userId.equals(uid ?? ''),
                ))
              .getSingleOrNull();

      if (ownerCheck == null) {
        return Result.failure(
          ClassroomOwnershipException(
            "Classroom does not belong to current user",
          ),
        );
      }

      final normalizedDate = DateNormalizer.normalizeToMidnightUtc(date);

      final existingSession =
          await (_db.select(_db.attendanceSessionsTable)
                ..where((t) => t.classroomId.equals(classroomId))
                ..where((t) => t.date.equals(normalizedDate))
                ..where((t) => t.label.equals(label)))
              .getSingleOrNull();

      if (existingSession != null) {
        return Result.failure(DuplicateSessionException(existingSession.id));
      }

      final sessionId = const Uuid().v4();
      final totalStudents = await _db.getSameClassroomStudentIds(classroomId);

      final now = DateTime.now();
      await _db.writeAndEnqueue(
        () async {
          await _db.insertSession(
            AttendanceSessionsTableCompanion.insert(
              id: sessionId,
              classroomId: classroomId,
              date: normalizedDate,
              label: Value(label),
              totalStudents: Value(totalStudents.length),
              createdAt: now,
              updatedAt: now,
            ),
          );
          // Update classroom lastSessionAt cache
          await (_db.update(
            _db.classroomsTable,
          )..where((t) => t.id.equals(classroomId))).write(
            ClassroomsTableCompanion(
              lastSessionAt: Value(normalizedDate),
              updatedAt: Value(now),
            ),
          );
        },
        [
          SyncQueueTableCompanion.insert(
            id: 'session:$sessionId',
            entityType: 'session',
            entityId: sessionId,
            operation: const Value('upsert'),
            enqueuedAt: DateTime.now(),
          ),
        ],
      );
      return Result.success(sessionId);
    } catch (e, st) {
      // Handle rare race condition where unique constraint is hit after our check
      if (e.toString().contains('UNIQUE constraint failed')) {
        final retryExisting =
            await (_db.select(_db.attendanceSessionsTable)
                  ..where((t) => t.classroomId.equals(classroomId))
                  ..where(
                    (t) => t.date.equals(
                      DateNormalizer.normalizeToMidnightUtc(date),
                    ),
                  )
                  ..where((t) => t.label.equals(label)))
                .getSingleOrNull();
        if (retryExisting != null) {
          return Result.failure(DuplicateSessionException(retryExisting.id));
        }
      }
      return Result.failure(e, st);
    }
  }

  Future<void> saveSessionWithRecords(
    String sessionId,
    String classroomId,
    Map<String, AttendanceStatus> statusMap,
  ) async {
    final validIds = await _db.getSameClassroomStudentIds(classroomId);
    for (final id in statusMap.keys) {
      if (!validIds.contains(id)) {
        throw Exception(
          "Student $id does not belong to classroom $classroomId",
        );
      }
    }

    // Phase 9 - Idempotency check: if records exist, do not insert again
    final existingRecords = await (_db.select(
      _db.attendanceRecordsTable,
    )..where((t) => t.sessionId.equals(sessionId))).get();
    if (existingRecords.isNotEmpty) return;

    final snapshots = <String, StudentSnapshot>{};
    for (final entry in statusMap.entries) {
      if (entry.value != AttendanceStatus.present &&
          entry.value != AttendanceStatus.absent &&
          entry.value != AttendanceStatus.onDuty) {
        throw InvalidStatusException(entry.key, entry.value.name);
      }
      final snap = await _studentRepo.getStudentSnapshot(entry.key);
      snapshots[entry.key] = snap;
    }

    int pCount = 0, aCount = 0, oCount = 0;
    final recordCompanions = <AttendanceRecordsTableCompanion>[];
    final recordSyncEntries = <SyncQueueTableCompanion>[];
    final now = DateTime.now();

    for (final entry in statusMap.entries) {
      if (entry.value == AttendanceStatus.present) {
        pCount++;
      } else if (entry.value == AttendanceStatus.absent) {
        aCount++;
      } else if (entry.value == AttendanceStatus.onDuty) {
        oCount++;
      }

      final snap = snapshots[entry.key]!;
      String sName = snap.name.trim();
      String sRoll = snap.rollNumber.trim();
      if (sName.isEmpty || sRoll.isEmpty) {
        sName = sName.isEmpty ? 'Student ${snap.rollNumber}' : sName;
        sRoll = sRoll.isEmpty ? '?' : sRoll;
        debugPrint(
          '[SNAPSHOT_WARN] Student ${entry.key} has empty name or roll. Using fallback.',
        );
      }

      final rId = const Uuid().v4();

      recordCompanions.add(
        AttendanceRecordsTableCompanion.insert(
          id: rId,
          sessionId: sessionId,
          studentId: entry.key,
          classroomId: classroomId,
          status: Value(entry.value.name),
          snapshotName: sName,
          snapshotRoll: sRoll,
          markedAt: now,
        ),
      );
      recordSyncEntries.add(
        SyncQueueTableCompanion.insert(
          id: 'record:$rId',
          entityType: 'record',
          entityId: rId,
          operation: const Value('upsert'),
          enqueuedAt: now,
          groupKey: Value('session:$sessionId'),
        ),
      );
    }

    await _db.writeAndEnqueue(
      () async {
        await _db.insertRecordsBatch(recordCompanions);

        await (_db.update(
          _db.attendanceSessionsTable,
        )..where((t) => t.id.equals(sessionId))).write(
          AttendanceSessionsTableCompanion(
            presentCount: Value(pCount),
            absentCount: Value(aCount),
            onDutyCount: Value(oCount),
          ),
        );

        await (_db.update(_db.classroomsTable)
              ..where((t) => t.id.equals(classroomId)))
            .write(ClassroomsTableCompanion(updatedAt: Value(DateTime.now())));
      },
      [
        ...recordSyncEntries,
        SyncQueueTableCompanion.insert(
          id: 'session:$sessionId',
          entityType: 'session',
          entityId: sessionId,
          operation: const Value('upsert'),
          enqueuedAt: DateTime.now(),
          groupKey: Value('session:$sessionId'),
        ),
        SyncQueueTableCompanion.insert(
          id: 'classroom:$classroomId',
          entityType: 'classroom',
          entityId: classroomId,
          operation: const Value('upsert'),
          enqueuedAt: DateTime.now(),
        ),
      ],
    );
  }

  Future<void> updateSessionRecords(
    String sessionId,
    String classroomId,
    Map<String, AttendanceStatus> newStatusMap,
  ) async {
    final validIds = await _db.getSameClassroomStudentIds(classroomId);
    for (final id in newStatusMap.keys) {
      if (!validIds.contains(id)) {
        throw Exception(
          "Student $id does not belong to classroom $classroomId",
        );
      }
    }

    final existingRecords = await (_db.select(
      _db.attendanceRecordsTable,
    )..where((t) => t.sessionId.equals(sessionId))).get();

    final existingStatusMap = <String, AttendanceRecord>{};
    for (final r in existingRecords) {
      existingStatusMap[r.studentId] = r;
    }

    // Prefetch snapshots for any missing record students beforehand
    final missingSnapshots = <String, StudentSnapshot>{};
    for (final entry in newStatusMap.entries) {
      final existingRecord = existingStatusMap[entry.key];
      if (existingRecord == null) {
        final snap = await _studentRepo.getStudentSnapshot(entry.key);
        missingSnapshots[entry.key] = snap;
      }
    }

    final recordSyncEntries = <SyncQueueTableCompanion>[];
    int pCount = 0, aCount = 0, oCount = 0;

    await _db.writeAndEnqueue(() async {
      for (final entry in newStatusMap.entries) {
        if (entry.value == AttendanceStatus.present) {
          pCount++;
        } else if (entry.value == AttendanceStatus.absent) {
          aCount++;
        } else if (entry.value == AttendanceStatus.onDuty) {
          oCount++;
        }

        final existingRecord = existingStatusMap[entry.key];
        if (existingRecord != null) {
          if (existingRecord.status != entry.value.name) {
            // Update record
            await (_db.update(
              _db.attendanceRecordsTable,
            )..where((t) => t.id.equals(existingRecord.id))).write(
              AttendanceRecordsTableCompanion(
                status: Value(entry.value.name),
                markedAt: Value(DateTime.now()),
              ),
            );

            // Queue sync
            recordSyncEntries.add(
              SyncQueueTableCompanion.insert(
                id: 'record:${existingRecord.id}',
                entityType: 'record',
                entityId: existingRecord.id,
                operation: const Value('upsert'),
                enqueuedAt: DateTime.now(),
                groupKey: Value('session:$sessionId'),
              ),
            );
          }
        } else {
          // Fallback if student was added to class after session was created
          // It's an edge case, we can insert a new record for them
          final snap = missingSnapshots[entry.key]!;
          final rId = const Uuid().v4();
          await _db
              .into(_db.attendanceRecordsTable)
              .insert(
                AttendanceRecordsTableCompanion.insert(
                  id: rId,
                  sessionId: sessionId,
                  studentId: entry.key,
                  classroomId: classroomId,
                  status: Value(entry.value.name),
                  snapshotName: snap.name.isNotEmpty
                      ? snap.name.trim()
                      : 'Student ${snap.rollNumber}',
                  snapshotRoll: snap.rollNumber.isNotEmpty
                      ? snap.rollNumber.trim()
                      : '?',
                  markedAt: DateTime.now(),
                ),
              );
          recordSyncEntries.add(
            SyncQueueTableCompanion.insert(
              id: 'record:$rId',
              entityType: 'record',
              entityId: rId,
              operation: const Value('upsert'),
              enqueuedAt: DateTime.now(),
              groupKey: Value('session:$sessionId'),
            ),
          );
        }
      }

      // Update Session counts
      await (_db.update(
        _db.attendanceSessionsTable,
      )..where((t) => t.id.equals(sessionId))).write(
        AttendanceSessionsTableCompanion(
          presentCount: Value(pCount),
          absentCount: Value(aCount),
          onDutyCount: Value(oCount),
          updatedAt: Value(DateTime.now()),
        ),
      );

      // Re-enqueue session
      recordSyncEntries.add(
        SyncQueueTableCompanion.insert(
          id: 'session:$sessionId',
          entityType: 'session',
          entityId: sessionId,
          operation: const Value('upsert'),
          enqueuedAt: DateTime.now(),
          groupKey: Value('session:$sessionId'),
        ),
      );
    }, recordSyncEntries);
  }

  Future<Result<void>> updateSessionLabel(
    String sessionId,
    String classroomId,
    String newLabel,
  ) async {
    try {
      final session =
          await (_db.select(_db.attendanceSessionsTable)..where(
                (t) =>
                    t.id.equals(sessionId) & t.classroomId.equals(classroomId),
              ))
              .getSingleOrNull();
      if (session == null) {
        return Result.failure(Exception('Session not found'));
      }

      final normalizedDate = DateNormalizer.normalizeToMidnightUtc(
        session.date,
      );
      final conflict =
          await (_db.select(_db.attendanceSessionsTable)
                ..where((t) => t.classroomId.equals(classroomId))
                ..where((t) => t.date.equals(normalizedDate))
                ..where((t) => t.label.equals(newLabel))
                ..where((t) => t.isDeleted.equals(false))
                ..where((t) => t.id.equals(sessionId).not()))
              .getSingleOrNull();

      if (conflict != null) {
        return Result.failure(DuplicateSessionException(conflict.id));
      }

      await _db.writeAndEnqueue(
        () =>
            (_db.update(_db.attendanceSessionsTable)..where(
                  (t) =>
                      t.id.equals(sessionId) &
                      t.classroomId.equals(classroomId),
                ))
                .write(
                  AttendanceSessionsTableCompanion(
                    label: Value(newLabel),
                    updatedAt: Value(DateTime.now()),
                  ),
                ),
        [
          SyncQueueTableCompanion.insert(
            id: 'session:$sessionId',
            entityType: 'session',
            entityId: sessionId,
            operation: const Value('upsert'),
            enqueuedAt: DateTime.now(),
          ),
        ],
      );
      return const Result.success(null);
    } catch (e, st) {
      return Result.failure(e, st);
    }
  }

  Future<Result<void>> updateRecord(
    String sessionId,
    String studentId,
    AttendanceStatus status,
  ) async {
    try {
      final now = DateTime.now();
      final record =
          await (_db.select(_db.attendanceRecordsTable)..where(
                (t) =>
                    t.sessionId.equals(sessionId) &
                    t.studentId.equals(studentId),
              ))
              .getSingleOrNull();

      if (record == null) return Result.failure(Exception('Record not found'));

      await _db.writeAndEnqueue(
        () =>
            (_db.update(
              _db.attendanceRecordsTable,
            )..where((t) => t.id.equals(record.id))).write(
              AttendanceRecordsTableCompanion(
                status: Value(status.name),
                markedAt: Value(now),
              ),
            ),
        [
          SyncQueueTableCompanion.insert(
            id: 'record:${record.id}',
            entityType: 'record',
            entityId: record.id,
            operation: const Value('upsert'),
            enqueuedAt: now,
            groupKey: Value('session:$sessionId'),
          ),
          SyncQueueTableCompanion.insert(
            id: 'session:$sessionId',
            entityType: 'session',
            entityId: sessionId,
            operation: const Value('upsert'),
            enqueuedAt: now,
            groupKey: Value('session:$sessionId'),
          ),
        ],
      );
      return const Result.success(null);
    } catch (e, st) {
      return Result.failure(e, st);
    }
  }

  /// Updates [studentIds] records in [sessionId] to [status] in a single SQL
  /// batch (WHERE session_id = ? AND student_id IN (?,...)).
  ///
  /// Complexity: O(1) DB round-trips regardless of student count, replacing the
  /// previous O(n) per-student SELECT+UPDATE loop.
  Future<Result<void>> updateBulkRecords(
    String sessionId,
    List<String> studentIds,
    AttendanceStatus status,
  ) async {
    if (studentIds.isEmpty) return const Result.success(null);
    try {
      final now = DateTime.now();

      await _db.transaction(() async {
        // Single batch update — WHERE session_id = ? AND student_id IN (...)
        await (_db.update(_db.attendanceRecordsTable)
              ..where(
                (t) =>
                    t.sessionId.equals(sessionId) &
                    t.studentId.isIn(studentIds),
              ))
            .write(
              AttendanceRecordsTableCompanion(
                status: Value(status.name),
                markedAt: Value(now),
              ),
            );

        // Derive counts from ground truth (single COUNT aggregate) instead
        // of tracking them manually — guarantees ACID consistency.
        await _db.recalculateSessionCounts(sessionId);
      });

      return const Result.success(null);
    } catch (e, st) {
      return Result.failure(e, st);
    }
  }

  Future<void> restoreSession(String sessionId, String classroomId) async {
    final session =
        await (_db.select(_db.attendanceSessionsTable)..where(
              (t) => t.id.equals(sessionId) & t.classroomId.equals(classroomId),
            ))
            .getSingleOrNull();
    if (session == null) return;

    final originalLabel = session.label.replaceAll(RegExp(r'_del_\d+$'), '');

    final conflict =
        await (_db.select(_db.attendanceSessionsTable)
              ..where((t) => t.classroomId.equals(classroomId))
              ..where((t) => t.date.equals(session.date))
              ..where((t) => t.label.equals(originalLabel))
              ..where((t) => t.isDeleted.equals(false)))
            .getSingleOrNull();

    if (conflict != null) {
      throw Exception(
        'Cannot restore: A session with label "$originalLabel" already exists on this date.',
      );
    }

    await _db.writeAndEnqueue(
      () =>
          (_db.update(_db.attendanceSessionsTable)..where(
                (t) =>
                    t.id.equals(sessionId) & t.classroomId.equals(classroomId),
              ))
              .write(
                AttendanceSessionsTableCompanion(
                  isDeleted: const Value(false),
                  label: Value(originalLabel),
                  deletedAt: const Value(null),
                  updatedAt: Value(DateTime.now()),
                ),
              ),
      [
        SyncQueueTableCompanion.insert(
          id: 'session:$sessionId',
          entityType: 'session',
          entityId: sessionId,
          operation: const Value('upsert'),
          enqueuedAt: DateTime.now(),
        ),
      ],
    );
  }

  Stream<List<SessionSummary>> watchDeletedSessions(String classroomId) {
    return _db.watchDeletedSessionsByClassroom(classroomId).asyncMap((
      sessions,
    ) async {
      return sessions
          .map(
            (session) => SessionSummary(
              sessionId: session.id,
              date: session.date,
              label: session.label,
              presentCount: session.presentCount,
              absentCount: session.absentCount,
              onDutyCount: session.onDutyCount,
              syncStatus: 'synced',
            ),
          )
          .toList();
    });
  }

  Future<void> deleteSession(String sessionId, String classroomId) async {
    final session =
        await (_db.select(_db.attendanceSessionsTable)..where(
              (t) => t.id.equals(sessionId) & t.classroomId.equals(classroomId),
            ))
            .getSingleOrNull();
    if (session == null) return;

    final deletedLabel =
        '${session.label}_del_${DateTime.now().millisecondsSinceEpoch}';

    await _db.writeAndEnqueue(
      () async {
        await (_db.update(_db.attendanceSessionsTable)..where(
              (t) => t.id.equals(sessionId) & t.classroomId.equals(classroomId),
            ))
            .write(
              AttendanceSessionsTableCompanion(
                isDeleted: const Value(true),
                label: Value(deletedLabel),
                deletedAt: Value(DateTime.now()),
                updatedAt: Value(DateTime.now()),
              ),
            );

        // Update classroom lastSessionAt cache to the previous session
        final lastRemaining =
            await (_db.select(_db.attendanceSessionsTable)
                  ..where(
                    (t) =>
                        t.classroomId.equals(classroomId) &
                        t.isDeleted.equals(false) &
                        t.id.equals(sessionId).not(),
                  )
                  ..orderBy([
                    (t) => OrderingTerm(
                      expression: t.date,
                      mode: OrderingMode.desc,
                    ),
                  ])
                  ..limit(1))
                .getSingleOrNull();

        await (_db.update(
          _db.classroomsTable,
        )..where((t) => t.id.equals(classroomId))).write(
          ClassroomsTableCompanion(
            lastSessionAt: Value(lastRemaining?.date),
            updatedAt: Value(DateTime.now()),
          ),
        );

        // Remove any pending sync entries for this session's records (optional, but keep for clean sync queue)
        await (_db.delete(
          _db.syncQueueTable,
        )..where((t) => t.entityId.equals(sessionId))).go();
      },
      [
        SyncQueueTableCompanion.insert(
          id: 'session:$sessionId',
          entityType: 'session',
          entityId: sessionId,
          operation: const Value('delete'),
          enqueuedAt: DateTime.now(),
        ),
      ],
    );
  }

  Stream<List<SessionSummary>> watchSessionsWithSummary(
    String classroomId, {
    int limit = 60,
  }) {
    return _db.watchSessionsByClassroom(classroomId, limit: limit).asyncMap((
      sessions,
    ) async {
      return sessions
          .map(
            (session) => SessionSummary(
              sessionId: session.id,
              date: session.date,
              label: session.label,
              presentCount: session.presentCount,
              absentCount: session.absentCount,
              onDutyCount: session.onDutyCount,
              syncStatus: 'synced',
            ),
          )
          .toList();
    });
  }

  Future<List<SessionSummary>> getSessionsForClassroomPage(
    String classroomId,
    int offset, {
    int limit = 60,
  }) async {
    final sessions = await _db.getSessionsForClassroomPage(
      classroomId,
      offset,
      limit: limit,
    );
    return sessions
        .map(
          (session) => SessionSummary(
            sessionId: session.id,
            date: session.date,
            label: session.label,
            presentCount: session.presentCount,
            absentCount: session.absentCount,
            onDutyCount: session.onDutyCount,
            syncStatus: 'synced',
          ),
        )
        .toList();
  }

  /// T 6.3 — Cursor-based pagination for the History Tab.
  /// [cursor] is the date of the last loaded session (exclusive).
  /// Pass null for the first page (loads the most recent sessions).
  Future<List<SessionDateGroup>> getSessionsPage(
    String classroomId, {
    DateTime? cursor,
    int limit = 20,
  }) async {
    final sessions = await _db.getSessionsPageCursor(
      classroomId,
      cursor: cursor,
      limit: limit,
    );
    final summaries = sessions.map(
      (s) => SessionSummary(
        sessionId: s.id,
        date: s.date,
        label: s.label,
        presentCount: s.presentCount,
        absentCount: s.absentCount,
        onDutyCount: s.onDutyCount,
        syncStatus: 'synced',
      ),
    );

    // Group by date
    final Map<String, List<SessionSummary>> grouped = {};
    for (final s in summaries) {
      final key =
          '${s.date.year}-${s.date.month.toString().padLeft(2, '0')}-${s.date.day.toString().padLeft(2, '0')}';
      grouped.putIfAbsent(key, () => []).add(s);
    }
    final seen = <String>{};
    final groups = <SessionDateGroup>[];
    for (final s in summaries) {
      final key =
          '${s.date.year}-${s.date.month.toString().padLeft(2, '0')}-${s.date.day.toString().padLeft(2, '0')}';
      if (!seen.contains(key)) {
        seen.add(key);
        groups.add(SessionDateGroup(date: s.date, sessions: grouped[key]!));
      }
    }
    return groups;
  }

  /// Groups sessions by date (newest first).

  Stream<List<SessionDateGroup>> watchSessionsGroupedByDate(
    String classroomId,
  ) {
    return watchSessionsWithSummary(classroomId).map((summaries) {
      final Map<String, List<SessionSummary>> grouped = {};
      for (final s in summaries) {
        final key =
            '${s.date.year}-${s.date.month.toString().padLeft(2, '0')}-${s.date.day.toString().padLeft(2, '0')}';
        grouped.putIfAbsent(key, () => []).add(s);
      }
      final seen = <String>{};
      final groups = <SessionDateGroup>[];
      for (final s in summaries) {
        final key =
            '${s.date.year}-${s.date.month.toString().padLeft(2, '0')}-${s.date.day.toString().padLeft(2, '0')}';
        if (!seen.contains(key)) {
          seen.add(key);
          groups.add(SessionDateGroup(date: s.date, sessions: grouped[key]!));
        }
      }
      return groups;
    });
  }

  Future<AttendanceSession?> getSessionById(String sessionId) =>
      _db.getSessionById(sessionId);

  Future<DateTime?> getLastSessionDateForClassroom(String classroomId) async {
    final session =
        await (_db.select(_db.attendanceSessionsTable)
              ..where(
                (t) => t.classroomId.equals(classroomId) & t.deletedAt.isNull(),
              )
              ..orderBy([
                (t) =>
                    OrderingTerm(expression: t.date, mode: OrderingMode.desc),
              ])
              ..limit(1))
            .getSingleOrNull();
    return session?.date;
  }

  Future<List<RecordWithStudent>> getRecordsForSession(String sessionId) async {
    final records = await _db.getRecordsBySession(sessionId);

    final result = <RecordWithStudent>[];
    for (final r in records) {
      AttendanceStatus statusEnum;
      if (r.status == AttendanceStatus.present.name) {
        statusEnum = AttendanceStatus.present;
      } else if (r.status == AttendanceStatus.absent.name) {
        statusEnum = AttendanceStatus.absent;
      } else {
        statusEnum = AttendanceStatus.onDuty;
      }

      result.add(
        RecordWithStudent(
          recordId: r.id,
          studentId: r.studentId,
          studentName: r.snapshotName,
          rollNumber: r.snapshotRoll,
          status: statusEnum,
        ),
      );
    }

    result.sort((a, b) => a.rollNumber.compareTo(b.rollNumber));
    return result;
  }
}
