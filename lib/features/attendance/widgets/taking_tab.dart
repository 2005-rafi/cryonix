import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/constants.dart';
import '../../../shared/loading_indicator.dart';
import '../../../shared/widgets/sliding_count.dart';
import '../../../theme/app_custom_colors.dart';
import '../providers.dart';
import '../../classroom/providers.dart';
import '../../../shared/widgets/error_snackbar.dart';
import '../widgets/student_attendance_row.dart';
import '../../../models/session_summary.dart';

class TakingTab extends ConsumerStatefulWidget {
  final String classroomId;
  final DateTime? initialDate;
  final VoidCallback onSaveSuccess;

  const TakingTab({
    super.key,
    required this.classroomId,
    this.initialDate,
    required this.onSaveSuccess,
  });

  @override
  ConsumerState<TakingTab> createState() => _TakingTabState();
}

class _TakingTabState extends ConsumerState<TakingTab> {
  late DateTime _selectedDate;
  String _selectedLabel = 'Morning';
  final _customLabelController = TextEditingController();
  bool _saveSuccessVisible = false;
  bool _saveSequenceRunning = false;

  static const _labelGroups = [
    _LabelGroup('Day Sessions', ['Morning', 'Afternoon', 'Full Day']),
    _LabelGroup('Period Sessions', [
      'Period 1',
      'Period 2',
      'Period 3',
      'Period 4',
      'Period 5',
      'Period 6',
      'Period 7',
      'Period 8',
    ]),
    _LabelGroup('Special Sessions', ['Lab Session']),
  ];

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.initialDate ?? DateTime.now();
  }

  @override
  void dispose() {
    _customLabelController.dispose();
    super.dispose();
  }

  Future<void> _handleSaveSuccess() async {
    if (_saveSequenceRunning) return;
    _saveSequenceRunning = true;
    setState(() => _saveSuccessVisible = true);
    await Future<void>.delayed(const Duration(milliseconds: 600));
    if (!mounted) return;
    ref
        .read(attendanceNotifierProvider(widget.classroomId).notifier)
        .resetIdle();
    setState(() => _saveSuccessVisible = false);
    _saveSequenceRunning = false;
    widget.onSaveSuccess();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final state = ref.watch(attendanceNotifierProvider(widget.classroomId));

    ref.listen<AttendanceSessionState>(
      attendanceNotifierProvider(widget.classroomId),
      (_, current) {
        if (current.state == SessionState.duplicateSessionError) {
          _showDuplicateDialog(current.duplicateSessionId!);
        } else if (current.state == SessionState.error &&
            current.errorMessage != null) {
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

    if (state.state == SessionState.idle ||
        state.state == SessionState.error ||
        state.state == SessionState.duplicateSessionError) {
      return _buildIdleState(cs);
    } else if (state.state == SessionState.active ||
        state.state == SessionState.saving ||
        state.state == SessionState.saved) {
      return _buildActiveState(state, cs);
    }
    return const LoadingIndicator();
  }

  Widget _buildIdleState(ColorScheme cs) {
    final tt = Theme.of(context).textTheme;
    final sessionsAsync = ref.watch(
      sessionsWithSummaryProvider(widget.classroomId),
    );
    List<SessionSummary> sessionsToday = [];
    sessionsAsync.whenData((sessions) {
      sessionsToday = sessions
          .where(
            (s) =>
                s.date.year == _selectedDate.year &&
                s.date.month == _selectedDate.month &&
                s.date.day == _selectedDate.day,
          )
          .toList();
    });

    final isDuplicateLabel = sessionsToday.any(
      (s) =>
          s.label ==
          (_selectedLabel == 'Custom'
              ? _customLabelController.text.trim()
              : _selectedLabel),
    );

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildSectionCard(
            context,
            title: 'Session Setup',
            child: InkWell(
              onTap: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: _selectedDate,
                  firstDate: DateTime(2020),
                  lastDate: DateTime.now(),
                );
                if (date != null) setState(() => _selectedDate = date);
              },
              borderRadius: BorderRadius.circular(12),
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'Date',
                  prefixIcon: Icon(Icons.calendar_today_outlined),
                  suffixIcon: Icon(Icons.arrow_drop_down_rounded),
                ),
                child: Text(
                  DateFormat('EEEE, d MMMM y').format(_selectedDate),
                  style: tt.bodyLarge,
                ),
              ),
            ),
          ),
          if (sessionsToday.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: cs.surfaceContainerLowest,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: cs.outlineVariant),
              ),
              child: Row(
                children: [
                  Text(
                    'Sessions Today',
                    style: tt.labelLarge?.copyWith(fontWeight: FontWeight.w600),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: () => _showSessionsBottomSheet(context, sessionsToday),
                    child: const Text('View'),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 12),
          _buildLabelSelectionCard(context),
          if (isDuplicateLabel) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: cs.errorContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(Icons.warning_amber_rounded, color: cs.error, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'A session with this label already exists today.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: cs.onErrorContainer,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed:
                isDuplicateLabel ||
                    (_selectedLabel == 'Custom' &&
                        _customLabelController.text.trim().isEmpty)
                ? null
                : () {
                    final finalLabel = _selectedLabel == 'Custom'
                        ? _customLabelController.text.trim()
                        : _selectedLabel;
                    ref
                        .read(
                          attendanceNotifierProvider(
                            widget.classroomId,
                          ).notifier,
                        )
                        .initSession(_selectedDate, label: finalLabel);
                  },
            icon: const Icon(Icons.play_arrow_rounded),
            label: const Text('Start Session'),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveState(AttendanceSessionState state, ColorScheme cs) {
    final tt = Theme.of(context).textTheme;
    final custom = Theme.of(context).extension<AppCustomColors>();
    final studentsAsync = ref.watch(
      studentsByClassroomProvider(widget.classroomId),
    );
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

    return Column(
      children: [
        _buildActiveHeaderCard(
          cs,
          tt,
          state,
          presentCount,
          absentCount,
          onDutyCount,
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
                return const Center(
                  child: Text('No students in this classroom.'),
                );
              }
              return ListView.builder(
                itemCount: students.length,
                itemBuilder: (context, index) {
                  final student = students[index];
                  final currentStatus =
                      state.statusMap[student.id] ?? AttendanceStatus.present;
                  return StudentAttendanceRow(
                    student: student,
                    currentStatus: currentStatus,
                    onStatusChanged: (newStatus) {
                      ref
                          .read(
                            attendanceNotifierProvider(
                              widget.classroomId,
                            ).notifier,
                          )
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
              onPressed:
                  state.state == SessionState.saving || _saveSuccessVisible
                  ? null
                  : () => ref
                        .read(
                          attendanceNotifierProvider(
                            widget.classroomId,
                          ).notifier,
                        )
                        .saveSession(),
            ),
          ),
        ),
      ],
    );
  }

  void _showDuplicateDialog(String duplicateSessionId) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: const Icon(Icons.warning_amber_rounded),
        title: const Text('Session Already Exists'),
        content: const Text(
          'A session already exists for this date. View it or choose a different date.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              ref
                  .read(attendanceNotifierProvider(widget.classroomId).notifier)
                  .resetIdle();
            },
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              ref
                  .read(attendanceNotifierProvider(widget.classroomId).notifier)
                  .resetIdle();
              context.push('/session/$duplicateSessionId');
            },
            child: const Text('View Existing'),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionCard(
    BuildContext context, {
    required String title,
    required Widget child,
  }) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cs.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: tt.labelLarge?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  void _showSessionsBottomSheet(BuildContext context, List<SessionSummary> sessions) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surfaceContainerLowest,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(ctx).size.height * 0.65,
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 32,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.outlineVariant,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Sessions Today',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                Flexible(
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: sessions.length,
                    itemBuilder: (ctx, index) {
                      return _buildCompactSessionCard(context, sessions[index]);
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildCompactSessionCard(BuildContext context, SessionSummary s) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final custom = Theme.of(context).extension<AppCustomColors>();

    final total = s.presentCount + s.absentCount + s.onDutyCount;
    final presentPercent = total > 0 ? (s.presentCount / total) : 0.0;
    final percentString = '${(presentPercent * 100).toInt()}%';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                s.label,
                style: tt.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              Text(
                percentString,
                style: tt.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '${s.presentCount} Present   ${s.absentCount} Absent   ${s.onDutyCount} OD',
            style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: presentPercent,
            minHeight: 4,
            backgroundColor: cs.surfaceContainerHighest,
            color: custom?.presentColor ?? cs.primary,
            borderRadius: BorderRadius.circular(2),
          ),
        ],
      ),
    );
  }



  Widget _buildLabelSelectionCard(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cs.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Label',
            style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 14),
          ..._labelGroups.map((group) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: _buildLabelGroup(context, group),
            );
          }),
          _buildCustomLabelCard(context),
        ],
      ),
    );
  }

  Widget _buildLabelGroup(BuildContext context, _LabelGroup group) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          group.title,
          style: tt.labelLarge?.copyWith(
            color: cs.onSurfaceVariant,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: group.labels.map((label) {
            final isSelected = _selectedLabel == label;
            return FilterChip(
              label: Text(label),
              selected: isSelected,
              onSelected: (selected) {
                if (selected) setState(() => _selectedLabel = label);
              },
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildCustomLabelCard(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final isCustom = _selectedLabel == 'Custom';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLow,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: cs.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Custom',
                style: tt.labelLarge?.copyWith(fontWeight: FontWeight.w700),
              ),
              const Spacer(),
              FilterChip(
                label: const Text('Custom'),
                selected: isCustom,
                onSelected: (selected) {
                  if (selected) setState(() => _selectedLabel = 'Custom');
                },
              ),
            ],
          ),
          if (isCustom) ...[
            const SizedBox(height: 12),
            TextField(
              controller: _customLabelController,
              decoration: const InputDecoration(
                labelText: 'Custom Label',
                prefixIcon: Icon(Icons.label_outline_rounded),
                hintText: 'e.g. Lab Session 3',
              ),
              onChanged: (_) => setState(() {}),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildActiveHeaderCard(
    ColorScheme cs,
    TextTheme tt,
    AttendanceSessionState state,
    int presentCount,
    int absentCount,
    int onDutyCount,
  ) {
    final countStyle = tt.labelMedium?.copyWith(fontWeight: FontWeight.w600);

    Widget stat(String label, int value) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: cs.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: cs.outlineVariant),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('$label: ', style: countStyle),
            SlidingCount(value: value, style: countStyle),
          ],
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: cs.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            DateFormat('d MMM y').format(_selectedDate),
            style: tt.titleSmall?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 2),
          Text(
            state.label ?? 'Session',
            style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              stat('Present', presentCount),
              stat('Absent', absentCount),
              stat('On-Duty', onDutyCount),
            ],
          ),
        ],
      ),
    );
  }
}

class _LabelGroup {
  const _LabelGroup(this.title, this.labels);

  final String title;
  final List<String> labels;
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
                    Text('Save Session'),
                  ],
                ),
        ),
      ),
    );
  }
}
