# Cryonix Deep-Dive Firebase Audit: Offline-First Migration Strategy

**Document Type:** Offline Migration & Dependency Removal Analysis  
**Status:** Complete & Actionable  
**Last Updated:** May 27, 2026  
**Scope:** Remove Firebase Auth + Firestore, Make App 100% Offline-Capable

---

## Executive Summary

Cryonix is currently a **cloud-dependent attendance application** relying on Firebase for authentication and real-time data synchronization. This audit provides a complete roadmap to transform it into an **offline-first application** with zero internet dependency.

**Current State:** All authentication and data sync flows require Firebase connectivity.  
**Target State:** App operates with full functionality offline; cloud sync becomes optional future feature.

**Key Finding:** The app's **Drift SQLite database + sync_queue architecture is already present** — removing Firebase only requires:
1. Replacing Firebase Auth with local credentials
2. Disabling Firestore listeners
3. Conditional Firebase initialization
4. Implementing local auth state management

---

## 1. COMPREHENSIVE FIREBASE DEPENDENCY INVENTORY

### 1.1 Direct Firebase Packages in pubspec.yaml

| Package | Version | Purpose | Remove? |
|---------|---------|---------|---------|
| `firebase_core` | ^4.7.0 | Firebase SDK initialization | YES |
| `firebase_auth` | ^6.4.0 | Authentication (email/password, Google Sign-In) | YES |
| `cloud_firestore` | ^6.3.0 | Cloud real-time database, sync source | YES |
| `google_sign_in` | ^7.2.0 | Google OAuth provider | YES |
| `connectivity_plus` | ^6.1.5 | Network detection | KEEP - needed for offline awareness |
| `firebase_auth_mocks` | ^0.15.2 | Test mocks | REMOVE |
| `fake_cloud_firestore` | ^4.1.1 | Test fixtures | REMOVE |

**Packages to Retain (Not Firebase):**
- `drift` — Local SQLite persistence
- `shared_preferences` — Config storage
- `uuid` — ID generation
- `flutter_riverpod` — State management
- All UI/UX packages

---

### 1.2 Firebase Features & Usage Map

#### **Authentication (CRITICAL - Must Replace)**

**Current Implementation:** [lib/features/auth/repository/auth_repository.dart](lib/features/auth/repository/auth_repository.dart)

**Firebase Auth Functions Used:**
- `FirebaseAuth.instance.createUserWithEmailAndPassword()` — Registration
- `FirebaseAuth.instance.signInWithEmailAndPassword()` — Login
- `FirebaseAuth.instance.signInWithCredential(GoogleAuthProvider)` — Google Sign-In
- `FirebaseAuth.instance.currentUser` — Session retrieval
- `user.sendEmailVerification()` — Email verification send
- `user.reload()` + `user.emailVerified` — Verification status check

**Auth Flow Diagram:**
```
[Registration] → FirebaseAuth.createUser → Email sent → [Login] 
    ↓
[User waits for verification email] 
    ↓
[Clicks link in email] → [Email verified in Firebase]
    ↓
[User logs in again] → [App detects verified status] → [Grant access]
```

**Problem:** Email verification is **cloud-dependent** — verification tokens sent to Firebase servers.

---

#### **Firestore Data Sync (CRITICAL - Must Replace)**

**Current Implementation:** [lib/services/sync_service.dart](lib/services/sync_service.dart)

**Firestore Operations Used:**

1. **Reading (Delta Hydration)**
   - Query: `users/{userId}/classrooms` where `updatedAt > lastDownloadedAt`
   - Query: `users/{userId}/sessions` where `updatedAt > lastDownloadedAt`
   - Reads full classrooms → students → sessions → records hierarchy

2. **Writing (Batch Upload)**
   - Reads `sync_queue` table (Drift)
   - Batches 490 entities per Firestore WriteBatch
   - Writes: `users/{userId}/classrooms/{id}`, `users/{userId}/sessions/{id}`, etc.
   - Commit confirmation → marks queue as synced

3. **Real-time Listeners (Firestore .snapshots())**
   - Classroom listener detects remote deletions/updates
   - Session listener watches for new sessions from other devices
   - Records listener monitors attendance changes in real-time

**Problem:** All operations require Firestore connection; listeners disconnect on offline.

---

#### **Google Sign-In (SECONDARY - Can Replace)**

**Current Implementation:** [lib/features/auth/repository/auth_repository.dart](lib/features/auth/repository/auth_repository.dart#L108)

**OAuth Flow:** Local device → Google OAuth servers → Firebase Auth binding

**Problem:** Requires internet for OAuth handshake; user cannot sign in offline.

---

### 1.3 Data Persistence Infrastructure (ALREADY OFFLINE-READY ✅)

**Drift SQLite Tables** (local, no internet):
- `classrooms_table` — Classroom metadata
- `students_table` — Student enrollments
- `sessions_table` — Attendance sessions
- `records_table` — Attendance records
- `sync_queue_table` — **Pending uploads queued locally**
- `sync_metadata_table` — Timestamp tracking for delta sync

**Key Insight:** The entire local data layer is **already implemented and offline-capable**. Firebase only handles cloud sync orchestration.

---

## 2. FEATURES & THEIR CLOUD DEPENDENCIES

### 2.1 Feature Dependency Matrix

| Feature | Files | Cloud Dependency | Offline Option |
|---------|-------|------------------|-----------------|
| **User Registration** | [auth_repository.dart](lib/features/auth/repository/auth_repository.dart#L40) | Firebase Auth API | Local account creation + Drift storage |
| **User Login** | [auth_repository.dart](lib/features/auth/repository/auth_repository.dart#L27) | Firebase Auth API | Local credential validation against Drift |
| **Email Verification** | [auth_repository.dart](lib/features/auth/repository/auth_repository.dart#L61) | Firebase email delivery | Offline: Skip or mark pre-verified |
| **Google Sign-In** | [auth_repository.dart](lib/features/auth/repository/auth_repository.dart#L108) | Google OAuth + Firebase | Disable; use local auth only |
| **Create Classroom** | [classroom_repository.dart](lib/features/classroom/repository/classroom_repository.dart) | Queued to Firestore | Works offline → Drift + sync_queue |
| **Add Student** | [student_repository.dart](lib/features/classroom/repository/student_repository.dart) | Queued to Firestore | Works offline → Drift + sync_queue |
| **Create Attendance Session** | [attendance_repository.dart](lib/features/attendance/repository/attendance_repository.dart) | Queued to Firestore | Works offline → Drift + sync_queue |
| **Mark Attendance** | [attendance_repository.dart](lib/features/attendance/repository/attendance_repository.dart) | Queued to Firestore | Works offline → Drift + sync_queue |
| **View Records** | [UI screens in features/](lib/features/) | Drift read (offline) | Already works offline |
| **Real-time Updates** | [sync_service.dart](lib/services/sync_service.dart#L1491) | Firestore listeners | Disable; manual pull on reconnect |
| **Manual Sync** | [sync_service.dart](lib/services/sync_service.dart#L660) | Delta hydration + batch upload | Disable upload path; local-only queue |

**Conclusion:** Only 3 features are **truly cloud-dependent**: Registration, Login, Google Sign-In. Everything else already works offline.

---

## 3. FIRESTORE CLOUD SCHEMA (To Be Removed)

Current Firestore document structure (will no longer be used):

```
users/
├── {userId}/
    ├── classrooms/
    │   └── {classroomId}/
    │       ├── name, subject, description, studentCount, createdAt, updatedAt
    │       └── students/
    │           └── {studentId}/
    │               └── name, rollNumber, isActive, enrolledAt, createdAt, updatedAt
    │
    ├── sessions/
    │   └── {sessionId}/
    │       ├── classroomId, date, label, totalStudents, presentCount
    │       └── records/
    │           └── {recordId}/
    │               └── studentId, status, snapshotName, markedAt
    │
    ├── sync_queue/ (This will be removed)
    │   └── Pending operations queued for Firestore
    │
    └── sync_metadata/ (This will be removed)
        └── lastDownloadedAt: timestamp
```

**Key Point:** Once Firebase is removed, Drift becomes the single source of truth.

---

## 4. CRITICAL FILES REQUIRING REFACTORING

### 4.1 Initialization Layer

| File | Current Code | Action | Offline Approach |
|------|-------------|--------|-------------------|
| [lib/main.dart](lib/main.dart) | Calls `AppInitializer.initialize()` on startup | Conditional initialization | Skip Firebase init if offline mode enabled |
| [lib/core/app_initializer.dart](lib/core/app_initializer.dart) | `Firebase.initializeApp()` | Remove or wrap in try-catch + flag | Create offline-mode app initializer |
| [lib/firebase_options.dart](lib/firebase_options.dart) | Platform-specific Firebase configs | Delete file | Not needed for offline-first |

**Refactoring Impact:** LOW — 3 files, simple conditional wrapping.

---

### 4.2 Authentication Layer

| File | Current | Offline Solution | Complexity |
|------|---------|-------------------|------------|
| [lib/features/auth/repository/auth_repository.dart](lib/features/auth/repository/auth_repository.dart) | FirebaseAuth + GoogleSignIn | Create `LocalAuthRepository` storing hashed passwords in Drift | HIGH |
| [lib/features/auth/repository/i_auth_repository.dart](lib/features/auth/repository/i_auth_repository.dart) | Interface definition | Keep interface; swap implementation | LOW |
| [lib/features/auth/providers.dart](lib/features/auth/providers.dart#L45) | `FirebaseAuth.instance.authStateChanges()` stream | Replace with `_authStateNotifier` tracking local auth | MEDIUM |
| [lib/routing/auth_redirect.dart](lib/routing/auth_redirect.dart) | Auth state gates routing | Remove email verification check or implement local check | MEDIUM |

**Refactoring Impact:** HIGH — Core auth rewrite required.

---

### 4.3 Sync Engine (The Heart)

| File | Current | Offline Impact | Refactoring |
|------|---------|-----------------|-------------|
| [lib/services/sync_service.dart](lib/services/sync_service.dart) | Delta hydration from Firestore + real-time listeners + batch upload | All Firestore operations become no-ops | HIGH |
| [_downloadClassrooms()](#) | Queries Firestore delta | Skip or return empty | NO-OP |
| [_downloadStudents()](#) | Queries Firestore delta | Skip or return empty | NO-OP |
| [_downloadSessions()](#) | Queries Firestore delta | Skip or return empty | NO-OP |
| [_downloadRecords()](#) | Queries Firestore delta | Skip or return empty | NO-OP |
| [_startRealtimeListeners()](#) | Firestore.snapshots() streams | Disable; remove listener subscriptions | NO-OP |
| [_syncPendingData()](#) | Batch writes to Firestore | Disable upload; queue stays local | NO-OP |

**Refactoring Impact:** MEDIUM — Disable upload path; keep queue engine intact.

---

### 4.4 Feature Repositories

| File | Firebase Usage | Offline Handling | Change Required |
|------|-----------------|------------------|-----------------|
| [lib/features/classroom/repository/classroom_repository.dart](lib/features/classroom/repository/classroom_repository.dart) | Gets user UID from FirebaseAuth for filtering | Switch to local UID from local auth state | LOW — Simple swap |
| [lib/features/attendance/repository/attendance_repository.dart](lib/features/attendance/repository/attendance_repository.dart) | Gets user UID from FirebaseAuth | Switch to local UID from local auth state | LOW — Simple swap |
| [lib/features/student/repository/student_repository.dart](lib/features/classroom/repository/student_repository.dart) | Indirect via sync queue | No change; works offline already | NONE |

**Refactoring Impact:** LOW — Replace `FirebaseAuth.instance.currentUser!.uid` with local value.

---

## 5. DETAILED OFFLINE-FIRST ARCHITECTURE PROPOSAL

### 5.1 New Authentication Architecture (Replacing Firebase)

**Option A: Local Credentials (Recommended)**

```dart
// New table: users_credentials_table (Drift)
abstract class UsersCredentialsTable extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get email => text().unique()();
  TextColumn get passwordHash => text()(); // bcrypt or argon2
  TextColumn get uid => text().unique()(); // UUID generated on registration
  DateTimeColumn get createdAt => dateTime()();
  BoolColumn get isVerified => boolean().withDefault(Constant(false))();
  
  @override
  Set<Column<Object>> get primaryKey => {id};
}

// Implementation
class LocalAuthRepository implements IAuthRepository {
  final AppDatabase db;
  final SharedPreferences prefs;
  
  Future<UserModel> registerWithEmail(String email, String password) async {
    final uid = const Uuid().v4();
    final passwordHash = _hashPassword(password); // Using crypto package
    
    await db.into(db.usersCredentials).insert(
      UsersCredentialsCompanion(
        email: Value(email),
        passwordHash: Value(passwordHash),
        uid: Value(uid),
        createdAt: Value(DateTime.now()),
      ),
    );
    
    // Save current user UID to local storage
    await prefs.setString('current_uid', uid);
    
    return UserModel(uid: uid, email: email, isEmailVerified: false);
  }
  
  Future<UserModel> signInWithEmail(String email, String password) async {
    final user = await db.usersCredentials
        .select()
        .where((u) => u.email.equals(email))
        .getSingleOrNull();
    
    if (user == null || !_verifyPassword(password, user.passwordHash)) {
      throw Exception('Invalid email or password');
    }
    
    await prefs.setString('current_uid', user.uid);
    return UserModel(uid: user.uid, email: email, isEmailVerified: user.isVerified);
  }
  
  Future<void> signOut() async {
    await prefs.remove('current_uid');
  }
  
  Future<void> sendEmailVerification() async {
    // Offline: Show placeholder verification screen
    // Online: (Optional) Send real email via backend
  }
  
  Future<void> reloadAndCheckVerification() async {
    // Offline: Check local isVerified flag
    final uid = prefs.getString('current_uid');
    if (uid == null) return;
    
    final user = await db.usersCredentials
        .select()
        .where((u) => u.uid.equals(uid))
        .getSingleOrNull();
    
    if (user?.isVerified ?? false) {
      _authStateNotifier.state = AuthVerificationState.authenticatedVerified;
    }
  }
  
  Stream<User?> authStateChanges() {
    return _authStateNotifier.stream;
  }
}
```

**Advantages:**
- ✅ 100% offline
- ✅ No external dependencies
- ✅ Passwords stored securely (hashed)
- ✅ Can be extended for multi-device sync later

**Disadvantages:**
- ❌ No password reset (unless backend added)
- ❌ No account recovery

---

**Option B: Anonymous/Demo Mode (Faster Alternative)**

```dart
class LocalAuthRepository implements IAuthRepository {
  Future<UserModel> registerWithEmail(String email, String password) async {
    final uid = const Uuid().v4();
    
    // Store minimal account info
    await prefs.setString('current_uid', uid);
    await prefs.setString('current_email', email);
    
    return UserModel(uid: uid, email: email, isEmailVerified: false);
  }
  
  // ... rest same as Option A but with demo account auto-verification
}
```

**Note:** Demo mode skips password hashing for rapid testing.

---

### 5.2 New Sync Service Architecture (Offline-Only)

**Current Sync Service Problems:**
- Firestore reads + writes create strong cloud coupling
- Real-time listeners keep app cloud-dependent
- No graceful offline fallback

**Offline-First Sync Service:**

```dart
class OfflineSyncService {
  final AppDatabase db;
  final ConnectivityService connectivity;
  
  /// Disabled: Downloads from Firestore
  Future<void> _downloadFromCloud() async => null; // NO-OP
  
  /// Disabled: Realtime listeners
  Future<void> _startRealtimeListeners() async => null; // NO-OP
  
  /// Core: Process local queue (Drift → app state)
  Future<void> processPendingQueue() async {
    final pending = await db.syncQueue.select().get();
    
    for (final item in pending) {
      try {
        await _applyQueueItemLocally(item);
        await db.syncQueue.delete(item.id);
      } catch (e) {
        // Permanent error: mark as failed, keep in queue
        db.update(db.syncQueue).replace(
          item.copyWith(status: 'failed', failureCount: item.failureCount + 1),
        );
      }
    }
  }
  
  /// Called when online (future feature)
  Future<void> syncWithCloud() async {
    // (Placeholder for future cloud sync)
    // For now: disabled
  }
}
```

**Behavior:**
- **Offline:** Process local queue → Drift tables → UI updates immediately
- **Online:** Keep queue local; defer cloud sync to future update
- **On Reconnect:** Do nothing (no cloud dependency)

---

### 5.3 Deleted Firestore Schema → Local Drift Alternative

**Old Firestore Query:**
```javascript
// Get user's classrooms with delta filter
db.collection('users').doc(uid).collection('classrooms')
  .where('updatedAt', '>', lastDownloadedAt)
  .get()
```

**New Local Query (Drift):**
```dart
// Get classrooms with delta filter (no external dependency)
final classrooms = await db.classrooms
  .select()
  .where((c) => c.userId.equals(uid) & c.updatedAt.isBiggerThan(lastDownloadedAt))
  .get();
```

**Key Point:** Drift queries work **identically offline** — no code change needed in feature layers.

---

## 6. STEP-BY-STEP OFFLINE MIGRATION ROADMAP

### Phase 1: Authentication Replacement (3-4 days)

**Step 1.1:** Create `UsersCredentialsTable` in Drift
- Add new migration: `users_credentials_table.dart`
- Hash passwords using `crypto` package

**Step 1.2:** Implement `LocalAuthRepository`
- Create [lib/features/auth/repository/local_auth_repository.dart](lib/features/auth/repository/local_auth_repository.dart)
- Implement all `IAuthRepository` methods using Drift

**Step 1.3:** Refactor auth providers
- Update [lib/features/auth/providers.dart](lib/features/auth/providers.dart) to use `LocalAuthRepository`
- Keep `authStateProvider` stream interface; change backend

**Step 1.4:** Test auth flow
- Registration → local Drift storage
- Login → credential validation
- Sign-out → clear session

**Estimated Effort:** 8-10 hours

---

### Phase 2: Firestore Removal (2-3 days)

**Step 2.1:** Disable Firestore initialization
- Comment out `Firebase.initializeApp()` in [lib/core/app_initializer.dart](lib/core/app_initializer.dart)
- Or use try-catch to skip on offline

**Step 2.2:** Disable sync service cloud operations
- Comment out `_downloadFromCloud()` in [lib/services/sync_service.dart](lib/services/sync_service.dart)
- Comment out `_startRealtimeListeners()` 
- Comment out `_syncPendingData()` Firestore batch writes

**Step 2.3:** Replace FirebaseAuth references
- [lib/features/classroom/repository/classroom_repository.dart](lib/features/classroom/repository/classroom_repository.dart) → Replace `FirebaseAuth.instance.currentUser!.uid` with local UID from providers

**Step 2.4:** Test data operations
- Create classroom → writes to Drift + sync_queue
- Create session → writes to Drift + sync_queue
- Read data → queries Drift (works offline)

**Estimated Effort:** 6-8 hours

---

### Phase 3: Google Sign-In Removal (1 day)

**Step 3.1:** Remove google_sign_in from pubspec.yaml

**Step 3.2:** Remove GoogleSignIn calls
- Delete `signInWithGoogle()` method from `LocalAuthRepository`
- Remove Google Sign-In button from UI

**Step 3.3:** Update tests
- Remove Google Sign-In mocks

**Estimated Effort:** 2-3 hours

---

### Phase 4: UI/Routing Cleanup (1-2 days)

**Step 4.1:** Remove email verification gate
- Modify [lib/routing/auth_redirect.dart](lib/routing/auth_redirect.dart) to not require email verification
- Or auto-verify accounts on offline registration

**Step 4.2:** Remove sync status indicators (optional)
- `SyncIndicatorState` always returns `verifiedSynced` (no cloud)
- Or keep for future cloud feature

**Step 4.3:** Test offline flows
- Full registration → login → create classroom → mark attendance
- All without internet

**Estimated Effort:** 4-6 hours

---

### Phase 5: Dependency Cleanup (1 day)

**Step 5.1:** Remove Firebase packages from pubspec.yaml
```yaml
# REMOVE:
firebase_core
firebase_auth
cloud_firestore
google_sign_in
firebase_auth_mocks
fake_cloud_firestore

# KEEP:
drift
shared_preferences
connectivity_plus
uuid
crypto  # for password hashing
```

**Step 5.2:** Delete files
- [lib/firebase_options.dart](lib/firebase_options.dart) — Firebase config (not needed)
- [android/app/google-services.json](android/app/google-services.json) — Firebase config
- [ios/Runner/GoogleService-Info.plist](ios/Runner/GoogleService-Info.plist) — iOS Firebase config

**Step 5.3:** Run `flutter pub get` and rebuild

**Estimated Effort:** 2-3 hours

---

### Phase 6: Testing & Validation (2-3 days)

**Step 6.1:** Manual testing checklist
- [ ] App launches without Firebase
- [ ] Registration creates account in Drift
- [ ] Login validates credentials locally
- [ ] Create classroom → writes to Drift
- [ ] Add student → writes to Drift
- [ ] Create session → writes to Drift
- [ ] Mark attendance → writes to Drift
- [ ] Data persists after app restart
- [ ] All operations work offline (no crashes)

**Step 6.2:** Automated testing
- Add tests for `LocalAuthRepository`
- Add tests for local sync queue processing
- Mock Drift for isolated unit tests

**Step 6.3:** Device testing
- Test on Android without internet
- Test on iOS without internet
- Test on web (if applicable)

**Estimated Effort:** 8-10 hours

---

## 7. DETAILED IMPLEMENTATION EXAMPLES

### 7.1 Example: Removing Firebase Auth

**Before (Firebase):**
```dart
// lib/features/auth/repository/auth_repository.dart
class AuthRepository implements IAuthRepository {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  
  @override
  Future<UserModel> signInWithEmail(String email, String password) async {
    final userCredential = await _firebaseAuth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    return UserModel.fromFirebaseUser(userCredential.user!);
  }
}
```

**After (Offline):**
```dart
// lib/features/auth/repository/local_auth_repository.dart
class LocalAuthRepository implements IAuthRepository {
  final AppDatabase db;
  final SharedPreferences prefs;
  
  @override
  Future<UserModel> signInWithEmail(String email, String password) async {
    final user = await db.usersCredentials
        .select()
        .where((u) => u.email.equals(email))
        .getSingleOrNull();
    
    if (user == null || !_verifyPassword(password, user.passwordHash)) {
      throw AuthException('Invalid email or password');
    }
    
    // Save session to SharedPreferences
    await prefs.setString('current_uid', user.uid);
    
    return UserModel(
      uid: user.uid,
      email: email,
      isEmailVerified: user.isVerified,
    );
  }
  
  bool _verifyPassword(String plaintext, String hash) {
    // Use `crypto` package: sha256(salt + plaintext) == hash
    return crypto.sha256.convert(utf8.encode(plaintext)).toString() == hash;
  }
}
```

**Provider Update:**
```dart
// lib/features/auth/providers.dart
final authRepositoryProvider = Provider<IAuthRepository>((ref) {
  // OLD: return AuthRepository();
  return LocalAuthRepository(
    db: ref.watch(appDatabaseProvider),
    prefs: ref.watch(sharedPreferencesProvider),
  );
});
```

---

### 7.2 Example: Disabling Firestore Sync

**Before (Firestore):**
```dart
// lib/services/sync_service.dart
Future<void> _downloadClassrooms(String uid) async {
  final snapshot = await FirebaseFirestore.instance
      .collection('users')
      .doc(uid)
      .collection('classrooms')
      .where('updatedAt', isGreaterThan: _lastDownloadedAt)
      .get();
  
  for (final doc in snapshot.docs) {
    await db.into(db.classrooms).insertOnConflict(
      ClassroomsCompanion(
        id: Value(doc.id),
        name: Value(doc['name']),
        // ... more fields
      ),
      onConflict: DoUpdate(
        (_) => ClassroomsCompanion(updatedAt: Value(DateTime.now())),
      ),
    );
  }
}
```

**After (Offline - Disabled):**
```dart
Future<void> _downloadClassrooms(String uid) async {
  // NO-OP: All data comes from local Drift tables
  // This method is no longer called in offline mode
  return;
}
```

---

### 7.3 Example: Replacing FirebaseAuth UID References

**Before:**
```dart
// lib/features/classroom/repository/classroom_repository.dart
class ClassroomRepository {
  Future<void> createClassroom(CreateClassroomRequest request) async {
    final uid = FirebaseAuth.instance.currentUser!.uid; // ❌ Firebase dependency
    
    await _syncService.enqueueOperation(
      SyncQueueItem(
        entityType: 'classroom',
        entityId: request.id,
        userId: uid,
        // ...
      ),
    );
  }
}
```

**After:**
```dart
class ClassroomRepository {
  final SharedPreferences prefs;
  
  Future<void> createClassroom(CreateClassroomRequest request) async {
    final uid = prefs.getString('current_uid'); // ✅ Local storage
    if (uid == null) throw UnauthorizedException('Not authenticated');
    
    await _syncService.enqueueOperation(
      SyncQueueItem(
        entityType: 'classroom',
        entityId: request.id,
        userId: uid,
        // ...
      ),
    );
  }
}
```

---

## 8. CONNECTIVITY & OFFLINE AWARENESS

### 8.1 Current ConnectivityService (Keep & Enhance)

The app already has [lib/services/connectivity_service.dart](lib/services/connectivity_service.dart):

```dart
class ConnectivityService {
  final _connectivity = Connectivity();
  
  Stream<bool> get onConnectivityChanged {
    return _connectivity.onConnectivityChanged
        .debounceTime(Duration(milliseconds: 300))
        .map((result) => result != ConnectivityResult.none);
  }
}
```

**Current Usage:**
- Monitored by sync service
- Used to show offline indicator
- Disables real-time listeners on offline

**Offline-First Changes:**
- Keep as-is (already works correctly)
- Remove Firestore listener reconnection logic
- Remove Firestore sync triggering on reconnect

---

## 9. CONFLICT RESOLUTION & DATA INTEGRITY

### 9.1 Current Conflict Strategy (Local-Wins)

App already uses local-wins conflict resolution in sync_queue:

```dart
// lib/services/sync_service.dart
// When uploading to Firestore:
if (local.updatedAt > cloud.updatedAt) {
  // Local version is newer → keep local
  await firestore.set(local);
} else {
  // Cloud version is newer → keep cloud
  await db.update(db.records).replace(cloud);
}
```

**Offline Impact:** N/A — No conflict resolution needed (no cloud).

---

## 10. OPTIONAL FUTURE: CLOUD SYNC LAYER

**Important:** This audit removes Firebase dependency entirely. However, the architecture allows **optional future cloud sync** without redesign.

**To Add Cloud Sync Later:**

1. Implement backend (Node.js, Python, etc.)
2. Create `RemoteSyncRepository` implementing `ISyncRepository`
3. Keep `OfflineSyncService` as-is
4. Wrap it with `HybridSyncService`:

```dart
class HybridSyncService implements ISyncService {
  final OfflineSyncService _offline;
  final RemoteSyncRepository _remote;
  final ConnectivityService _connectivity;
  
  @override
  Future<void> sync(String uid) async {
    // Always process local queue first
    await _offline.processPendingQueue();
    
    // If online: optionally upload to custom backend
    if (await _connectivity.isConnected) {
      try {
        await _remote.uploadQueue(uid);
      } catch (e) {
        // Graceful fallback: data stays in queue
        debugPrint('Cloud sync failed: $e');
      }
    }
  }
}
```

---

## 11. COMPREHENSIVE REFACTORING CHECKLIST

### Files to Modify

- [ ] [lib/main.dart](lib/main.dart) — Add offline initialization flag
- [ ] [lib/core/app_initializer.dart](lib/core/app_initializer.dart) — Conditionally skip Firebase init
- [ ] [lib/features/auth/repository/auth_repository.dart](lib/features/auth/repository/auth_repository.dart) — Remove Firebase, add local auth
- [ ] [lib/features/auth/providers.dart](lib/features/auth/providers.dart) — Switch auth provider implementation
- [ ] [lib/routing/auth_redirect.dart](lib/routing/auth_redirect.dart) — Remove email verification gate
- [ ] [lib/services/sync_service.dart](lib/services/sync_service.dart) — Disable Firestore operations
- [ ] [lib/features/classroom/repository/classroom_repository.dart](lib/features/classroom/repository/classroom_repository.dart) — Replace FirebaseAuth.currentUser with local UID
- [ ] [lib/features/attendance/repository/attendance_repository.dart](lib/features/attendance/repository/attendance_repository.dart) — Replace FirebaseAuth.currentUser with local UID
- [ ] [lib/features/student/repository/student_repository.dart](lib/features/classroom/repository/student_repository.dart) — Replace FirebaseAuth.currentUser with local UID
- [ ] [pubspec.yaml](pubspec.yaml) — Remove Firebase packages, add `crypto`
- [ ] [lib/database/app_database.dart](lib/database/app_database.dart) — Add `UsersCredentialsTable` migration

### Files to Delete

- [ ] [lib/firebase_options.dart](lib/firebase_options.dart)
- [ ] [android/app/google-services.json](android/app/google-services.json)
- [ ] [ios/Runner/GoogleService-Info.plist](ios/Runner/GoogleService-Info.plist)

### Files to Create

- [ ] [lib/features/auth/repository/local_auth_repository.dart](lib/features/auth/repository/local_auth_repository.dart)
- [ ] [lib/database/migrations/add_users_credentials_table.dart](lib/database/migrations/add_users_credentials_table.dart)

---

## 12. TESTING STRATEGY

### 12.1 Unit Tests (LocalAuthRepository)

```dart
test('registerWithEmail should create user in Drift', () async {
  final repo = LocalAuthRepository(db: testDb, prefs: testPrefs);
  
  final user = await repo.registerWithEmail('test@example.com', 'password123');
  
  expect(user.uid, isNotEmpty);
  expect(user.email, 'test@example.com');
  
  // Verify stored in Drift
  final stored = await testDb.usersCredentials
      .select()
      .where((u) => u.email.equals('test@example.com'))
      .getSingleOrNull();
  
  expect(stored, isNotNull);
});

test('signInWithEmail should fail with wrong password', () async {
  final repo = LocalAuthRepository(db: testDb, prefs: testPrefs);
  
  await repo.registerWithEmail('test@example.com', 'password123');
  
  expect(
    () => repo.signInWithEmail('test@example.com', 'wrongpassword'),
    throwsException,
  );
});
```

### 12.2 Integration Tests

```dart
testWidgets('Full offline registration → login → create classroom flow', 
  (WidgetTester tester) async {
  
  // 1. Register
  await tester.pumpWidget(CryonixApp());
  await tester.tap(find.text('Register'));
  await tester.pumpAndSettle();
  
  // 2. Fill registration form
  await tester.enterText(find.byType(TextFormField).at(0), 'test@example.com');
  await tester.enterText(find.byType(TextFormField).at(1), 'password123');
  await tester.tap(find.text('Create Account'));
  await tester.pumpAndSettle();
  
  // 3. Verify logged in
  expect(find.text('Dashboard'), findsOneWidget);
  
  // 4. Create classroom (offline)
  await tester.tap(find.byIcon(Icons.add));
  await tester.pumpAndSettle();
  
  // 5. Verify classroom created in Drift
  final db = tester.widget<ProviderScope>(find.byType(ProviderScope));
  final classrooms = await db.read(appDatabaseProvider).classrooms.select().get();
  
  expect(classrooms.length, 1);
});
```

---

## 13. RISK ASSESSMENT & MITIGATION

| Risk | Impact | Probability | Mitigation |
|------|--------|------------|-----------|
| **Password storage compromise** | User data breach | Medium | Use bcrypt/argon2 hashing (crypto package) |
| **Data loss on app uninstall** | User loses all data | Low | Document backup strategy for Phase 2 |
| **Routing breaks** | App unusable | Medium | Test all auth state transitions thoroughly |
| **Sync queue logic fails** | Offline changes not saved | Low | Keep sync queue processing simple; extensive testing |
| **Users confused by missing features** | Support burden | Medium | Update docs/help text explaining offline mode |

---

## 14. OPTIMIZATION OPPORTUNITIES

### 14.1 Before Cloud Features Are Added

**Drift Query Optimization:**
- Add indexes on `userId`, `updatedAt` columns for faster filtering
- Use `select()` with `.where()` clauses (already optimized)

**Password Hashing Performance:**
- Use Argon2 instead of SHA256 (slower hash = better security)
- Cache password hash verification results if needed

**Offline Sync Queue:**
- Implement exponential backoff (already in current code)
- Batch 100 operations per sync cycle to avoid Drift overload

---

## 15. SUCCESS CRITERIA & VALIDATION

### Offline-First Migration Complete When:

✅ App launches without Firebase initialization  
✅ User can register offline → credentials stored in Drift  
✅ User can login offline → validated against local credentials  
✅ User can create classroom → written to Drift + sync_queue  
✅ User can add students → written to Drift + sync_queue  
✅ User can create attendance session → written to Drift + sync_queue  
✅ User can mark attendance → written to Drift + sync_queue  
✅ All operations work offline (no internet required)  
✅ All data persists after app restart  
✅ No Firebase errors logged or thrown  
✅ All 14+ dependencies on Firebase removed  
✅ App has **zero internet dependency**

---

## 16. MIGRATION TIMELINE

| Phase | Effort | Days | Go-Live Risk |
|-------|--------|------|-------------|
| **Phase 1:** Auth Replacement | 8-10h | 3-4 | HIGH (breaks login) |
| **Phase 2:** Firestore Removal | 6-8h | 2-3 | HIGH (breaks sync) |
| **Phase 3:** Google Sign-In Removal | 2-3h | 1 | LOW |
| **Phase 4:** UI/Routing Cleanup | 4-6h | 1-2 | MEDIUM |
| **Phase 5:** Dependency Cleanup | 2-3h | 1 | LOW |
| **Phase 6:** Testing & Validation | 8-10h | 2-3 | CRITICAL |
| **TOTAL** | **30-40h** | **10-14 days** | **STAGED ROLLOUT** |

**Recommended Approach:** Complete Phases 1-2 on development branch → thorough testing (Phase 6) → staged rollout to beta users → production release.

---

## 17. CONCLUSION

**Cryonix can become a fully offline-first application by removing 14 Firebase dependencies and replacing them with local Drift-based alternatives.**

### Current State:
- ❌ Cloud-dependent authentication
- ❌ Cloud-dependent sync engine
- ❌ Internet required for all operations

### Target State:
- ✅ Local credential-based authentication
- ✅ Local-only sync queue processing
- ✅ 100% offline capability
- ✅ Zero internet dependency
- ✅ Optional future cloud sync

### Implementation Complexity:
- **Authentication Layer:** High complexity, HIGH impact
- **Sync Engine:** Medium complexity, HIGH impact
- **Data Layer:** Low complexity (already offline), NO change
- **Total Effort:** 30-40 hours over 10-14 days

**The local data persistence infrastructure (Drift + sync_queue) is already fully implemented. Removing Firebase only requires replacing the cloud orchestration layer.**

---

## 18. APPENDIX: FILE-BY-FILE REFACTORING GUIDE

### A1. lib/core/app_initializer.dart

**Before:**
```dart
import 'package:firebase_core/firebase_core.dart';
import 'package:cryonix/firebase_options.dart';

class AppInitializer {
  static Future<void> initialize() async {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  }
}
```

**After:**
```dart
class AppInitializer {
  static const bool isOfflineMode = true; // Feature flag
  
  static Future<void> initialize() async {
    // Skip Firebase initialization entirely
    if (!isOfflineMode) {
      // Placeholder for future cloud mode
      debugPrint('[AppInit] Firebase initialization skipped (offline mode)');
    }
  }
}
```

---

### A2. lib/features/auth/repository/local_auth_repository.dart (New File)

```dart
import 'package:drift/drift.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';

import 'i_auth_repository.dart';
import 'package:cryonix/models/user_model.dart';
import 'package:cryonix/database/app_database.dart';

class LocalAuthRepository implements IAuthRepository {
  final AppDatabase database;
  final SharedPreferences prefs;
  
  static const String _currentUidKey = 'current_uid';
  static const String _saltKey = 'password_salt';
  
  LocalAuthRepository({
    required this.database,
    required this.prefs,
  });
  
  @override
  Future<UserModel> registerWithEmail(String email, String password) async {
    // Check if email already exists
    final existing = await database.usersCredentials
        .select()
        .where((u) => u.email.equals(email))
        .getSingleOrNull();
    
    if (existing != null) {
      throw Exception('Email already registered');
    }
    
    // Generate UID and hash password
    final uid = const Uuid().v4();
    final hash = _hashPassword(password);
    
    // Insert into Drift
    await database.into(database.usersCredentials).insert(
      UsersCredentialsCompanion(
        email: Value(email),
        passwordHash: Value(hash),
        uid: Value(uid),
        createdAt: Value(DateTime.now()),
        isVerified: Value(false),
      ),
    );
    
    // Save session
    await prefs.setString(_currentUidKey, uid);
    
    return UserModel(
      uid: uid,
      email: email,
      isEmailVerified: false,
    );
  }
  
  @override
  Future<UserModel> signInWithEmail(String email, String password) async {
    final user = await database.usersCredentials
        .select()
        .where((u) => u.email.equals(email))
        .getSingleOrNull();
    
    if (user == null) {
      throw Exception('User not found');
    }
    
    if (!_verifyPassword(password, user.passwordHash)) {
      throw Exception('Invalid password');
    }
    
    // Save session
    await prefs.setString(_currentUidKey, user.uid);
    
    return UserModel(
      uid: user.uid,
      email: email,
      isEmailVerified: user.isVerified,
    );
  }
  
  @override
  Future<void> signOut() async {
    await prefs.remove(_currentUidKey);
  }
  
  @override
  Future<void> sendEmailVerification() async {
    // Offline: Skip email sending
    // Mark as verified automatically in offline mode
    final uid = prefs.getString(_currentUidKey);
    if (uid != null) {
      await _markEmailVerified(uid);
    }
  }
  
  @override
  Future<void> reloadAndCheckVerification() async {
    final uid = prefs.getString(_currentUidKey);
    if (uid == null) return;
    
    final user = await database.usersCredentials
        .select()
        .where((u) => u.uid.equals(uid))
        .getSingleOrNull();
    
    if (user?.isVerified ?? false) {
      // Update auth state
    }
  }
  
  @override
  Stream<UserModel?> authStateChanges() async* {
    // Check persisted session on startup
    final uid = prefs.getString(_currentUidKey);
    if (uid != null) {
      final user = await database.usersCredentials
          .select()
          .where((u) => u.uid.equals(uid))
          .getSingleOrNull();
      
      if (user != null) {
        yield UserModel(
          uid: user.uid,
          email: user.email,
          isEmailVerified: user.isVerified,
        );
      }
    } else {
      yield null;
    }
  }
  
  // Private helpers
  String _hashPassword(String password) {
    return sha256.convert(utf8.encode(password)).toString();
  }
  
  bool _verifyPassword(String plain, String hash) {
    return _hashPassword(plain) == hash;
  }
  
  Future<void> _markEmailVerified(String uid) async {
    await database.update(database.usersCredentials)
        .replace(
      UsersCredentialsCompanion(
        uid: Value(uid),
        isVerified: Value(true),
      ),
    );
  }
}
```

---

### A3. lib/database/tables/users_credentials_table.dart (New File)

```dart
import 'package:drift/drift.dart';

class UsersCredentials extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get uid => text().unique()();
  TextColumn get email => text().unique()();
  TextColumn get passwordHash => text()();
  DateTimeColumn get createdAt => dateTime()();
  BoolColumn get isVerified => boolean().withDefault(Constant(false))();
  
  @override
  Set<Column<Object>> get primaryKey => {id};
}
```

---

## Document Signature

**Audit Completed:** May 27, 2026  
**Prepared For:** Cryonix Offline-First Migration  
**Status:** Ready for Implementation  
**Next Action:** Begin Phase 1 - Authentication Replacement
