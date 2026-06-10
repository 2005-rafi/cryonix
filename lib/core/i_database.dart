import '../database/app_database.dart';

/// The database contract exposed to feature repositories.
///
/// By coding against [IDatabase] instead of [AppDatabase] directly, features
/// become independent of the Drift ORM. In unit tests a [FakeDatabase]
/// implementation that uses in-memory maps can be substituted with no Drift
/// involvement needed.
abstract class IDatabase {
  // ── Classroom operations ─────────────────────────────────────────────────

  Future<void> insertClassroom(ClassroomsTableCompanion companion);

  Future<bool> checkIfClassroomExists(String classroomId);

  Future<int> batchInsertClassrooms(List<ClassroomsTableCompanion> companions);

  Stream<List<Classroom>> watchClassrooms(String userId);

  Future<Classroom?> getClassroomById(String id);

  Future<void> updateClassroom(
      String id, String name, String subject, String? description);

  Future<void> incrementStudentCount(String classroomId, {int by = 1});

  Future<void> decrementStudentCount(String classroomId, {int by = 1});

  Future<void> recalculateStudentCount(String classroomId);

  // ── Student operations ───────────────────────────────────────────────────

  Future<void> insertStudent(StudentsTableCompanion companion);

  Future<bool> checkIfStudentExists(String studentId);

  Future<void> insertStudentsBatch(List<StudentsTableCompanion> companions);

  Future<int> batchInsertStudents(List<StudentsTableCompanion> companions);

  Stream<List<Student>> watchActiveStudentsByClassroom(String classroomId);

  Future<List<Student>> getActiveStudentsByClassroom(String classroomId);

  Future<void> updateStudent(String id, String rollNumber, String name);

  Future<void> softDeleteStudent(String id, String classroomId);

  // ── Session operations ───────────────────────────────────────────────────

  Future<void> insertSession(AttendanceSessionsTableCompanion companion);

  Future<int> batchInsertSessions(
    List<AttendanceSessionsTableCompanion> companions,
  );

  Future<AttendanceSession?> getSessionById(String sessionId);

  Stream<List<AttendanceSession>> watchSessionsByClassroom(String classroomId,
      {int limit = 60});

  Future<List<AttendanceSession>> getSessionsPageCursor(
    String classroomId, {
    DateTime? cursor,
    int limit = 20,
  });

  Future<void> recalculateSessionCounts(String sessionId);

  Future<void> reconcileRecentSessionCounts();

  // ── Record operations ────────────────────────────────────────────────────

  Future<void> insertRecordsBatch(
      List<AttendanceRecordsTableCompanion> companions);

  Future<int> batchInsertRecords(
    List<AttendanceRecordsTableCompanion> companions,
  );

  Future<List<AttendanceRecord>> getRecordsBySession(String sessionId);

  Stream<List<AttendanceRecord>> watchRecordsBySession(String sessionId);

  // ── Sync queue operations ────────────────────────────────────────────────

  Future<T> writeAndEnqueue<T>(
    Future<T> Function() writeAction,
    List<SyncQueueTableCompanion> syncEntries,
  );

  Future<void> enqueueSyncEntry(SyncQueueTableCompanion companion);

  Future<List<SyncQueueEntry>> getPendingSyncEntries(int limit);

  Future<int> getPermanentErrorCount();

  Future<void> markSyncInProgress(String id, String sessionId);

  Future<void> markSyncFailed(String id, {bool isTransient = true});

  Future<void> deleteSyncEntry(String id);

  Future<int> resetStaleInProgress([String? currentSessionId]);

  // ── Sync metadata operations ─────────────────────────────────────────────

  Future<String?> getLastDownloadedAt(String collectionKey);

  Future<void> setLastDownloadedAt(String collectionKey, String lastDownloadedAt);

  // ── Analytics ───────────────────────────────────────────────────────────

  Future<List<AttendanceRecord>> getStudentAttendanceSummary(
    String studentId,
    String classroomId,
    DateTime enrolledAt,
  );

  // ── Lifecycle ───────────────────────────────────────────────────────────

  Future<void> close();
}
