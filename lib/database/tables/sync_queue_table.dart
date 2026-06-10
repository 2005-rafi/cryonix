import 'package:drift/drift.dart';

// Phase 3 — Task 3.1 & 3.2:
// • Added `nextRetryAt`     — earliest epoch-ms at which this entry may retry.
// • Added `backoffLevel`    — which tier of the exponential backoff schedule.
// • Added `failureCategory` — distinguishes transient vs permanent failures.
// • status CHECK extended   — includes 'permanent_error'.
// • Hard retry cap (retryCount >= 5) is REMOVED — time-based expiry is used.

@TableIndex(name: 'idx_syncqueue_pending', columns: {#status, #entityType})
@TableIndex(name: 'idx_syncqueue_entityId', columns: {#entityType, #entityId})
@TableIndex(name: 'idx_syncqueue_nextRetry', columns: {#status, #nextRetryAt})
@DataClassName('SyncQueueEntry')
class SyncQueueTable extends Table {
  TextColumn get id => text().named('id')();
  TextColumn get entityType => text()();
  TextColumn get entityId => text()();
  TextColumn get operation => text()
      .withDefault(const Constant('upsert'))
      .customConstraint("NOT NULL CHECK(operation IN ('upsert','delete'))")();
  TextColumn get status => text()
      .withDefault(const Constant('pending'))
      .customConstraint(
        "NOT NULL CHECK(status IN ('pending','in_progress','failed','permanent_error'))",
      )();

  /// Number of retry attempts. No longer used as a hard cap.
  /// Retained for debugging / observability purposes.
  IntColumn get retryCount => integer().withDefault(const Constant(0))();

  /// Epoch milliseconds — earliest time this entry may be retried.
  /// 0 means "retry immediately". Updated on each failure.
  IntColumn get nextRetryAt => integer().withDefault(const Constant(0))();

  /// Which tier of the backoff schedule this entry is on (0–6+).
  IntColumn get backoffLevel => integer().withDefault(const Constant(0))();

  /// 'transient' = network error — safe to retry with backoff.
  /// 'permanent' = Firestore permission/validation error — do not retry.
  /// null        = no failure yet.
  TextColumn get failureCategory => text().nullable()();

  /// Group key for batched operations (e.g. session+records, student imports).
  TextColumn get groupKey => text().nullable()();

  /// JSON metadata for special sync operations (e.g. cascade delete manifests).
  TextColumn get payload => text().nullable()();

  /// JSON representing the entity content at enqueue time (Phase 1).
  TextColumn get pendingPayload => text().nullable()();

  /// UUID lock for active sync session (Phase 1).
  TextColumn get syncSessionId => text().nullable()();

  DateTimeColumn get enqueuedAt => dateTime()();
  DateTimeColumn get lastAttemptAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};

  @override
  List<Set<Column>> get uniqueKeys => [
        {entityType, entityId},
      ];
}
