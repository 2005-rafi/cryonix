import 'package:drift/drift.dart';

@TableIndex(name: 'idx_users_credentials_email', columns: {#email})
@TableIndex(name: 'idx_users_credentials_uid', columns: {#uid})
@DataClassName('UserCredentialsData')
class UsersCredentialsTable extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get email => text().unique()();
  TextColumn get passwordHash => text()();
  TextColumn get uid => text().unique()();
  TextColumn get displayName => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  BoolColumn get isVerified => boolean().withDefault(const Constant(true))();
}
