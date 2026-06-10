// Email verification is enforced at the GoRouter redirect level.
// Repository methods do not re-check verification — they trust that the
// router has already validated this (Phase 2 — Task 2.3).
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'repository/i_auth_repository.dart';
import 'repository/auth_repository.dart';
import '../../core/providers.dart';

/// Which auth method is currently in progress (for separate button loading UI).
enum LoadingMethod {
  none,
  emailPassword,
  google,
}

@immutable
class AuthNotifierState {
  const AuthNotifierState({
    this.asyncValue = const AsyncData<String?>(null),
    this.loadingMethod = LoadingMethod.none,
  });

  final AsyncValue<String?> asyncValue;
  final LoadingMethod loadingMethod;

  bool get isEmailLoading =>
      asyncValue is AsyncLoading && loadingMethod == LoadingMethod.emailPassword;

  bool get isGoogleLoading =>
      asyncValue is AsyncLoading && loadingMethod == LoadingMethod.google;
}

// ── Three-state auth enum (Phase 2 — Task 2.2) ───────────────────────────
enum AuthVerificationState {
  /// No Firebase user is signed in.
  unauthenticated,

  /// User is signed in but has not verified their email address.
  authenticatedUnverified,

  /// User is signed in AND email is verified (or is a Google-auth user).
  authenticatedVerified,
}

final authRepositoryProvider = Provider<IAuthRepository>((ref) {
  final db = ref.watch(appDatabaseProvider);
  final prefs = ref.watch(sharedPreferencesProvider);
  return AuthRepository(db, prefs);
});

/// Watches user changes (including profile updates, sign in/out, and token updates).
final userChangesProvider = StreamProvider<User?>((ref) {
  return ref.watch(authRepositoryProvider).authStateChanges;
});

/// Emits a [AuthVerificationState] derived from the current user.
/// This is the single source of truth consumed by the GoRouter redirect.
final authStateProvider = StreamProvider<AuthVerificationState>((ref) {
  return ref
      .watch(authRepositoryProvider)
      .authStateChanges
      .map((user) {
    if (user == null) {
      return AuthVerificationState.unauthenticated;
    }
    if (user.emailVerified) {
      return AuthVerificationState.authenticatedVerified;
    }
    return AuthVerificationState.authenticatedUnverified;
  });
});

/// Convenience provider that exposes the raw [User?] for UI widgets that
/// only need profile information (display name, email, uid).
/// Watches [userChangesProvider] to dynamically rebuild when profile or verification state changes.
final currentUserProvider = Provider<User?>((ref) {
  final userChanges = ref.watch(userChangesProvider).value;
  return userChanges ?? ref.watch(authRepositoryProvider).currentUser;
});

// ── AuthNotifier ─────────────────────────────────────────────────────────
class AuthNotifier extends StateNotifier<AuthNotifierState> {
  final IAuthRepository _repository;
  final Ref _ref;

  AuthNotifier(this._repository, this._ref) : super(const AuthNotifierState());

  void _setLoading(LoadingMethod method) {
    state = AuthNotifierState(
      asyncValue: const AsyncLoading(),
      loadingMethod: method,
    );
  }

  void _setSuccess([String? message]) {
    state = AuthNotifierState(asyncValue: AsyncData(message));
  }

  void _setError(Object error, StackTrace stackTrace) {
    state = AuthNotifierState(
      asyncValue: AsyncError(error, stackTrace),
    );
  }

  Future<void> signInWithEmail(String email, String password) async {
    _setLoading(LoadingMethod.emailPassword);
    try {
      await _repository.signInWithEmail(email, password);
      _setSuccess();
    } catch (e, st) {
      _setError(e, st);
    }
  }

  Future<void> registerWithEmail(
    String email,
    String password,
    String displayName,
  ) async {
    _setLoading(LoadingMethod.emailPassword);
    try {
      await _repository.registerWithEmail(email, password, displayName);
      _setSuccess(
        'Registration successful! Please check your email to verify your account.',
      );
    } catch (e, st) {
      _setError(e, st);
    }
  }

  Future<void> signInWithGoogle() async {
    _setLoading(LoadingMethod.google);
    try {
      await _repository.signInWithGoogle();
      _setSuccess();
    } catch (e, st) {
      _setError(e, st);
    }
  }

  Future<void> signOut() async {
    _setLoading(LoadingMethod.emailPassword);
    try {
      await _repository.signOut();
      _setSuccess();
    } catch (e, st) {
      _setError(e, st);
    }
  }

  /// Sends a verification email to the currently signed-in unverified user.
  Future<void> sendVerificationEmail() async {
    _setLoading(LoadingMethod.emailPassword);
    try {
      await _repository.sendVerificationEmail();
      _setSuccess(
        'Verification email sent! Please check your inbox.',
      );
    } catch (e, st) {
      _setError(e, st);
    }
  }

  /// Reloads the Firebase user token and returns the updated emailVerified
  /// status. Call this from the VerificationPendingScreen "Check Status" flow.
  Future<bool> reloadAndCheckVerification() async {
    try {
      final isVerified = await _repository.reloadAndCheckVerification();
      if (isVerified) {
        _ref.invalidate(authStateProvider);
      }
      return isVerified;
    } catch (_) {
      return false;
    }
  }
}

final authNotifierProvider =
    StateNotifierProvider<AuthNotifier, AuthNotifierState>((ref) {
  return AuthNotifier(ref.watch(authRepositoryProvider), ref);
});
