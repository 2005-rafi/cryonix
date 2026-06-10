import 'package:flutter_test/flutter_test.dart';
import 'package:cryonix/core/app_initializer.dart';

void main() {
  test('AppInitializer completes without errors', () async {
    await expectLater(AppInitializer.initialize(), completes);
  });
}
