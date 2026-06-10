import 'package:cryonix/database/app_database.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/builders/test_data_builder.dart';
import '../../../helpers/test_database.dart';

void main() {
  late AppDatabase db;
  const classroomA = 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa';
  const classroomB = 'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb';

  setUp(() {
    db = createTestDatabase();
  });

  tearDown(() async {
    await db.close();
  });

  test('roll number unique per classroom', () async {
    await db.insertClassroom(buildTestClassroom(id: classroomA));
    await db.insertClassroom(buildTestClassroom(id: classroomB));
    await db.insertStudent(
      buildTestStudent(
        id: 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa',
        classroomId: classroomA,
        rollNumber: '01',
      ),
    );
    expect(
      () => db.insertStudent(
        buildTestStudent(
          id: 'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb',
          classroomId: classroomA,
          rollNumber: '01',
        ),
      ),
      throwsA(isA<Exception>()),
    );
    await db.insertStudent(
      buildTestStudent(
        id: 'cccccccc-cccc-cccc-cccc-cccccccccccc',
        classroomId: classroomB,
        rollNumber: '01',
      ),
    );
    final bStudents = await db.getActiveStudentsByClassroom(classroomB);
    expect(bStudents.length, 1);
  });

  test('batch insert rolls back on duplicate roll', () async {
    await db.insertClassroom(buildTestClassroom(id: classroomA));
    final batch = [
      buildTestStudent(
        id: 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa',
        classroomId: classroomA,
        rollNumber: '01',
      ),
      buildTestStudent(
        id: 'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb',
        classroomId: classroomA,
        rollNumber: '02',
      ),
      buildTestStudent(
        id: 'cccccccc-cccc-cccc-cccc-cccccccccccc',
        classroomId: classroomA,
        rollNumber: '02',
      ),
    ];
    await expectLater(
      () => db.insertStudentsBatch(batch),
      throwsA(isA<Exception>()),
    );
    final students = await db.getActiveStudentsByClassroom(classroomA);
    expect(students, isEmpty);
  });

  test('soft-deleted students hidden from active query', () async {
    await db.insertClassroom(buildTestClassroom(id: classroomA));
    await db.insertStudent(
      buildTestStudent(
        id: 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa',
        classroomId: classroomA,
        rollNumber: '01',
      ),
    );
    await db.insertStudent(
      buildTestStudent(
        id: 'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb',
        classroomId: classroomA,
        rollNumber: '02',
      ),
    );
    await db.insertStudent(
      buildTestStudent(
        id: 'cccccccc-cccc-cccc-cccc-cccccccccccc',
        classroomId: classroomA,
        rollNumber: '03',
      ),
    );
    await db.softDeleteStudent(
      'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb',
      classroomA,
    );
    final active = await db.getActiveStudentsByClassroom(classroomA);
    expect(active.length, 2);
    final all = await db.select(db.studentsTable).get();
    expect(all.length, 3);
  });

  test('enrolledAt is set on insert', () async {
    await db.insertClassroom(buildTestClassroom(id: classroomA));
    final before = DateTime.now();
    await db.insertStudent(
      buildTestStudent(
        id: 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa',
        classroomId: classroomA,
        rollNumber: '01',
      ),
    );
    final student = await (db.select(db.studentsTable)
          ..where((t) => t.id.equals('aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa')))
        .getSingle();
    expect(student.enrolledAt.difference(before).inSeconds, lessThan(5));
  });
}
