import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants.dart';
import '../../../shared/cryonix_scaffold.dart';
import '../../../shared/loading_indicator.dart';
import '../../../shared/widgets/sliding_count.dart';
import '../../../shared/widgets/error_snackbar.dart';
import '../../../theme/app_custom_colors.dart';
import '../providers.dart';
import '../../classroom/providers.dart';
import '../widgets/student_attendance_row.dart';

class EditSessionScreen extends ConsumerStatefulWidget {
  final String classroomId;
  final String sessionId;

  const EditSessionScreen({
    super.key,
    required this.classroomId,
    required this.sessionId,
  });

  @override
  ConsumerState<EditSessionScreen> createState() => _EditSessionScreenState();
}

class _EditSessionScreenState extends ConsumerState<EditSessionScreen> {
  bool _saveSuccessVisible = false;
  bool _saveSequenceRunning = false;
  bool _hasUnsavedChanges = false;
  late final EditSessionArgs _args;

  @override
  void initState() {
    super.initState();
    _args = (classroomId: widget.classroomId, sessionId: widget.sessionId);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(editSessionNotifierProvider(_args).notifier).loadSession();
    });
  }

  Future<void> _handleSaveSuccess() async {
    if (_saveSequenceRunning) return;
    _saveSequenceRunning = true;
    setState(() {
      _saveSuccessVisible = true;
      _hasUnsavedChanges = false;
    });
    await Future<void>.delayed(const Duration(milliseconds: 600));
    if (!mounted) return;
    setState(() => _saveSuccessVisible = false);
    _saveSequenceRunning = false;
    context.pop(); // Go back to session detail screen
  }

  Future<bool> _handleBack() async {
    if (!_hasUnsavedChanges) return true;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Unsaved Changes'),
        content: const Text('Discard your changes?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Keep Editing'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Discard'),
          ),
        ],
      ),
    );
    return confirmed == true;
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final state = ref.watch(editSessionNotifierProvider(_args));

    ref.listen<AttendanceSessionState>(
      editSessionNotifierProvider(_args),
      (_, current) {
        if (current.state == SessionState.error && current.errorMessage != null) {
          ErrorSnackBar.show(
            context,
            message: current.errorMessage!,
            type: ErrorSnackBarType.error,
          );
        } else if (current.state == SessionState.saved) {
          _handleSaveSuccess();
        }
      },
    );

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final allowed = await _handleBack();
        if (allowed && context.mounted) {
          context.pop();
        }
      },
      child: CryonixScaffold(
        appBar: AppBar(
          title: const Text('Edit Session'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () async {
              final allowed = await _handleBack();
              if (allowed && context.mounted) {
                context.pop();
              }
            },
          ),
        ),
        body: _buildBody(state, cs),
      ),
    );
  }

  Widget _buildBody(AttendanceSessionState state, ColorScheme cs) {
    if (state.state == SessionState.idle || state.state == SessionState.saving && state.statusMap.isEmpty) {
      return const LoadingIndicator();
    }
    
    if (state.state == SessionState.error && state.statusMap.isEmpty) {
       return Center(child: Text(state.errorMessage ?? 'An error occurred.'));
    }

    final tt = Theme.of(context).textTheme;
    final custom = Theme.of(context).extension<AppCustomColors>();
    final studentsAsync = ref.watch(studentsByClassroomProvider(widget.classroomId));

    final presentCount = state.statusMap.values
        .where((s) => s == AttendanceStatus.present)
        .length;
    final absentCount = state.statusMap.values
        .where((s) => s == AttendanceStatus.absent)
        .length;
    final onDutyCount = state.statusMap.values
        .where((s) => s == AttendanceStatus.onDuty)
        .length;
    final total = presentCount + absentCount + onDutyCount;

    final countStyle = tt.labelMedium?.copyWith(fontWeight: FontWeight.w600);

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          color: cs.surfaceContainerHighest,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          state.label ?? 'Session',
                          style: tt.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                        ),
                        Text(
                          'Editing records',
                          style: tt.labelSmall?.copyWith(color: cs.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 4,
                runSpacing: 4,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text('Present: ', style: countStyle),
                  SlidingCount(value: presentCount, style: countStyle),
                  Text(' · Absent: ', style: countStyle),
                  SlidingCount(value: absentCount, style: countStyle),
                  Text(' · On-Duty: ', style: countStyle),
                  SlidingCount(value: onDutyCount, style: countStyle),
                ],
              ),
            ],
          ),
        ),
        if (total > 0)
          LinearProgressIndicator(
            value: presentCount / total,
            backgroundColor: cs.surfaceContainerHigh,
            color: cs.primary,
            minHeight: 4,
          ),
        Expanded(
          child: studentsAsync.when(
            data: (students) {
              if (students.isEmpty) {
                return const Center(child: Text('No students in this classroom.'));
              }
              // It's possible some students were deleted or added after the session.
              // We should show all students currently in the classroom.
              // If a student doesn't have a record in the session yet, we default them to present.
              return ListView.builder(
                itemCount: students.length,
                itemBuilder: (context, index) {
                  final student = students[index];
                  final currentStatus = state.statusMap[student.id] ?? AttendanceStatus.present;
                  return StudentAttendanceRow(
                    student: student,
                    currentStatus: currentStatus,
                    onStatusChanged: (newStatus) {
                      setState(() => _hasUnsavedChanges = true);
                      ref
                          .read(editSessionNotifierProvider(_args).notifier)
                          .setStatus(student.id, newStatus);
                    },
                  );
                },
              );
            },
            loading: () => const LoadingIndicator(),
            error: (err, _) => Center(child: Text('Error: $err')),
          ),
        ),
        Container(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          decoration: BoxDecoration(
            color: cs.surfaceContainer,
            border: Border(top: BorderSide(color: cs.outlineVariant)),
          ),
          child: SafeArea(
            top: false,
            child: _SaveSessionButton(
              isSaving: state.state == SessionState.saving,
              showSuccess: _saveSuccessVisible,
              successColor: custom?.presentColor ?? cs.primary,
              onPressed: state.state == SessionState.saving || _saveSuccessVisible
                  ? null
                  : () => ref
                      .read(editSessionNotifierProvider(_args).notifier)
                      .saveChanges(),
            ),
          ),
        ),
      ],
    );
  }
}

class _SaveSessionButton extends StatelessWidget {
  const _SaveSessionButton({
    required this.isSaving,
    required this.showSuccess,
    required this.successColor,
    required this.onPressed,
  });

  final bool isSaving;
  final bool showSuccess;
  final Color successColor;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return AnimatedContainer(
      duration: kAnimFast,
      curve: kCurveStandard,
      child: FilledButton(
        onPressed: onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: showSuccess ? successColor : null,
          foregroundColor: showSuccess ? cs.onPrimary : null,
        ),
        child: AnimatedSwitcher(
          duration: kAnimFast,
          child: isSaving
              ? SizedBox(
                  key: const ValueKey('saving'),
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: showSuccess ? cs.onPrimary : cs.onPrimary,
                  ),
                )
              : showSuccess
                  ? const Icon(Icons.check_rounded, key: ValueKey('success'))
                  : const Row(
                      key: ValueKey('label'),
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.save_rounded),
                        SizedBox(width: 8),
                        Text('Save Changes'),
                      ],
                    ),
        ),
      ),
    );
  }
}
