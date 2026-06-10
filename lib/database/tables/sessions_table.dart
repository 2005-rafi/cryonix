import 'package:drift/drift.dart';

// Phase 4 — Task 4.1:
// Added `updatedAt` column for conditional Firestore write / conflict resolution.
// Phase 5 — Task 5.1 (verifiedSynced) uses updatedAt for post-sync read-back.

@TableIndex(name: 'idx_sessions_classroomDateActive', columns: {#classroomId, #date, #isDeleted})
@TableIndex(name: 'idx_sessions_id_date', columns: {#id, #date})
@DataClassName('AttendanceSession')
class AttendanceSessionsTable extends Table {
  TextColumn get id => text().named('id').withLength(min: 36, max: 36)();
  TextColumn get classroomId => text()();
  DateTimeColumn get date => dateTime()();
  IntColumn get totalStudents => integer().withDefault(const Constant(0))();
  IntColumn get presentCount => integer().withDefault(const Constant(0))();
  IntColumn get absentCount => integer().withDefault(const Constant(0))();
  IntColumn get onDutyCount => integer().withDefault(const Constant(0))();
  TextColumn get label => text().withDefault(const Constant('Full Day'))();
  BoolColumn get isDeleted => boolean().withDefault(const Constant(false))();
  DateTimeColumn get deletedAt => dateTime().nullable()();
  DateTimeColumn get createdAt => dateTime()();

  /// Set to DateTime.now() on every write — used for conflict resolution.
  DateTimeColumn get updatedAt => dateTime()();
  IntColumn get syncVersion => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {id};

  @override
  List<Set<Column>> get uniqueKeys => [
        {classroomId, date, label},
      ];
}
