import 'package:drift/drift.dart';

@TableIndex(name: 'idx_classrooms_userId', columns: {#userId})
@DataClassName('Classroom')
class ClassroomsTable extends Table {
  TextColumn get id => text().named('id').withLength(min: 36, max: 36)();
  TextColumn get userId => text()();
  TextColumn get name => text()();
  TextColumn get subject => text().nullable().withDefault(const Constant(''))();
  TextColumn get description => text().nullable()();
  IntColumn get studentCount => integer().withDefault(const Constant(0))();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  DateTimeColumn get lastSessionAt => dateTime().nullable()();
  DateTimeColumn get deletedAt => dateTime().nullable()();
  IntColumn get syncVersion => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {id};
}
