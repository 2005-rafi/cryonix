import 'package:flutter_test/flutter_test.dart';
import 'package:cryonix/core/startup_notifier.dart';

// ---------------------------------------------------------------------------
// Minimal fake AppDatabase for testing startup notifier without a real DB.
// ---------------------------------------------------------------------------
class _FakeStartupDb {
  final List<String> calls = [];

  Future<void> doNothing() async {}
  Future<void> fail(String name) async => throw Exception('$name failed');
}

// ---------------------------------------------------------------------------
// Helpers to build task lists without a real DB.
// ---------------------------------------------------------------------------
List<StartupTask> _buildFakeTasks(List<(String, Future<void> Function())> defs) {
  return defs.map((d) => StartupTask(d.$1, d.$2)).toList();
}

void main() {
  group('StartupNotifier', () {
    test('happy path: all tasks complete → ready state', () async {
      // ignore: unused_local_variable
      final db = _FakeStartupDb();
      final executionOrder = <String>[];

      final tasks = _buildFakeTasks([
        ('Task A', () async { executionOrder.add('A'); }),
        ('Task B', () async { executionOrder.add('B'); }),
        ('Task C', () async { executionOrder.add('C'); }),
      ]);

      final states = <StartupState>[];
      // ignore: unused_local_variable
      final notifier = StartupNotifier.withTasks(tasks)
        ..addListener((s) => states.add(s));

      // Give the async loop time to finish.
      await Future.delayed(const Duration(milliseconds: 50));

      expect(states.last.status, StartupStatus.ready);
      expect(states.last.progressPercent, 1.0);
    });

    test('error path: second task throws → error state with task name', () async {
      final tasks = _buildFakeTasks([
        ('Task A', () async {}),
        ('Task B', () async => throw Exception('boom')),
        ('Task C', () async {}),
      ]);

      final notifier = StartupNotifier.withTasks(tasks);
      await Future.delayed(const Duration(milliseconds: 50));

      expect(notifier.state.status, StartupStatus.error);
      expect(notifier.state.failedTaskName, 'Task B');
      expect(notifier.state.errorMessage, contains('boom'));
    });

    test('order guarantee: tasks execute in list order', () async {
      final executionOrder = <String>[];

      final tasks = _buildFakeTasks([
        ('First',  () async { executionOrder.add('First'); }),
        ('Second', () async { executionOrder.add('Second'); }),
        ('Third',  () async { executionOrder.add('Third'); }),
      ]);

      // ignore: unused_local_variable
      final notifier = StartupNotifier.withTasks(tasks);
      await Future.delayed(const Duration(milliseconds: 50));

      expect(executionOrder, ['First', 'Second', 'Third']);
    });

    test('progress increases monotonically from 0 to 1', () async {
      final progressValues = <double>[];

      final tasks = _buildFakeTasks([
        ('T1', () async {}),
        ('T2', () async {}),
        ('T3', () async {}),
      ]);

      final notifier = StartupNotifier.withTasks(tasks);
      notifier.addListener((s) {
        if (s.status == StartupStatus.loading) {
          progressValues.add(s.progressPercent);
        }
      });

      await Future.delayed(const Duration(milliseconds: 50));

      // Progress should increase (or stay same) — never go backwards.
      for (int i = 1; i < progressValues.length; i++) {
        expect(progressValues[i], greaterThanOrEqualTo(progressValues[i - 1]));
      }
    });

    test('retry resets to loading then reaches ready again', () async {
      var shouldFail = true;
      final tasks = _buildFakeTasks([
        ('Flaky', () async {
          if (shouldFail) throw Exception('temp');
        }),
      ]);

      final notifier = StartupNotifier.withTasks(tasks);
      await Future.delayed(const Duration(milliseconds: 50));
      expect(notifier.state.status, StartupStatus.error);

      shouldFail = false;
      notifier.retry();
      await Future.delayed(const Duration(milliseconds: 50));
      expect(notifier.state.status, StartupStatus.ready);
    });
  });
}
