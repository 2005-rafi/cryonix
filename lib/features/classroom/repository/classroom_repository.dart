import 'dart:convert';
import 'package:drift/drift.dart';
import '../../auth/repository/i_auth_repository.dart';
import 'package:uuid/uuid.dart';
import '../../../core/base_repository.dart';
import '../../../database/app_database.dart';

class ClassroomRepository extends BaseRepository<Classroom> {
  final AppDatabase _db;
  final IAuthRepository _auth;

  ClassroomRepository(this._db, {required IAuthRepository auth})
      : _auth = auth;

  @override
  Stream<List<Classroom>> watchAll(String userId) => watchClassrooms(userId);

  @override
  Future<void> delete(String id) => deleteClassroom(id);

  Future<void> createClassroom(String name, String subject, {String? description}) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) throw Exception('User not authenticated');

    final id = const Uuid().v4();
    await _db.writeAndEnqueue(
      () => _db.insertClassroom(
        ClassroomsTableCompanion.insert(
          id: id,
          userId: uid,
          name: name,
          subject: Value(subject.isEmpty ? null : subject),
          description: Value(description),
          studentCount: const Value(0),
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      ),
      [
        SyncQueueTableCompanion.insert(
          id: 'classroom:$id',
          entityType: 'classroom',
          entityId: id,
          operation: const Value('upsert'),
          enqueuedAt: DateTime.now(),
        ),
      ],
    );
  }

  Stream<List<Classroom>> watchClassrooms(String userId) {
    return _db.watchClassrooms(userId);
  }

  Future<Classroom?> getClassroomById(String id) {
    return _db.getClassroomById(id);
  }

  Future<void> updateClassroom(String id, String name, String subject, {String? description}) async {
    await _db.writeAndEnqueue(
      () => _db.updateClassroom(id, name, subject, description),
      [
        SyncQueueTableCompanion.insert(
          id: 'classroom:$id',
          entityType: 'classroom',
          entityId: id,
          operation: const Value('upsert'),
          enqueuedAt: DateTime.now(),
        ),
      ],
    );
  }

  Future<void> deleteClassroom(String id) async {
    // 1. Read everything first to construct the manifest
    final records = await (_db.select(_db.attendanceRecordsTable)..where((t) => t.classroomId.equals(id))).get();
    final recordRefs = records.map((r) => 'sessions/${r.sessionId}/records/${r.id}').toList();

    final sessions = await (_db.select(_db.attendanceSessionsTable)..where((t) => t.classroomId.equals(id))).get();
    final sessionRefs = sessions.map((s) => 'sessions/${s.id}').toList();

    final students = await (_db.select(_db.studentsTable)..where((t) => t.classroomId.equals(id))).get();
    final studentRefs = students.map((s) => 'classrooms/$id/students/${s.id}').toList();

    final manifest = {
      'recordRefs': recordRefs,
      'sessionRefs': sessionRefs,
      'studentRefs': studentRefs,
      'classroomRef': 'classrooms/$id',
    };

    // 2. Perform the database deletes and enqueue the cascade delete in a single atomic transaction
    await _db.writeAndEnqueue(() async {
      for (final r in records) {
        await (_db.delete(_db.syncQueueTable)..where((t) => t.entityType.equals('record') & t.entityId.equals(r.id))).go();
      }
      for (final s in sessions) {
        await (_db.delete(_db.syncQueueTable)..where((t) => t.entityType.equals('session') & t.entityId.equals(s.id))).go();
      }
      for (final s in students) {
        await (_db.delete(_db.syncQueueTable)..where((t) => t.entityType.equals('student') & t.entityId.equals(s.id))).go();
      }
      await (_db.delete(_db.syncQueueTable)..where((t) => t.entityType.equals('classroom') & t.entityId.equals(id))).go();

      await (_db.delete(_db.attendanceRecordsTable)..where((t) => t.classroomId.equals(id))).go();
      await (_db.delete(_db.attendanceSessionsTable)..where((t) => t.classroomId.equals(id))).go();
      await (_db.delete(_db.studentsTable)..where((t) => t.classroomId.equals(id))).go();
      await (_db.delete(_db.classroomsTable)..where((t) => t.id.equals(id))).go();
    }, [
      SyncQueueTableCompanion.insert(
        id: 'cascade:$id',
        entityType: 'classroom_cascade_delete',
        entityId: id,
        operation: const Value('delete'),
        payload: Value(jsonEncode(manifest)),
        enqueuedAt: DateTime.now(),
      ),
    ]);
  }

  Future<int> getStudentCount(String classroomId) async {
    final countExp = _db.studentsTable.id.count();
    final query = _db.selectOnly(_db.studentsTable)
      ..addColumns([countExp])
      ..where(_db.studentsTable.classroomId.equals(classroomId))
      ..where(_db.studentsTable.isActive.equals(true));
    final result = await query.getSingle();
    return result.read(countExp) ?? 0;
  }
}
