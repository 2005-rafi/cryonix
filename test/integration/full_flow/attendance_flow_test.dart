import 'package:cryonix/core/constants.dart';
import 'package:cryonix/features/auth/repository/i_auth_repository.dart';
import 'package:cryonix/features/attendance/repository/attendance_repository.dart';
import 'package:cryonix/features/classroom/repository/classroom_repository.dart';
import 'package:cryonix/features/classroom/repository/student_repository.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/test_database.dart';

class _MockAuthRepository implements IAuthRepository {
  final String _uid;
  _MockAuthRepository(this._uid);

  @override
  User? get currentUser => User(uid: _uid, emailVerified: true);

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

/// End-to-end data flow: classroom → student → session → present status →
/// re-read from Drift (simulates leaving and reopening attendance).
void main() {
  test('classroom through attendance status persists in database', () async {
    final db = createTestDatabase();
    addTearDown(db.close);

    const uid = 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa';
    final auth = _MockAuthRepository(uid);

    final classroomRepo = ClassroomRepository(db, auth: auth);
    final studentRepo = StudentRepository(db);
    final attendanceRepo = AttendanceRepository(db, studentRepo, auth: auth);

    await classroomRepo.createClassroom('Math 10A', 'Mathematics');
    final classrooms = await db.watchClassrooms(uid).first;
    expect(classrooms.single.name, 'Math 10A');
    final createdClassroomId = classrooms.single.id;

    await studentRepo.addStudent(createdClassroomId, '01', 'Priya');
    final students = await studentRepo.getStudentsByClassroom(createdClassroomId);
    expect(students.single.name, 'Priya');
    expect(students.single.rollNumber, '01');
    final studentId = students.single.id;

    final sessionDate = DateTime.utc(2026, 5, 17);
    final sessionResult = await attendanceRepo.createSession(
      createdClassroomId,
      sessionDate,
    );
    expect(sessionResult.isSuccess, true);
    final sessionId = sessionResult.dataOrNull!;

    await attendanceRepo.saveSessionWithRecords(
      sessionId,
      createdClassroomId,
      {studentId: AttendanceStatus.present},
    );

    var records = await db.getRecordsBySession(sessionId);
    expect(records.length, 1);
    expect(records.single.status, AttendanceStatus.present.name);
    expect(records.single.snapshotName, 'Priya');

    // Re-open: read persisted state from Drift (not in-memory UI state).
    records = await db.getRecordsBySession(sessionId);
    expect(records.single.status, AttendanceStatus.present.name);

    await db.close();
  });
}
