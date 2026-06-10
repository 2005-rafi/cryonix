import 'package:drift/drift.dart';
import 'package:cryonix/database/app_database.dart';

ClassroomsTableCompanion buildTestClassroom({
  String? id,
  String? name,
  String? userId,
  String? subject,
}) {
  return ClassroomsTableCompanion.insert(
    id: id ?? 'classroom_1_123456789012345678901234',
    userId: userId ?? 'user_1',
    name: name ?? 'Test Classroom',
    subject: Value(subject ?? 'Test Subject'),
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
  );
}

StudentsTableCompanion buildTestStudent({
  String? id,
  String? classroomId,
  String? rollNumber,
  String? name,
}) {
  return StudentsTableCompanion.insert(
    id: id ?? 'student_1_12345678901234567890123456',
    classroomId: classroomId ?? 'classroom_1_123456789012345678901234',
    name: name ?? 'Test Student',
    rollNumber: rollNumber ?? '01',
    enrolledAt: DateTime.now(),
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
  );
}

AttendanceSessionsTableCompanion buildTestSession({
  String? id,
  String? classroomId,
  DateTime? date,
}) {
  return AttendanceSessionsTableCompanion.insert(
    id: id ?? 'session_1_12345678901234567890123456',
    classroomId: classroomId ?? 'classroom_1_123456789012345678901234',
    date: date ?? DateTime.now(),
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
  );
}

AttendanceRecordsTableCompanion buildTestRecord({
  String? id,
  String? sessionId,
  String? studentId,
  String? classroomId,
  String status = 'present',
}) {
  return AttendanceRecordsTableCompanion.insert(
    id: id ?? 'record_1_123456789012345678901234567',
    classroomId: classroomId ?? 'classroom_1_123456789012345678901234',
    sessionId: sessionId ?? 'session_1_12345678901234567890123456',
    studentId: studentId ?? 'student_1_12345678901234567890123456',
    status: Value(status),
    markedAt: DateTime.now(),
    snapshotName: 'Test Snapshot',
    snapshotRoll: '01',
  );
}

SyncQueueTableCompanion buildTestSyncQueueEntry({
  String? id,
  String? entityType,
  String? entityId,
  String operation = 'upsert',
}) {
  return SyncQueueTableCompanion.insert(
    id: id ?? 'sync_1_12345678901234567890123456789',
    entityType: entityType ?? 'classroom',
    entityId: entityId ?? 'classroom_1_123456789012345678901234',
    operation: Value(operation),
    enqueuedAt: DateTime.now(),
    status: const Value('pending'),
    retryCount: const Value(0),
    nextRetryAt: const Value(0),
    backoffLevel: const Value(0),
  );
}
