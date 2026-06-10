import 'package:cryonix/features/auth/repository/auth_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../helpers/test_database.dart';

void main() {
  late dynamic db;

  setUp(() {
    db = createTestDatabase();
    SharedPreferences.setMockInitialValues({});
  });

  tearDown(() async {
    await db.close();
  });

  group('AuthRepository', () {
    test('registerWithEmail and signInWithEmail offline flow', () async {
      final prefs = await SharedPreferences.getInstance();
      final repo = AuthRepository(db, prefs);

      // Register
      final cred = await repo.registerWithEmail('teacher@school.com', 'password12345', 'Teacher One');
      expect(cred.user, isNotNull);
      expect(cred.user?.email, 'teacher@school.com');
      expect(cred.user?.displayName, 'Teacher One');
      expect(repo.currentUser?.uid, cred.user?.uid);

      // Sign out
      await repo.signOut();
      expect(repo.currentUser?.uid, 'offline_user');

      // Sign in
      final cred2 = await repo.signInWithEmail('teacher@school.com', 'password12345');
      expect(cred2.user, isNotNull);
      expect(cred2.user?.email, 'teacher@school.com');
    });

    test('currentUser is offline_user when signed out', () async {
      final prefs = await SharedPreferences.getInstance();
      final repo = AuthRepository(db, prefs);
      expect(repo.currentUser?.uid, 'offline_user');
    });
  });
}
