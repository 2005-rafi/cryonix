import 'package:cryonix/database/app_database.dart';
import 'package:cryonix/features/classroom/repository/classroom_repository.dart';
import 'package:cryonix/features/classroom/repository/student_repository.dart';
import 'package:cryonix/features/auth/repository/i_auth_repository.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/builders/test_data_builder.dart';
import '../../../helpers/test_database.dart';

class _DummyAuthRepository implements IAuthRepository {
  @override
  User? get currentUser => const User(uid: 'user_1', emailVerified: true);
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
  late ClassroomRepository classroomRepo;
  late StudentRepository studentRepo;
  const userId = 'user_1';
  const classroomId = 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa';

  setUp(() {
    db = createTestDatabase();
    classroomRepo = ClassroomRepository(db, auth: _DummyAuthRepository());
    studentRepo = StudentRepository(db);
  });

  tearDown(() async {
    await db.close();
  });

  test('watchAll emits inserted classroom', () async {
    await db.insertClassroom(
      buildTestClassroom(id: classroomId, userId: userId, name: 'Physics'),
    );
    final list = await classroomRepo.watchAll(userId).first;
    expect(list.single.name, 'Physics');
  });

  test('student watchAll streams active students', () async {
    await db.insertClassroom(buildTestClassroom(id: classroomId, userId: userId));
    await db.insertStudent(
      buildTestStudent(
        id: 'student_1_12345678901234567890123456',
        classroomId: classroomId,
        rollNumber: '01',
        name: 'Ali',
      ),
    );
    final students = await studentRepo.watchAll(classroomId).first;
    expect(students.length, 1);
    expect(students.first.name, 'Ali');
  });

  test('delete classroom cascades students', () async {
    await db.insertClassroom(buildTestClassroom(id: classroomId, userId: userId));
    await db.insertStudent(
      buildTestStudent(
        id: 'student_1_12345678901234567890123456',
        classroomId: classroomId,
        rollNumber: '01',
      ),
    );
    await db.insertStudent(
      buildTestStudent(
        id: 'student_2_12345678901234567890123456',
        classroomId: classroomId,
        rollNumber: '02',
      ),
    );
    await classroomRepo.delete(classroomId);
    final remaining = await db.getActiveStudentsByClassroom(classroomId);
    expect(remaining, isEmpty);
    expect(await db.getClassroomById(classroomId), isNull);
  });
}
