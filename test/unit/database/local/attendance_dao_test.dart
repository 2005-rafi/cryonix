import 'package:cryonix/core/constants/domain_enums.dart';
import 'package:cryonix/database/app_database.dart';
import 'package:cryonix/features/classroom/repository/classroom_repository.dart';
import 'package:cryonix/features/auth/repository/i_auth_repository.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/builders/test_data_builder.dart';
import '../../../helpers/test_database.dart';

class _DummyAuthRepository implements IAuthRepository {
  @override
  User? get currentUser => const User(uid: 'uid-1', emailVerified: true);
  @override
  Stream<User?> get authStateChanges => Stream.value(currentUser);
  @override
  Future<UserCredential> signInWithEmail(String email, String password) => throw UnimplementedError();
  @override
  Future<UserCredential> registerWithEmail(String email, String password, String displayName) => throw UnimplementedError();
  @override
  Future<void> sendVerificationEmail() => throw UnimplementedError();
  @override
  Future<bool> reloadAndCheckVerification() async => true;
  @override
  Future<UserCredential> signInWithGoogle() => throw UnimplementedError();
  @override
  Future<void> signOut() => throw UnimplementedError();
  @override
  Future<void> reauthenticateWithPassword(String password) => throw UnimplementedError();
  @override
  Future<void> reauthenticateWithGoogle() => throw UnimplementedError();
}

void main() {
  late AppDatabase db;
  const classroomId = 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa';

  setUp(() {
    db = createTestDatabase();
  });

  tearDown(() async {
    await db.close();
  });

  Future<void> seedClassroomWithStudents(int count) async {
    await db.insertClassroom(buildTestClassroom(id: classroomId));
    for (var i = 0; i < count; i++) {
      await db.insertStudent(
        buildTestStudent(
          id: 'student_${i}_12345678901234567890123456',
          classroomId: classroomId,
          rollNumber: '${i + 1}'.padLeft(2, '0'),
          name: 'Student $i',
        ),
      );
    }
  }

  test('session save updates record status and counts', () async {
    await seedClassroomWithStudents(3);
    const sessionId = 'session_1_12345678901234567890123456';
    final date = DateTime.utc(2026, 5, 15);
    await db.insertSession(
      buildTestSession(id: sessionId, classroomId: classroomId, date: date),
    );
    final students = await db.getActiveStudentsByClassroom(classroomId);
    final records = <AttendanceRecordsTableCompanion>[];
    const recordIds = [
      '00000001-aaaa-aaaa-aaaa-aaaaaaaaaaaa',
      '00000002-aaaa-aaaa-aaaa-aaaaaaaaaaaa',
      '00000003-aaaa-aaaa-aaaa-aaaaaaaaaaaa',
    ];
    for (var i = 0; i < students.length; i++) {
      final s = students[i];
      records.add(
        buildTestRecord(
          id: recordIds[i],
          sessionId: sessionId,
          studentId: s.id,
          classroomId: classroomId,
          status: i == 0
              ? AttendanceStatus.present.name
              : AttendanceStatus.absent.name,
        ),
      );
    }
    await db.insertRecordsBatch(records);
    await db.recalculateSessionCounts(sessionId);
    final session = await db.getSessionById(sessionId);
    expect(session?.presentCount, 1);
    expect(session?.absentCount, 2);
  });

  test('unique session per classroom date and label', () async {
    await seedClassroomWithStudents(1);
    final date = DateTime.utc(2026, 5, 15);
    await db.insertSession(
      buildTestSession(
        id: 'session_1_12345678901234567890123456',
        classroomId: classroomId,
        date: date,
      ),
    );
    expect(
      () => db.insertSession(
        buildTestSession(
          id: 'session_2_12345678901234567890123456',
          classroomId: classroomId,
          date: date,
        ),
      ),
      throwsA(isA<Exception>()),
    );
  });

  test('sessions ordered most recent first', () async {
    await seedClassroomWithStudents(1);
    await db.insertSession(
      buildTestSession(
        id: 'session_1_12345678901234567890123456',
        classroomId: classroomId,
        date: DateTime.utc(2026, 5, 1),
      ),
    );
    await db.insertSession(
      buildTestSession(
        id: 'session_2_12345678901234567890123456',
        classroomId: classroomId,
        date: DateTime.utc(2026, 5, 3),
      ),
    );
    await db.insertSession(
      buildTestSession(
        id: 'session_3_12345678901234567890123456',
        classroomId: classroomId,
        date: DateTime.utc(2026, 5, 2),
      ),
    );
    final sessions = await db.watchSessionsByClassroom(classroomId).first;
    expect(sessions.first.date.toUtc(), DateTime.utc(2026, 5, 3));
    expect(sessions.last.date.toUtc(), DateTime.utc(2026, 5, 1));
  });

  test('snapshot fields populated on records', () async {
    await seedClassroomWithStudents(1);
    const sessionId = 'session_1_12345678901234567890123456';
    await db.insertSession(
      buildTestSession(id: sessionId, classroomId: classroomId),
    );
    await db.insertRecordsBatch([
      buildTestRecord(
        id: 'record_1_123456789012345678901234567',
        sessionId: sessionId,
        studentId: 'student_0_12345678901234567890123456',
        classroomId: classroomId,
        status: 'present',
      ),
    ]);
    final records = await db.getRecordsBySession(sessionId);
    expect(records.first.snapshotName, isNotEmpty);
    expect(records.first.snapshotRoll, isNotEmpty);
  });

  test('cascade delete removes related rows', () async {
    await seedClassroomWithStudents(2);
    const sessionId = 'session_1_12345678901234567890123456';
    await db.insertSession(
      buildTestSession(id: sessionId, classroomId: classroomId),
    );
    await db.insertRecordsBatch([
      buildTestRecord(
        id: 'record_1_123456789012345678901234567',
        sessionId: sessionId,
        studentId: 'student_0_12345678901234567890123456',
        classroomId: classroomId,
      ),
      buildTestRecord(
        id: 'record_2_123456789012345678901234567',
        sessionId: sessionId,
        studentId: 'student_1_12345678901234567890123456',
        classroomId: classroomId,
      ),
    ]);
    await ClassroomRepository(db, auth: _DummyAuthRepository()).deleteClassroom(classroomId);
    expect(await db.select(db.studentsTable).get(), isEmpty);
    expect(await db.select(db.attendanceSessionsTable).get(), isEmpty);
    expect(await db.select(db.attendanceRecordsTable).get(), isEmpty);
  });
}
