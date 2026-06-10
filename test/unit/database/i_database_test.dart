import 'package:flutter_test/flutter_test.dart';
import 'package:cryonix/core/i_database.dart';
import 'package:cryonix/database/app_database.dart';

/// A minimal in-memory [FakeDatabase] that implements [IDatabase].
/// Demonstrates the interface is correctly specified and usable outside Drift.
class FakeDatabase implements IDatabase {
  final Map<String, Classroom> _classrooms = {};
  final Map<String, Student> _students = {};
  final Map<String, AttendanceSession> _sessions = {};
  final Map<String, AttendanceRecord> _records = {};

  @override
  Future<void> insertClassroom(ClassroomsTableCompanion companion) async {
    _classrooms[companion.id.value] = Classroom(
      id: companion.id.value,
      userId: companion.userId.value,
      name: companion.name.value,
      subject: companion.subject.present ? companion.subject.value : null,
      description:
          companion.description.present ? companion.description.value : null,
      studentCount:
          companion.studentCount.present ? companion.studentCount.value : 0,
      createdAt: companion.createdAt.value,
      updatedAt: companion.updatedAt.value,
      syncVersion: 0,
    );
  }

  @override
  Future<bool> checkIfClassroomExists(String classroomId) async =>
      _classrooms.containsKey(classroomId);

  @override
  Future<int> batchInsertClassrooms(
      List<ClassroomsTableCompanion> companions) async {
    var insertedCount = 0;
    for (final companion in companions) {
      if (_classrooms.containsKey(companion.id.value)) continue;
      await insertClassroom(companion);
      insertedCount++;
    }
    return insertedCount;
  }

  @override
  Stream<List<Classroom>> watchClassrooms(String userId) =>
      Stream.value(_classrooms.values
          .where((c) => c.userId == userId)
          .toList());

  @override
  Future<Classroom?> getClassroomById(String id) async =>
      _classrooms[id];

  @override
  Future<void> updateClassroom(
      String id, String name, String subject, String? description) async {
    final existing = _classrooms[id];
    if (existing == null) return;
    _classrooms[id] = Classroom(
      id: existing.id,
      userId: existing.userId,
      name: name,
      subject: subject,
      description: description,
      studentCount: existing.studentCount,
      createdAt: existing.createdAt,
      updatedAt: DateTime.now(),
      syncVersion: existing.syncVersion,
    );
  }

  @override
  Future<void> incrementStudentCount(String classroomId, {int by = 1}) async {}

  @override
  Future<void> decrementStudentCount(String classroomId, {int by = 1}) async {}

  @override
  Future<void> recalculateStudentCount(String classroomId) async {}

  @override
  Future<void> insertStudent(StudentsTableCompanion companion) async {
    _students[companion.id.value] = Student(
      id: companion.id.value,
      classroomId: companion.classroomId.value,
      name: companion.name.value,
      rollNumber: companion.rollNumber.value,
      isActive: companion.isActive.present ? companion.isActive.value : true,
      enrolledAt: companion.enrolledAt.value,
      deletedAt:
          companion.deletedAt.present ? companion.deletedAt.value : null,
      createdAt: companion.createdAt.value,
      updatedAt: companion.updatedAt.value,
      syncVersion: 0,
    );
  }

  @override
  Future<bool> checkIfStudentExists(String studentId) async =>
      _students.containsKey(studentId);

  @override
  Future<void> insertStudentsBatch(
      List<StudentsTableCompanion> companions) async {
    await batchInsertStudents(companions);
  }

  @override
  Future<int> batchInsertStudents(
      List<StudentsTableCompanion> companions) async {
    var insertedCount = 0;
    for (final companion in companions) {
      final existsById = _students.containsKey(companion.id.value);
      final existsByUnique = _students.values.any(
        (student) =>
            student.classroomId == companion.classroomId.value &&
            student.rollNumber == companion.rollNumber.value,
      );
      if (existsById || existsByUnique) continue;
      await insertStudent(companion);
      insertedCount++;
    }
    return insertedCount;
  }

  @override
  Stream<List<Student>> watchActiveStudentsByClassroom(String classroomId) =>
      Stream.value(_students.values
          .where((s) => s.classroomId == classroomId && s.isActive)
          .toList());

  @override
  Future<List<Student>> getActiveStudentsByClassroom(String classroomId) async =>
      _students.values
          .where((s) => s.classroomId == classroomId && s.isActive)
          .toList();

  @override
  Future<void> updateStudent(String id, String rollNumber, String name) async {}

  @override
  Future<void> softDeleteStudent(String id, String classroomId) async {
    final s = _students[id];
    if (s != null) {
      _students[id] = Student(
        id: s.id,
        classroomId: s.classroomId,
        name: s.name,
        rollNumber: s.rollNumber,
        isActive: false,
        enrolledAt: s.enrolledAt,
        deletedAt: DateTime.now(),
        createdAt: s.createdAt,
        updatedAt: DateTime.now(),
        syncVersion: s.syncVersion,
      );
    }
  }

  @override
  Future<void> insertSession(AttendanceSessionsTableCompanion companion) async {
    _sessions[companion.id.value] = AttendanceSession(
      id: companion.id.value,
      classroomId: companion.classroomId.value,
      date: companion.date.value,
      totalStudents:
          companion.totalStudents.present ? companion.totalStudents.value : 0,
      presentCount:
          companion.presentCount.present ? companion.presentCount.value : 0,
      absentCount:
          companion.absentCount.present ? companion.absentCount.value : 0,
      onDutyCount:
          companion.onDutyCount.present ? companion.onDutyCount.value : 0,
      label: companion.label.present ? companion.label.value : 'Full Day',
      isDeleted: companion.isDeleted.present ? companion.isDeleted.value : false,
      deletedAt:
          companion.deletedAt.present ? companion.deletedAt.value : null,
      createdAt: companion.createdAt.value,
      updatedAt: companion.updatedAt.value,
      syncVersion: 0,
    );
  }

  @override
  Future<int> batchInsertSessions(
      List<AttendanceSessionsTableCompanion> companions) async {
    var insertedCount = 0;
    for (final companion in companions) {
      final label = companion.label.present ? companion.label.value : 'Full Day';
      final existsById = _sessions.containsKey(companion.id.value);
      final existsByUnique = _sessions.values.any(
        (session) =>
            session.classroomId == companion.classroomId.value &&
            session.date == companion.date.value &&
            session.label == label,
      );
      if (existsById || existsByUnique) continue;
      await insertSession(companion);
      insertedCount++;
    }
    return insertedCount;
  }

  @override
  Future<AttendanceSession?> getSessionById(String sessionId) async =>
      _sessions[sessionId];

  @override
  Stream<List<AttendanceSession>> watchSessionsByClassroom(String classroomId,
          {int limit = 60}) =>
      Stream.value(_sessions.values
          .where((session) => session.classroomId == classroomId)
          .where((session) => !session.isDeleted)
          .take(limit)
          .toList());

  @override
  Future<List<AttendanceSession>> getSessionsPageCursor(String classroomId,
          {DateTime? cursor, int limit = 20}) async =>
      _sessions.values
          .where((session) => session.classroomId == classroomId)
          .where((session) => !session.isDeleted)
          .where((session) => cursor == null || session.date.isBefore(cursor))
          .take(limit)
          .toList();

  @override
  Future<void> recalculateSessionCounts(String sessionId) async {}

  @override
  Future<void> reconcileRecentSessionCounts() async {}

  @override
  Future<void> insertRecordsBatch(
      List<AttendanceRecordsTableCompanion> companions) async {
    await batchInsertRecords(companions);
  }

  @override
  Future<int> batchInsertRecords(
      List<AttendanceRecordsTableCompanion> companions) async {
    var insertedCount = 0;
    for (final companion in companions) {
      final existsById = _records.containsKey(companion.id.value);
      final existsByUnique = _records.values.any(
        (record) =>
            record.sessionId == companion.sessionId.value &&
            record.studentId == companion.studentId.value,
      );
      if (existsById || existsByUnique) continue;
      _records[companion.id.value] = AttendanceRecord(
        id: companion.id.value,
        sessionId: companion.sessionId.value,
        studentId: companion.studentId.value,
        classroomId: companion.classroomId.value,
        status: companion.status.value,
        snapshotName: companion.snapshotName.value,
        snapshotRoll: companion.snapshotRoll.value,
        markedAt: companion.markedAt.value,
        syncVersion: 0,
      );
      insertedCount++;
    }
    return insertedCount;
  }

  @override
  Future<List<AttendanceRecord>> getRecordsBySession(String sessionId) async =>
      _records.values.where((record) => record.sessionId == sessionId).toList();

  @override
  Stream<List<AttendanceRecord>> watchRecordsBySession(String sessionId) =>
      Stream.value(_records.values
          .where((record) => record.sessionId == sessionId)
          .toList());

  @override
  Future<void> enqueueSyncEntry(SyncQueueTableCompanion companion) async {}

  @override
  Future<List<SyncQueueEntry>> getPendingSyncEntries(int limit) async => [];

  @override
  Future<int> getPermanentErrorCount() async => 0;

  @override
  Future<T> writeAndEnqueue<T>(
    Future<T> Function() writeAction,
    List<SyncQueueTableCompanion> syncEntries,
  ) async {
    final result = await writeAction();
    for (final entry in syncEntries) {
      await enqueueSyncEntry(entry);
    }
    return result;
  }

  @override
  Future<void> markSyncInProgress(String id, String sessionId) async {}

  @override
  Future<void> markSyncFailed(String id, {bool isTransient = true}) async {}

  @override
  Future<void> deleteSyncEntry(String id) async {}

  @override
  Future<int> resetStaleInProgress([String? currentSessionId]) async => 0;

  @override
  Future<String?> getLastDownloadedAt(String collectionKey) async => null;

  @override
  Future<void> setLastDownloadedAt(
    String collectionKey,
    String lastDownloadedAt,
  ) async {}

  @override
  Future<List<AttendanceRecord>> getStudentAttendanceSummary(
          String studentId, String classroomId, DateTime enrolledAt) async =>
      [];

  @override
  Future<void> close() async {}
}

void main() {
  group('IDatabase interface contract', () {
    late FakeDatabase db;

    setUp(() {
      db = FakeDatabase();
    });

    test('FakeDatabase compiles and fulfills IDatabase contract', () {
      expect(db, isA<IDatabase>());
    });

    test('insertClassroom and watchClassrooms work correctly', () async {
      final companion = ClassroomsTableCompanion.insert(
        id: 'cr1',
        userId: 'user1',
        name: 'Math',
        createdAt: DateTime(2026),
        updatedAt: DateTime(2026),
      );
      await db.insertClassroom(companion);
      final stream = db.watchClassrooms('user1');
      final classrooms = await stream.first;
      expect(classrooms.length, 1);
      expect(classrooms.first.name, 'Math');
    });

    test('getClassroomById returns null for missing id', () async {
      expect(await db.getClassroomById('nonexistent'), isNull);
    });

    test('close completes without error', () async {
      await expectLater(db.close(), completes);
    });
  });
}
