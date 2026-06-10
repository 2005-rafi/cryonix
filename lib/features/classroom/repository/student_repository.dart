import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';
import '../../../core/base_repository.dart';
import '../../../database/app_database.dart';
import '../../../models/parsed_student.dart';

class ClassroomIsolationException implements Exception {
  final String message;
  ClassroomIsolationException(this.message);
}

class StudentImportResult {
  final int insertedCount;
  final List<String> skippedRolls;
  StudentImportResult({
    required this.insertedCount,
    required this.skippedRolls,
  });
}

class StudentRepository extends BaseRepository<Student> {
  final AppDatabase _db;

  StudentRepository(this._db);

  @override
  Stream<List<Student>> watchAll(String classroomId) =>
      watchStudentsByClassroom(classroomId);

  @override
  Future<void> delete(String id) async {
    final student = await (_db.select(_db.studentsTable)
          ..where((t) => t.id.equals(id)))
        .getSingleOrNull();
    if (student != null) {
      await deleteStudent(id, student.classroomId);
    }
  }

  Future<void> addStudent(
    String classroomId,
    String rollNumber,
    String name,
  ) async {
    final existing =
        await (_db.select(_db.studentsTable)
              ..where((t) => t.classroomId.equals(classroomId))
              ..where((t) => t.rollNumber.equals(rollNumber)))
            .getSingleOrNull();

    if (existing != null) {
      if (existing.isActive) {
        throw Exception('Roll number already exists in this classroom');
      } else {
        // Reactivate soft-deleted student
        final now = DateTime.now();
        await _db.writeAndEnqueue(() async {
          await (_db.update(
            _db.studentsTable,
          )..where((t) => t.id.equals(existing.id))).write(
            StudentsTableCompanion(
              name: Value(name),
              isActive: const Value(true),
              deletedAt: const Value(null),
              enrolledAt: Value(now),
              updatedAt: Value(now),
            ),
          );

          await _db.incrementStudentCount(classroomId);
        }, [
          SyncQueueTableCompanion.insert(
            id: 'student:${existing.id}',
            entityType: 'student',
            entityId: existing.id,
            operation: const Value('upsert'),
            enqueuedAt: DateTime.now(),
          ),
          SyncQueueTableCompanion.insert(
            id: 'classroom:$classroomId',
            entityType: 'classroom',
            entityId: classroomId,
            operation: const Value('upsert'),
            enqueuedAt: DateTime.now(),
          ),
        ]);
        return;
      }
    }

    final id = const Uuid().v4();
    final now = DateTime.now();
    await _db.writeAndEnqueue(() async {
      await _db.insertStudent(
        StudentsTableCompanion.insert(
          id: id,
          classroomId: classroomId,
          rollNumber: rollNumber,
          name: name,
          isActive: const Value(true),
          enrolledAt: now,
          createdAt: now,
          updatedAt: now,
        ),
      );

      await _db.incrementStudentCount(classroomId);
    }, [
      SyncQueueTableCompanion.insert(
        id: 'student:$id',
        entityType: 'student',
        entityId: id,
        operation: const Value('upsert'),
        enqueuedAt: DateTime.now(),
      ),
      SyncQueueTableCompanion.insert(
        id: 'classroom:$classroomId',
        entityType: 'classroom',
        entityId: classroomId,
        operation: const Value('upsert'),
        enqueuedAt: DateTime.now(),
      ),
    ]);
  }

  Stream<List<Student>> watchStudentsByClassroom(String classroomId) {
    return _db.watchActiveStudentsByClassroom(classroomId);
  }

  Future<List<Student>> getStudentsByClassroom(String classroomId) {
    return _db.getActiveStudentsByClassroom(classroomId);
  }

  Future<StudentImportResult> insertStudentsBatch(
    String classroomId,
    List<ParsedStudent> parsedStudents,
  ) async {
    final importBatchId = const Uuid().v4();
    final groupKey = 'import:$importBatchId';

    final allExistingStudents = await (_db.select(
      _db.studentsTable,
    )..where((t) => t.classroomId.equals(classroomId))).get();

    final activeRolls = allExistingStudents
        .where((s) => s.isActive)
        .map((s) => s.rollNumber)
        .toSet();
    final inactiveStudents = {
      for (var s in allExistingStudents.where((s) => !s.isActive))
        s.rollNumber: s,
    };

    final validStudents = <ParsedStudent>[];
    final studentsToReactivate = <Student>[];
    final skippedRolls = <String>[];
    final processedRolls = <String>{};

    for (final s in parsedStudents) {
      if (processedRolls.contains(s.rollNumber) ||
          activeRolls.contains(s.rollNumber)) {
        skippedRolls.add(s.rollNumber);
      } else if (inactiveStudents.containsKey(s.rollNumber)) {
        studentsToReactivate.add(inactiveStudents[s.rollNumber]!);
        processedRolls.add(s.rollNumber);
      } else {
        validStudents.add(s);
        processedRolls.add(s.rollNumber);
      }
    }

    final syncEntries = <SyncQueueTableCompanion>[];
    final now = DateTime.now();

    final insertedCount = await _db.writeAndEnqueue(() async {
      int inserted = 0;

      // 1. Insert brand new students
      for (final student in validStudents) {
        final id = const Uuid().v4();
        await _db.insertStudent(
          StudentsTableCompanion.insert(
            id: id,
            classroomId: classroomId,
            rollNumber: student.rollNumber,
            name: student.name,
            isActive: const Value(true),
            enrolledAt: now,
            createdAt: now,
            updatedAt: now,
          ),
        );
        inserted++;

        syncEntries.add(
          SyncQueueTableCompanion.insert(
            id: 'student:$id',
            entityType: 'student',
            entityId: id,
            operation: const Value('upsert'),
            enqueuedAt: DateTime.now(),
            groupKey: Value(groupKey),
          ),
        );
      }

      // 2. Reactivate soft-deleted students
      final parsedMap = {
        for (var ps in parsedStudents) ps.rollNumber: ps,
      };

      for (final student in studentsToReactivate) {
        final parsed = parsedMap[student.rollNumber];
        if (parsed == null) continue;

        await (_db.update(
          _db.studentsTable,
        )..where((t) => t.id.equals(student.id))).write(
          StudentsTableCompanion(
            name: Value(parsed.name),
            isActive: const Value(true),
            deletedAt: const Value(null),
            enrolledAt: Value(now),
            updatedAt: Value(now),
          ),
        );
        inserted++;

        syncEntries.add(
          SyncQueueTableCompanion.insert(
            id: 'student:${student.id}',
            entityType: 'student',
            entityId: student.id,
            operation: const Value('upsert'),
            enqueuedAt: DateTime.now(),
            groupKey: Value(groupKey),
          ),
        );
      }

      if (inserted > 0) {
        await _db.incrementStudentCount(classroomId, by: inserted);
        syncEntries.add(
          SyncQueueTableCompanion.insert(
            id: 'classroom:$classroomId',
            entityType: 'classroom',
            entityId: classroomId,
            operation: const Value('upsert'),
            enqueuedAt: DateTime.now(),
            groupKey: Value(groupKey),
          ),
        );
      }
      return inserted;
    }, syncEntries);

    return StudentImportResult(
      insertedCount: insertedCount,
      skippedRolls: skippedRolls,
    );
  }

  Future<void> updateStudent(
    String id,
    String classroomId,
    String rollNumber,
    String name,
  ) async {
    final ownerCheck =
        await (_db.selectOnly(_db.studentsTable)
              ..addColumns([_db.studentsTable.id])
              ..where(
                _db.studentsTable.id.equals(id) &
                    _db.studentsTable.classroomId.equals(classroomId),
              ))
            .getSingleOrNull();

    if (ownerCheck == null) {
      throw ClassroomIsolationException(
        "Student does not belong to this classroom",
      );
    }

    final existing =
        await (_db.select(_db.studentsTable)
              ..where((t) => t.classroomId.equals(classroomId))
              ..where((t) => t.rollNumber.equals(rollNumber))
              ..where((t) => t.id.equals(id).not()))
            .getSingleOrNull();

    if (existing != null) {
      throw Exception('Roll number already exists in this classroom');
    }

    await _db.writeAndEnqueue(
      () => _db.updateStudent(id, rollNumber, name),
      [
        SyncQueueTableCompanion.insert(
          id: 'student:$id',
          entityType: 'student',
          entityId: id,
          operation: const Value('upsert'),
          enqueuedAt: DateTime.now(),
        ),
      ],
    );
  }

  Future<void> deleteStudent(String id, String classroomId) async {
    final ownerCheck =
        await (_db.selectOnly(_db.studentsTable)
              ..addColumns([_db.studentsTable.id])
              ..where(
                _db.studentsTable.id.equals(id) &
                    _db.studentsTable.classroomId.equals(classroomId),
              ))
            .getSingleOrNull();

    if (ownerCheck == null) {
      throw ClassroomIsolationException(
        "Student does not belong to this classroom",
      );
    }

    await _db.writeAndEnqueue(() async {
      await _db.softDeleteStudent(id, classroomId);
      await _db.decrementStudentCount(classroomId);
    }, [
      SyncQueueTableCompanion.insert(
        id: 'student:$id',
        entityType: 'student',
        entityId: id,
        operation: const Value('upsert'),
        enqueuedAt: DateTime.now(),
      ),
      SyncQueueTableCompanion.insert(
        id: 'classroom:$classroomId',
        entityType: 'classroom',
        entityId: classroomId,
        operation: const Value('upsert'),
        enqueuedAt: DateTime.now(),
      ),
    ]);
  }

  Future<StudentSnapshot> getStudentSnapshot(String studentId) async {
    final s = await (_db.select(
      _db.studentsTable,
    )..where((t) => t.id.equals(studentId))).getSingle();
    return StudentSnapshot(name: s.name, rollNumber: s.rollNumber);
  }
}

class StudentSnapshot {
  final String name;
  final String rollNumber;
  StudentSnapshot({required this.name, required this.rollNumber});
}
