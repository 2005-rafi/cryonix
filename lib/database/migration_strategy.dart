import 'package:drift/drift.dart';
import 'package:cryonix/database/app_database.dart';

/// Holds all schema migration logic for [AppDatabase].
///
/// Each schema version jump is handled by a dedicated private static method.
/// When [AppDatabase] needs a new schema version, a developer adds a new
/// private method here and one line to [build]'s `onUpgrade` callback —
/// [AppDatabase] itself is not touched.
///
/// This keeps [AppDatabase] small and stable while migration history is
/// clearly visible as named methods in this file.
class AppMigrationStrategy {
  AppMigrationStrategy._(); // prevent instantiation

  /// Builds the Drift [MigrationStrategy] for [AppDatabase.migration].
  static MigrationStrategy build(AppDatabase db) {
    return MigrationStrategy(
      onCreate: (Migrator m) async {
        await m.createAll();
      },
      onUpgrade: (Migrator m, int from, int to) async {
        if (from < 5) await _migrateToV5(m, db);
        if (from < 6) await _migrateToV6(m, db);
        if (from < 7) await _migrateToV7(m, db);
        if (from < 8) await _migrateToV8(m, db);
        if (from < 9) await _migrateToV9(m, db);
        if (from < 10) await _migrateToV10(m, db, from);
        if (from < 11) await _migrateToV11(m, db);
        if (from < 12) await _migrateToV12(m, db);
        if (from < 13) await _migrateToV13(m, db);
        if (from < 14) await _migrateToV14(m, db);
        if (from < 15) await _migrateToV15(m, db);
        if (from < 16) await _migrateToV16(m);
      },
      beforeOpen: (details) async {
        await db.customStatement('PRAGMA foreign_keys = ON;');
        await db.customStatement('PRAGMA journal_mode = WAL;');
      },
    );
  }

  // ── v1–v4 → v5 ───────────────────────────────────────────────────────────
  static Future<void> _migrateToV5(Migrator m, AppDatabase db) async {
    // ignore: experimental_member_use
    await m.alterTable(TableMigration(
      db.attendanceSessionsTable,
      columnTransformer: {
        db.attendanceSessionsTable.createdAt: currentDateAndTime,
        db.attendanceSessionsTable.totalStudents: const Constant<int>(0),
        db.attendanceSessionsTable.presentCount: const Constant<int>(0),
        db.attendanceSessionsTable.absentCount: const Constant<int>(0),
        db.attendanceSessionsTable.onDutyCount: const Constant<int>(0),
      },
    ));
    // ignore: experimental_member_use
    await m.alterTable(TableMigration(
      db.studentsTable,
      columnTransformer: {
        db.studentsTable.isActive: const Constant<bool>(true),
        db.studentsTable.enrolledAt: currentDateAndTime,
        db.studentsTable.deletedAt: const CustomExpression('NULL'),
        db.studentsTable.createdAt: currentDateAndTime,
      },
    ));
    // ignore: experimental_member_use
    await m.alterTable(TableMigration(
      db.attendanceRecordsTable,
      columnTransformer: {
        db.attendanceRecordsTable.snapshotName: const Constant<String>('Unknown'),
        db.attendanceRecordsTable.snapshotRoll: const Constant<String>('Unknown'),
      },
    ));
    // ignore: experimental_member_use
    await m.alterTable(TableMigration(
      db.classroomsTable,
      columnTransformer: {
        db.classroomsTable.description: const CustomExpression('NULL'),
        db.classroomsTable.studentCount: const Constant<int>(0),
        db.classroomsTable.updatedAt: currentDateAndTime,
      },
    ));
    await m.createTable(db.syncQueueTable);
  }

  // ── v5 → v6 ──────────────────────────────────────────────────────────────
  static Future<void> _migrateToV6(Migrator m, AppDatabase db) async {
    await m.drop(db.attendanceRecordsTable);
    await m.createTable(db.attendanceRecordsTable);
    await m.drop(db.syncQueueTable);
    await m.createTable(db.syncQueueTable);
  }

  // ── v6 → v7 ──────────────────────────────────────────────────────────────
  static Future<void> _migrateToV7(Migrator m, AppDatabase db) async {
    await m.drop(db.attendanceSessionsTable);
    await m.createTable(db.attendanceSessionsTable);
    await m.drop(db.syncQueueTable);
    await m.createTable(db.syncQueueTable);
  }

  // ── v7 → v8 ──────────────────────────────────────────────────────────────
  static Future<void> _migrateToV8(Migrator m, AppDatabase db) async {
    await m.createIndex(Index(
      'attendance_sessions',
      'CREATE INDEX idx_sessions_id_date ON attendance_sessions (id, date)',
    ));
  }

  // ── v8 → v9 ──────────────────────────────────────────────────────────────
  static Future<void> _migrateToV9(Migrator m, AppDatabase db) async {
    await m.drop(db.syncQueueTable);
    await m.createTable(db.syncQueueTable);
    // ignore: experimental_member_use
    await m.alterTable(TableMigration(
      db.studentsTable,
      columnTransformer: {
        db.studentsTable.updatedAt: currentDateAndTime,
      },
    ));
  }

  // ── v9 → v10 ─────────────────────────────────────────────────────────────
  static Future<void> _migrateToV10(
      Migrator m, AppDatabase db, int from) async {
    final transformer = <GeneratedColumn, Expression>{};
    if (from < 9) {
      transformer[db.attendanceSessionsTable.updatedAt] = currentDateAndTime;
    }
    transformer[db.attendanceSessionsTable.label] =
        const Constant<String>('Full Day');
    transformer[db.attendanceSessionsTable.isDeleted] =
        const Constant<bool>(false);
    transformer[db.attendanceSessionsTable.deletedAt] =
        const Constant(null);
    await m.alterTable(
        // ignore: experimental_member_use
        TableMigration(db.attendanceSessionsTable, columnTransformer: transformer));
  }

  // ── v10 → v11 ────────────────────────────────────────────────────────────
  static Future<void> _migrateToV11(Migrator m, AppDatabase db) async {
    await m.addColumn(db.syncQueueTable, db.syncQueueTable.groupKey);
    await m.addColumn(db.syncQueueTable, db.syncQueueTable.payload);
  }

  // ── v11 → v12 ────────────────────────────────────────────────────────────
  static Future<void> _migrateToV12(Migrator m, AppDatabase db) async {
    await m.addColumn(db.syncQueueTable, db.syncQueueTable.pendingPayload);
    await m.addColumn(db.syncQueueTable, db.syncQueueTable.syncSessionId);
    await m.createTable(db.syncMetadataTable);
  }

  // ── v12 → v13 ────────────────────────────────────────────────────────────
  static Future<void> _migrateToV13(Migrator m, AppDatabase db) async {
    await m.addColumn(db.classroomsTable, db.classroomsTable.deletedAt);
  }

  // ── v13 → v14 ────────────────────────────────────────────────────────────
  static Future<void> _migrateToV14(Migrator m, AppDatabase db) async {
    await m.addColumn(db.classroomsTable, db.classroomsTable.syncVersion);
    await m.addColumn(db.studentsTable, db.studentsTable.syncVersion);
    await m.addColumn(db.attendanceSessionsTable, db.attendanceSessionsTable.syncVersion);
    await m.addColumn(db.attendanceRecordsTable, db.attendanceRecordsTable.syncVersion);
  }

  // ── v14 → v15 ────────────────────────────────────────────────────────────
  static Future<void> _migrateToV15(Migrator m, AppDatabase db) async {
    await m.createTable(db.usersCredentialsTable);
  }

  // ── v15 → v16 ────────────────────────────────────────────────────────────
  // Adds 4 compound indexes to cover the hottest query paths at production
  // data volumes (2+ years of attendance records).
  //
  // Index strategy (DBMS principle — composite index for selective + range):
  //  • classrooms: (user_id, deleted_at)  → home screen classroom list
  //  • sessions:   (classroom_id, is_deleted, date DESC) → history tab + analytics
  //  • records:    (session_id)            → attendance taking / editing
  //  • students:   (classroom_id, is_active) → active student lookup
  static Future<void> _migrateToV16(Migrator m) async {
    await m.createIndex(Index(
      'idx_classrooms_user_deleted',
      'CREATE INDEX IF NOT EXISTS idx_classrooms_user_deleted '
      'ON classrooms_table (user_id, deleted_at)',
    ));
    await m.createIndex(Index(
      'idx_sessions_classroom_deleted_date',
      'CREATE INDEX IF NOT EXISTS idx_sessions_classroom_deleted_date '
      'ON attendance_sessions_table (classroom_id, is_deleted, date DESC)',
    ));
    await m.createIndex(Index(
      'idx_records_session',
      'CREATE INDEX IF NOT EXISTS idx_records_session '
      'ON attendance_records_table (session_id)',
    ));
    await m.createIndex(Index(
      'idx_students_classroom_active',
      'CREATE INDEX IF NOT EXISTS idx_students_classroom_active '
      'ON students_table (classroom_id, is_active)',
    ));
  }
}
