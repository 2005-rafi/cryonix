import 'package:cryonix/features/classroom/repository/student_repository.dart';
import 'package:cryonix/services/csv_result.dart';
import 'package:cryonix/services/csv_service.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/builders/test_data_builder.dart';
import '../../helpers/test_database.dart';

void main() {
  test('CSV import adds students to classroom', () async {
    final db = createTestDatabase();
    const classroomId = 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa';
    await db.insertClassroom(buildTestClassroom(id: classroomId));
    final repo = StudentRepository(db);
    const csv = 'roll,name\n01,A\n02,B\n03,C\n04,D\n05,E\n';
    final result = CsvService().parseString(csv);
    expect(result, isA<CsvSuccess>());
    final students = (result as CsvSuccess).students;
    final importResult = await repo.insertStudentsBatch(classroomId, students);
    expect(importResult.insertedCount, 5);
    final roster = await repo.getStudentsByClassroom(classroomId);
    expect(roster.length, 5);
    await db.close();
  });

  test('partial duplicate import skips existing rolls', () async {
    final db = createTestDatabase();
    const classroomId = 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa';
    await db.insertClassroom(buildTestClassroom(id: classroomId));
    final repo = StudentRepository(db);
    await repo.addStudent(classroomId, '01', 'Existing A');
    await repo.addStudent(classroomId, '02', 'Existing B');
    const csv = 'roll,name\n01,A\n02,B\n03,C\n04,D\n05,E\n';
    final students = (CsvService().parseString(csv) as CsvSuccess).students;
    final importResult = await repo.insertStudentsBatch(classroomId, students);
    expect(importResult.insertedCount, 3);
    expect(importResult.skippedRolls, containsAll(['01', '02']));
    final roster = await repo.getStudentsByClassroom(classroomId);
    expect(roster.length, 5);
    await db.close();
  });
}
