/// The authentication contract used by providers and tests.
/// Redefined to be completely offline and database-independent.
library;

class User {
  final String uid;
  final String? email;
  final String? displayName;
  final bool emailVerified;
  final Future<void> Function()? _onDelete;

  const User({
    required this.uid,
    this.email,
    this.displayName,
    this.emailVerified = true,
    Future<void> Function()? onDelete,
  }) : _onDelete = onDelete;

  Future<void> delete() async {
    if (_onDelete != null) {
      await _onDelete();
    }
  }
}

class UserCredential {
  final User? user;
  const UserCredential({this.user});
}

abstract class IAuthRepository {
  /// The currently signed-in user, or null.
  User? get currentUser;

  /// Stream of auth state changes. Emits null when signed out.
  Stream<User?> get authStateChanges;

  /// Signs in with email and password.
  Future<UserCredential> signInWithEmail(String email, String password);

  /// Registers a new account with email, password, and display name.
  Future<UserCredential> registerWithEmail(
      String email, String password, String displayName);

  /// Sends an email verification to the current user.
  Future<void> sendVerificationEmail();

  /// Reloads the user token and returns updated emailVerified status.
  Future<bool> reloadAndCheckVerification();

  /// Signs in via Google OAuth (Deprecated - throws UnimplementedError).
  Future<UserCredential> signInWithGoogle();

  /// Signs out from local session.
  Future<void> signOut();

  /// Re-authenticates the current user with their password (for sensitive ops).
  Future<void> reauthenticateWithPassword(String password);

  /// Re-authenticates the current user with Google (Deprecated - throws UnimplementedError).
  Future<void> reauthenticateWithGoogle();
}
