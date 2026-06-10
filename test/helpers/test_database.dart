import 'package:drift/native.dart';
import 'package:cryonix/database/app_database.dart';

/// Creates a new in-memory Drift database for testing.
/// This database is identical to the production AppDatabase in schema
/// but lives only in memory and is destroyed when the test ends.
AppDatabase createTestDatabase() {
  return AppDatabase.forTesting(NativeDatabase.memory());
}
