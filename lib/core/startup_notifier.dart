import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../database/app_database.dart';

// ── StartupStatus ─────────────────────────────────────────────────────────

/// The three possible states of the startup sequence.
enum StartupStatus {
  /// One or more tasks are still running. Check [StartupState.progressPercent].
  loading,

  /// All initialization tasks completed successfully.
  ready,

  /// A task threw an exception. Check [StartupState.errorMessage] and
  /// [StartupState.failedTaskName] to identify the cause.
  error,
}

// ── StartupState ──────────────────────────────────────────────────────────

class StartupState {
  final StartupStatus status;

  /// 0.0–1.0 progress through the task list. Only meaningful when [status]
  /// is [StartupStatus.loading].
  final double progressPercent;

  /// Human-readable name of the currently-running task.
  final String? currentTaskName;

  /// Set when [status] is [StartupStatus.error].
  final String? errorMessage;

  /// Name of the task that failed.
  final String? failedTaskName;

  const StartupState({
    required this.status,
    this.progressPercent = 0.0,
    this.currentTaskName,
    this.errorMessage,
    this.failedTaskName,
  });

  const StartupState.loading({double progress = 0.0, String? taskName})
      : status = StartupStatus.loading,
        progressPercent = progress,
        currentTaskName = taskName,
        errorMessage = null,
        failedTaskName = null;

  const StartupState.ready()
      : status = StartupStatus.ready,
        progressPercent = 1.0,
        currentTaskName = null,
        errorMessage = null,
        failedTaskName = null;

  StartupState.error({required String message, required String taskName})
      : status = StartupStatus.error,
        progressPercent = 0.0,
        currentTaskName = null,
        errorMessage = message,
        failedTaskName = taskName;
}

// ── StartupTask ────────────────────────────────────────────────────────────

/// A named async initialization task for the startup sequence.
/// Publicly exposed so tests can build custom task lists without a real DB.
typedef TaskFn = Future<void> Function();

class StartupTask {
  final String name;
  final TaskFn run;
  const StartupTask(this.name, this.run);
}

// ── StartupNotifier ───────────────────────────────────────────────────────

/// Runs a sequential list of named initialization tasks and exposes progress
/// as a percentage to the splash screen.
///
/// Adding a new initialization step requires only adding one [StartupTask]
/// to the task list — the notifier loop handles everything else.
class StartupNotifier extends StateNotifier<StartupState> {
  final List<StartupTask> _tasks;

  /// Production constructor — uses real DB tasks.
  StartupNotifier(AppDatabase db)
      : _tasks = [
          StartupTask('Reset stale sync entries', () => db.resetStaleInProgress()),
          StartupTask('Reconcile session counts', () => db.reconcileRecentSessionCounts()),
          StartupTask('Purge old soft-deleted sessions', () => db.permanentlyDeleteOldSessions()),
          StartupTask('Audit session dates', () => db.auditSessionDates()),
          StartupTask('Recalculate student counts', () => db.recalculateAllStudentCounts()),
        ],
        super(const StartupState.loading(progress: 0.0)) {
    _runTasks();
  }

  /// Testing constructor — accepts a custom task list. Allows unit tests to
  /// inject fake tasks without any DB dependency.
  StartupNotifier.withTasks(List<StartupTask> tasks)
      : _tasks = tasks,
        super(const StartupState.loading(progress: 0.0)) {
    _runTasks();
  }

  /// Builds and runs the ordered task list. Each task runs sequentially;
  /// a failure in any task transitions to the error state immediately.
  Future<void> _runTasks() async {
    final total = _tasks.length;
    for (var i = 0; i < total; i++) {
      final task = _tasks[i];
      state = StartupState.loading(
        progress: i / total,
        taskName: task.name,
      );
      try {
        await task.run();
        debugPrint('[Startup] ✓ ${task.name}');
      } catch (e, stack) {
        debugPrint('[Startup] ✗ ${task.name}: $e\n$stack');
        state = StartupState.error(
          message: e.toString(),
          taskName: task.name,
        );
        return;
      }
    }

    state = const StartupState.ready();
    debugPrint('[Startup] All tasks complete.');
  }

  /// Retries the full initialization sequence from the beginning.
  void retry() {
    state = const StartupState.loading(progress: 0.0);
    _runTasks();
  }
}
