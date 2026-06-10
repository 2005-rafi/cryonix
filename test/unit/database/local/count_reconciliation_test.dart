import 'package:cryonix/core/constants/domain_enums.dart';
import 'package:cryonix/database/app_database.dart';
import 'package:drift/drift.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/builders/test_data_builder.dart';
import '../../../helpers/test_database.dart';

void main() {
  late AppDatabase db;
  const classroomId = 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa';
  const sessionId = 'session_1_12345678901234567890123456';

  setUp(() {
    db = createTestDatabase();
  });

  tearDown(() async {
    await db.close();
  });

  Future<void> seedSessionWithRecords() async {
    await db.insertClassroom(buildTestClassroom(id: classroomId));
    await db.insertStudent(
      buildTestStudent(
        id: 'student_0_12345678901234567890123456',
        classroomId: classroomId,
        rollNumber: '01',
      ),
    );
    await db.insertStudent(
      buildTestStudent(
        id: 'student_1_12345678901234567890123456',
        classroomId: classroomId,
        rollNumber: '02',
      ),
    );
    await db.insertStudent(
      buildTestStudent(
        id: 'student_2_12345678901234567890123456',
        classroomId: classroomId,
        rollNumber: '03',
      ),
    );
    await db.insertStudent(
      buildTestStudent(
        id: 'student_3_12345678901234567890123456',
        classroomId: classroomId,
        rollNumber: '04',
      ),
    );
    await db.insertStudent(
      buildTestStudent(
        id: 'student_4_12345678901234567890123456',
        classroomId: classroomId,
        rollNumber: '05',
      ),
    );
    await db.insertSession(
      buildTestSession(id: sessionId, classroomId: classroomId),
    );
    final statuses = [
      AttendanceStatus.present,
      AttendanceStatus.present,
      AttendanceStatus.present,
      AttendanceStatus.absent,
      AttendanceStatus.onDuty,
    ];
    final students = await db.getActiveStudentsByClassroom(classroomId);
    final records = <AttendanceRecordsTableCompanion>[];
    for (var i = 0; i < students.length; i++) {
      records.add(
        buildTestRecord(
          id: 'record_${i}_123456789012345678901234567',
          sessionId: sessionId,
          studentId: students[i].id,
          classroomId: classroomId,
          status: statuses[i].name,
        ),
      );
    }
    await db.insertRecordsBatch(records);
    await (db.update(db.attendanceSessionsTable)
          ..where((t) => t.id.equals(sessionId)))
        .write(
      const AttendanceSessionsTableCompanion(
        presentCount: Value(3),
        absentCount: Value(1),
        onDutyCount: Value(1),
        totalStudents: Value(5),
      ),
    );
  }

  test('counts correct after save', () async {
    await seedSessionWithRecords();
    await db.recalculateSessionCounts(sessionId);
    final session = await db.getSessionById(sessionId);
    expect(session?.presentCount, 3);
    expect(session?.absentCount, 1);
    expect(session?.onDutyCount, 1);
    expect(session?.totalStudents, 5);
  });

  test('recalculateSessionCounts corrects drift', () async {
    await seedSessionWithRecords();
    await (db.update(db.attendanceSessionsTable)
          ..where((t) => t.id.equals(sessionId)))
        .write(
      const AttendanceSessionsTableCompanion(presentCount: Value(99)),
    );
    await db.recalculateSessionCounts(sessionId);
    final session = await db.getSessionById(sessionId);
    expect(session?.presentCount, 3);
  });

  test('reconcileRecentSessionCounts only touches recent sessions', () async {
    await db.insertClassroom(buildTestClassroom(id: classroomId));
    for (var i = 0; i < 35; i++) {
      final sid =
          '${i.toString().padLeft(8, '0')}-aaaa-aaaa-aaaa-aaaaaaaaaaaa';
      await db.insertSession(
        buildTestSession(
          id: sid,
          classroomId: classroomId,
          date: DateTime.utc(2026, 5, i + 1),
        ),
      );
      await (db.update(db.attendanceSessionsTable)
            ..where((t) => t.id.equals(sid)))
          .write(
        const AttendanceSessionsTableCompanion(presentCount: Value(99)),
      );
    }
    await db.reconcileRecentSessionCounts();
    final recent = await db.getSessionById(
      '00000005-aaaa-aaaa-aaaa-aaaaaaaaaaaa',
    );
    final old = await db.getSessionById(
      '00000000-aaaa-aaaa-aaaa-aaaaaaaaaaaa',
    );
    expect(recent?.presentCount, isNot(99));
    expect(old?.presentCount, 99);
  });
}
