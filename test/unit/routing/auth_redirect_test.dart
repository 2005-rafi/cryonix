import 'package:cryonix/features/auth/providers.dart';
import 'package:cryonix/routing/auth_redirect.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('unauthenticated user on /home stays', () {
    expect(
      resolveAuthRedirect(
        authLoading: false,
        verification: AuthVerificationState.unauthenticated,
        currentPath: '/home',
      ),
      isNull,
    );
  });

  test('unauthenticated user on /auth redirects to /home', () {
    expect(
      resolveAuthRedirect(
        authLoading: false,
        verification: AuthVerificationState.unauthenticated,
        currentPath: '/auth',
      ),
      '/home',
    );
  });

  test('verified user on /auth redirects to /home', () {
    expect(
      resolveAuthRedirect(
        authLoading: false,
        verification: AuthVerificationState.authenticatedVerified,
        currentPath: '/auth',
      ),
      '/home',
    );
  });
}
