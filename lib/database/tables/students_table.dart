import 'package:drift/drift.dart';

// Phase 4 — Task 4.1:
// Added `updatedAt` column so every student write carries a timestamp for
// conditional Firestore write / conflict resolution.

@TableIndex(name: 'idx_students_classroomId', columns: {#classroomId, #isActive})
@TableIndex(name: 'idx_students_enrolledAt', columns: {#classroomId, #enrolledAt})
@DataClassName('Student')
class StudentsTable extends Table {
  TextColumn get id => text().named('id').withLength(min: 36, max: 36)();
  TextColumn get classroomId => text()();
  TextColumn get rollNumber => text()();
  TextColumn get name => text()();
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
  DateTimeColumn get enrolledAt => dateTime()();
  DateTimeColumn get deletedAt => dateTime().nullable()();
  DateTimeColumn get createdAt => dateTime()();

  /// Set to DateTime.now() on every write — used for conflict resolution.
  DateTimeColumn get updatedAt => dateTime()();
  IntColumn get syncVersion => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {id};

  @override
  List<Set<Column>> get uniqueKeys => [
        {classroomId, rollNumber},
      ];
}
