import 'package:cryonix/database/app_database.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/builders/test_data_builder.dart';
import '../../../helpers/test_database.dart';

void main() {
  late AppDatabase db;

  setUp(() {
    db = createTestDatabase();
  });

  tearDown(() async {
    await db.close();
  });

  test('insert and watch stream emits classroom', () async {
    await db.insertClassroom(buildTestClassroom(name: 'Math'));
    final list = await db.watchClassrooms('user_1').first;
    expect(list.length, 1);
    expect(list.first.name, 'Math');
  });

  test('watchClassrooms is user-scoped', () async {
    await db.insertClassroom(
      buildTestClassroom(
        id: 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa',
        userId: 'user1',
      ),
    );
    await db.insertClassroom(
      buildTestClassroom(
        id: 'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb',
        userId: 'user1',
      ),
    );
    await db.insertClassroom(
      buildTestClassroom(
        id: 'cccccccc-cccc-cccc-cccc-cccccccccccc',
        userId: 'user2',
        name: 'Other',
      ),
    );
    final list = await db.watchClassrooms('user1').first;
    expect(list.length, 2);
  });

  test('update reflects in stream', () async {
    const id = 'classroom_1_123456789012345678901234';
    await db.insertClassroom(buildTestClassroom(id: id, name: 'Old'));
    await db.updateClassroom(id, 'New', 'Science', null);
    final classroom = await db.getClassroomById(id);
    expect(classroom?.name, 'New');
  });

  test('getClassroomById returns correct item', () async {
    const idA = 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa';
    const idB = 'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb';
    await db.insertClassroom(
      buildTestClassroom(id: idA, name: 'A', userId: 'u'),
    );
    await db.insertClassroom(
      buildTestClassroom(id: idB, name: 'B', userId: 'u'),
    );
    final found = await db.getClassroomById(idA);
    expect(found?.name, 'A');
  });

  test('getClassroomById returns null for missing id', () async {
    expect(await db.getClassroomById('missing'), isNull);
  });
}
