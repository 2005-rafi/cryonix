import 'package:cryonix/database/migration_strategy.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/test_database.dart';

void main() {
  test('AppMigrationStrategy.build returns non-null strategy', () {
    final db = createTestDatabase();
    addTearDown(db.close);
    expect(AppMigrationStrategy.build(db), isNotNull);
  });
}
