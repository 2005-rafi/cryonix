/// T 7.2 — Centralized UI string constants for i18n readiness.
///
/// All string literals used in widget build methods are extracted here.
/// Grouped by feature. Dynamic strings (with parameters) are static methods,
/// not constants. When full l10n is added, only this file needs updating.
abstract final class AppStrings {
  // ── Common ──────────────────────────────────────────────────────────────────
  static const String appName = 'Cryonix';
  static const String cancel = 'Cancel';
  static const String save = 'Save';
  static const String delete = 'Delete';
  static const String edit = 'Edit';
  static const String retry = 'Retry';
  static const String loading = 'Loading…';
  static const String unknown = 'Unknown';
  static const String errorPrefix = 'Error: ';
  static String error(Object e) => 'Error: $e';

  // ── Auth ────────────────────────────────────────────────────────────────────
  static const String signIn = 'Sign In';
  static const String signOut = 'Sign Out';
  static const String signInWithGoogle = 'Sign in with Google';
  static const String createAccount = 'Create Account';
  static const String forgotPassword = 'Forgot password?';
  static const String emailLabel = 'Email';
  static const String passwordLabel = 'Password';
  static const String verificationPending = 'Verification Pending';
  static const String verificationSent =
      'A verification email has been sent. Please check your inbox.';
  static const String resendEmail = 'Resend Email';

  // ── Classroom ────────────────────────────────────────────────────────────────
  static const String newClassroom = 'New Classroom';
  static const String editClassroom = 'Edit Classroom';
  static const String createClassroom = 'Create Classroom';
  static const String saveChanges = 'Save Changes';
  static const String classroomName = 'Classroom Name';
  static const String classroomNameHint = 'e.g. Grade 10A';
  static const String subject = 'Subject';
  static const String subjectHint = 'Optional';
  static const String noClassroomsTitle = 'No classrooms yet';
  static const String noClassroomsBody =
      'Create your first classroom to get started.';
  static const String deleteClassroomTitle = 'Delete Classroom';
  static String deleteClassroomMessage(String name) =>
      'Delete "$name"? All students and records will be permanently removed.';
  static const String quitTitle = 'Quit Cryonix?';
  static const String quitMessage =
      'Are you sure you want to exit the application?';
  static const String quit = 'Quit';
  static const String notSignedIn = 'Not signed in';
  static const String required = 'Required';

  // ── Attendance ───────────────────────────────────────────────────────────────
  static const String attendanceTitle = 'Attendance';
  static const String sessionSetup = 'Session Setup';
  static const String startSession = 'Start Session';
  static const String saveSession = 'Save Session';
  static const String dateLabel = 'Date';
  static const String sessionLabel = 'Label';
  static const String customLabel = 'Custom Label';
  static const String sessionsToday = 'Sessions Today';
  static const String noStudents = 'No students in this classroom.';
  static const String sessionAlreadyExists = 'Session Already Exists';
  static const String sessionAlreadyExistsBody =
      'A session already exists for this date. View it or choose a different date.';
  static const String viewExisting = 'View Existing';
  static const String duplicateLabelWarning =
      'A session with this label already exists today.';
  static const String sessionDetails = 'Session Details';
  static const String noRecords = 'No records found.';
  static const String recordsFinal =
      'Records are final. Retake attendance to make corrections.';
  static String attendanceRate(String rate) => '$rate% attendance rate';
  static String savedSummary(int p, int a, int od) =>
      'Saved — $p Present · $a Absent · $od On-Duty';

  // ── History ──────────────────────────────────────────────────────────────────
  static const String noSessionsTitle = 'No sessions yet';
  static const String noSessionsBody = 'Saved sessions will appear here.';
  static const String recentlyDeleted = 'Recently Deleted';
  static const String recentlyDeletedFootnote =
      'Sessions are permanently removed after 30 days.';
  static const String noRecentlyDeleted = 'No recently deleted sessions.';
  static const String deleteSessionTitle = 'Delete Session?';
  static String deleteSessionMessage(String date) =>
      'This will delete the session on $date and its attendance records. '
      'It can be restored within 30 days.';
  static const String movedToDeleted = 'Session moved to recently deleted';
  static const String sessionRestored = 'Session restored';

  // ── Profile ──────────────────────────────────────────────────────────────────
  static const String profileTitle = 'Profile';
  static const String syncStatus = 'Sync Status';
  static const String theme = 'Theme';
  static const String darkMode = 'Dark Mode';
  static const String lightMode = 'Light Mode';
  static const String systemDefault = 'System Default';
  static const String deleteAccount = 'Delete Account';
  static const String deleteAccountTitle = 'Delete Account?';
  static const String deleteAccountMessage =
      'This action is irreversible. All your data will be permanently deleted.';

  // ── Sync ─────────────────────────────────────────────────────────────────────
  static const String syncOffline = 'Offline';
  static const String syncAllSynced = 'All data synced';
  static const String syncPending = 'Sync pending — tap for details';
  static const String syncError = 'Sync error — tap for details';
  static const String syncSyncing = 'Syncing\u2026 Tap for details';
  static const String syncViewDetails = 'View sync status';

  // ── Errors ───────────────────────────────────────────────────────────────────
  static const String startupInterrupted = 'Startup Interrupted';
  static const String startupError =
      'An unknown error occurred during database initialization.';
  static const String retryStartup = 'Retry Startup';
  static const String fatalStartupError = 'Fatal Startup Error';
  static const String initializingApp = 'Initializing Cryonix…';

  // ── Students ─────────────────────────────────────────────────────────────────
  static const String addStudent = 'Add Student';
  static const String rollNumber = 'Roll Number';
  static const String studentName = 'Student Name';
  static const String importStudents = 'Import from CSV';
  static String importSuccess(int count) => 'Imported $count students';
  static String importSkipped(int count) => '$count duplicate(s) skipped';
  static const String rollAlreadyExists =
      'Roll number already exists in this classroom';
}
