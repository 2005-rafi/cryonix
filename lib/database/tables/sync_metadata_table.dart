import 'package:drift/drift.dart';

@DataClassName('SyncMetadataEntry')
class SyncMetadataTable extends Table {
  TextColumn get collectionKey => text()();
  TextColumn get lastDownloadedAt => text().nullable()();

  @override
  Set<Column> get primaryKey => {collectionKey};
}
