import 'dart:async';
import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:drift/drift.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../../../database/app_database.dart';
import 'i_auth_repository.dart';

class AuthRepository implements IAuthRepository {
  final AppDatabase _db;
  final SharedPreferences _prefs;
  final _authStateController = StreamController<User?>.broadcast();
  User? _currentUser;

  AuthRepository(this._db, this._prefs) {
    _initCurrentUser();
  }

  void _initCurrentUser() {
    final uid = _prefs.getString('current_uid');
    if (uid != null) {
      final email = _prefs.getString('current_email');
      final displayName = _prefs.getString('current_display_name');
      _currentUser = User(
        uid: uid,
        email: email,
        displayName: displayName,
        emailVerified: true,
        onDelete: deleteCurrentUser,
      );
      _authStateController.add(_currentUser);
    } else {
      _currentUser = User(
        uid: 'offline_user',
        email: 'offline@cryonix.local',
        displayName: 'Offline Teacher',
        emailVerified: true,
        onDelete: deleteCurrentUser,
      );
      _authStateController.add(_currentUser);
    }
  }

  @override
  User? get currentUser => _currentUser;

  @override
  Stream<User?> get authStateChanges async* {
    yield _currentUser;
    yield* _authStateController.stream;
  }

  String _hashPassword(String password) {
    return sha256.convert(utf8.encode(password)).toString();
  }

  @override
  Future<UserCredential> signInWithEmail(String email, String password) async {
    final normalizedEmail = email.toLowerCase().trim();
    final userRow = await (_db.select(_db.usersCredentialsTable)
          ..where((t) => t.email.equals(normalizedEmail)))
        .getSingleOrNull();

    if (userRow == null) {
      throw Exception('No account found with this email.');
    }

    final computedHash = _hashPassword(password);
    if (userRow.passwordHash != computedHash) {
      throw Exception('Incorrect email or password.');
    }

    await _prefs.setString('current_uid', userRow.uid);
    await _prefs.setString('current_email', userRow.email);
    if (userRow.displayName != null) {
      await _prefs.setString('current_display_name', userRow.displayName!);
    } else {
      await _prefs.remove('current_display_name');
    }

    _currentUser = User(
      uid: userRow.uid,
      email: userRow.email,
      displayName: userRow.displayName,
      emailVerified: userRow.isVerified,
      onDelete: deleteCurrentUser,
    );
    _authStateController.add(_currentUser);

    return UserCredential(user: _currentUser);
  }

  @override
  Future<UserCredential> registerWithEmail(
    String email,
    String password,
    String displayName,
  ) async {
    final normalizedEmail = email.toLowerCase().trim();

    // Check if email already exists
    final existing = await (_db.select(_db.usersCredentialsTable)
          ..where((t) => t.email.equals(normalizedEmail)))
        .getSingleOrNull();

    if (existing != null) {
      throw Exception('An account already exists for that email.');
    }

    final uid = const Uuid().v4();
    final hash = _hashPassword(password);
    final now = DateTime.now();

    await _db.into(_db.usersCredentialsTable).insert(
          UsersCredentialsTableCompanion.insert(
            email: normalizedEmail,
            passwordHash: hash,
            uid: uid,
            displayName: Value(displayName.isEmpty ? null : displayName),
            createdAt: now,
            isVerified: const Value(true),
          ),
        );

    await _prefs.setString('current_uid', uid);
    await _prefs.setString('current_email', normalizedEmail);
    if (displayName.isNotEmpty) {
      await _prefs.setString('current_display_name', displayName);
    } else {
      await _prefs.remove('current_display_name');
    }

    _currentUser = User(
      uid: uid,
      email: normalizedEmail,
      displayName: displayName.isEmpty ? null : displayName,
      emailVerified: true,
      onDelete: deleteCurrentUser,
    );
    _authStateController.add(_currentUser);

    return UserCredential(user: _currentUser);
  }

  @override
  Future<void> sendVerificationEmail() async {
    // Local verification is automatic, no-op
  }

  @override
  Future<bool> reloadAndCheckVerification() async {
    return true;
  }

  @override
  Future<UserCredential> signInWithGoogle() {
    throw UnimplementedError('Google Sign-In is not supported in offline mode.');
  }

  @override
  Future<void> signOut() async {
    await _prefs.remove('current_uid');
    await _prefs.remove('current_email');
    await _prefs.remove('current_display_name');
    _currentUser = User(
      uid: 'offline_user',
      email: 'offline@cryonix.local',
      displayName: 'Offline Teacher',
      emailVerified: true,
      onDelete: deleteCurrentUser,
    );
    _authStateController.add(_currentUser);
  }

  @override
  Future<void> reauthenticateWithPassword(String password) async {
    final user = _currentUser;
    if (user == null || user.email == null) {
      throw Exception('No user is currently signed in.');
    }

    final userRow = await (_db.select(_db.usersCredentialsTable)
          ..where((t) => t.email.equals(user.email!)))
        .getSingleOrNull();

    if (userRow == null) {
      throw Exception('User account not found.');
    }

    final computedHash = _hashPassword(password);
    if (userRow.passwordHash != computedHash) {
      throw Exception('Incorrect password.');
    }
  }

  @override
  Future<void> reauthenticateWithGoogle() {
    throw UnimplementedError('Google Sign-In is not supported in offline mode.');
  }

  Future<void> deleteCurrentUser() async {
    final uid = _currentUser?.uid;
    if (uid != null) {
      await (_db.delete(_db.usersCredentialsTable)..where((t) => t.uid.equals(uid))).go();
    }
    await signOut();
  }
}
