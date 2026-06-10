/// Network, sync, and timing-related constants.
class NetworkConstants {
  /// Debounce duration before triggering a sync after connectivity change.
  static const Duration connectivityDebounce = Duration(seconds: 3);

  /// Periodic sync check interval while app is in foreground.
  static const Duration syncCheckInterval = Duration(minutes: 5);

  /// Maximum number of sync entries processed in a single batch.
  static const int syncBatchSize = 20;

  /// Firestore collection paths.
  static const String usersCollection = 'users';
  static const String classroomsCollection = 'classrooms';
  static const String studentsCollection = 'students';
  static const String sessionsCollection = 'sessions';
  static const String recordsCollection = 'records';
}
