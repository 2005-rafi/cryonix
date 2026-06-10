import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/constants.dart';
import '../../../database/app_database.dart';
import '../../../shared/animations/animated_status_chip.dart';
import '../../../theme/app_custom_colors.dart';

class StudentAttendanceRow extends StatelessWidget {
  final Student student;
  final AttendanceStatus currentStatus;
  final Function(AttendanceStatus) onStatusChanged;

  const StudentAttendanceRow({
    super.key,
    required this.student,
    required this.currentStatus,
    required this.onStatusChanged,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final custom = Theme.of(context).extension<AppCustomColors>();

    final presentColor = custom?.presentColor ?? cs.primary;
    final absentColor = custom?.absentColor ?? cs.error;
    final onDutyColor = custom?.onDutyColor ?? cs.tertiary;

    return Semantics(
      container: true,
      label: '${student.name}, Roll ${student.rollNumber}. '
          'Current status: ${currentStatus.name}',
      child: Column(
        children: [
          ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 56),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          student.rollNumber,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: cs.onSurfaceVariant,
                              ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          student.name,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ],
                    ),
                  ),
                  Semantics(
                    excludeSemantics: true,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Semantics(
                          label: 'Mark ${student.name} as Present',
                          button: true,
                          selected: currentStatus == AttendanceStatus.present,
                          child: ExcludeSemantics(
                            child: AnimatedStatusChip(
                              status: AttendanceStatus.present.name,
                              label: AttendanceStatus.present.shortName,
                              backgroundColor: presentColor,
                              foregroundColor: cs.onPrimary,
                              inactiveBorderColor: cs.outlineVariant,
                              isSelected: currentStatus == AttendanceStatus.present,
                              onTap: () {
                                HapticFeedback.selectionClick();
                                onStatusChanged(AttendanceStatus.present);
                              },
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Semantics(
                          label: 'Mark ${student.name} as Absent',
                          button: true,
                          selected: currentStatus == AttendanceStatus.absent,
                          child: ExcludeSemantics(
                            child: AnimatedStatusChip(
                              status: AttendanceStatus.absent.name,
                              label: AttendanceStatus.absent.shortName,
                              backgroundColor: absentColor,
                              foregroundColor: cs.onError,
                              inactiveBorderColor: cs.outlineVariant,
                              isSelected: currentStatus == AttendanceStatus.absent,
                              onTap: () {
                                HapticFeedback.selectionClick();
                                onStatusChanged(AttendanceStatus.absent);
                              },
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Semantics(
                          label: 'Mark ${student.name} as On Duty',
                          button: true,
                          selected: currentStatus == AttendanceStatus.onDuty,
                          child: ExcludeSemantics(
                            child: AnimatedStatusChip(
                              status: AttendanceStatus.onDuty.name,
                              label: AttendanceStatus.onDuty.shortName,
                              backgroundColor: onDutyColor,
                              foregroundColor: cs.onTertiary,
                              inactiveBorderColor: cs.outlineVariant,
                              isSelected: currentStatus == AttendanceStatus.onDuty,
                              onTap: () {
                                HapticFeedback.selectionClick();
                                onStatusChanged(AttendanceStatus.onDuty);
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const Divider(height: 1),
        ],
      ),
    );
  }
}
