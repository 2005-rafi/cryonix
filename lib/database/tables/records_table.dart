import 'package:drift/drift.dart';

@TableIndex(name: 'idx_records_sessionId', columns: {#sessionId})
@TableIndex(name: 'idx_records_studentId', columns: {#studentId})
@TableIndex(name: 'idx_records_classroomDate', columns: {#classroomId, #markedAt})
@DataClassName('AttendanceRecord')
class AttendanceRecordsTable extends Table {
  TextColumn get id => text().named('id').withLength(min: 36, max: 36)();
  TextColumn get sessionId => text()();
  TextColumn get studentId => text()();
  TextColumn get classroomId => text()();
  TextColumn get status => text().withDefault(const Constant('present')).customConstraint("NOT NULL CHECK(status IN ('present','absent','onDuty'))")();
  TextColumn get snapshotName => text().customConstraint("NOT NULL CHECK(length(trim(snapshot_name)) > 0)")();
  TextColumn get snapshotRoll => text().customConstraint("NOT NULL CHECK(length(trim(snapshot_roll)) > 0)")();
  DateTimeColumn get markedAt => dateTime()();
  IntColumn get syncVersion => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {id};

  @override
  List<Set<Column>> get uniqueKeys => [
    {sessionId, studentId},
  ];
}
