import '../features/auth/providers.dart';

/// Pure redirect logic for GoRouter — testable without widget tree.
///
/// Returns the path to navigate to, or null to stay on [currentPath].
String? resolveAuthRedirect({
  required bool authLoading,
  required AuthVerificationState? verification,
  required String currentPath,
}) {
  if (authLoading) {
    return currentPath == '/splash' ? null : '/splash';
  }

  if (currentPath == '/splash' || currentPath == '/auth' || currentPath == '/verify-email') {
    return '/home';
  }

  return null;
}
