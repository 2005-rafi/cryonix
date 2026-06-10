/// Database-layer constants: schema versioning, query limits, maintenance.
class DatabaseConstants {
  /// Current Drift schema version. Update when tables change.
  static const int currentSchemaVersion = 11;

  /// Maximum number of sessions loaded in a single paginated query.
  static const int sessionPageSize = 20;

  /// Maximum sessions reconciled during startup self-healing.
  static const int reconcileSessionLimit = 30;

  /// Age (in days) after which soft-deleted sessions are permanently purged.
  static const int softDeletePurgeDays = 30;

  /// Stale in-progress sync entries older than this are reset to pending.
  static const int staleInProgressMinutes = 10;
}
