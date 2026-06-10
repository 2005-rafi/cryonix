import 'package:cryonix/database/app_database.dart';
import 'package:cryonix/database/migration_strategy.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/builders/test_data_builder.dart';
import '../../../helpers/test_database.dart';

void main() {
  test('fresh database reaches current schema version', () async {
    final db = createTestDatabase();
    addTearDown(db.close);
    expect(db.schemaVersion, 16);
    expect(AppMigrationStrategy.build(db), isNotNull);
  });

  test('UNIQUE classroom+date+label enforced on sessions', () async {
    final db = createTestDatabase();
    addTearDown(db.close);
    const classroomId = 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa';
    await db.insertClassroom(buildTestClassroom(id: classroomId, name: 'Math'));
    final date = DateTime.utc(2026, 5, 15);
    await db.insertSession(
      AttendanceSessionsTableCompanion.insert(
        id: 'session_1_12345678901234567890123456',
        classroomId: classroomId,
        date: date,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    );
    expect(
      () => db.insertSession(
        AttendanceSessionsTableCompanion.insert(
          id: 'session_2_12345678901234567890123456',
          classroomId: classroomId,
          date: date,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      ),
      throwsA(isA<Exception>()),
    );
  });

  test('inserted classroom is readable in same database session', () async {
    final db = createTestDatabase();
    addTearDown(db.close);
    const classroomId = 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa';
    await db.insertClassroom(buildTestClassroom(id: classroomId, name: 'Science'));
    final classroom = await db.getClassroomById(classroomId);
    expect(classroom?.name, 'Science');
  });
}
