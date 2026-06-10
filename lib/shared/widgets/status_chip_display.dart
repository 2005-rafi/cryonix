import 'package:flutter/material.dart';
import '../../core/constants/domain_enums.dart';
import '../../theme/app_custom_colors.dart';


/// A read-only status display chip that includes an icon alongside the label.
/// Used in session detail for color-blind accessibility.
class StatusChipDisplay extends StatelessWidget {
  const StatusChipDisplay({super.key, required this.status});

  final AttendanceStatus status;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final custom = Theme.of(context).extension<AppCustomColors>();
    final (Color bg, Color fg, IconData icon, String label) = switch (status) {
      AttendanceStatus.present => (
          custom?.presentColor ?? cs.primary,
          Colors.white,
          Icons.check_circle_rounded,
          'Present',
        ),
      AttendanceStatus.absent => (
          custom?.absentColor ?? cs.error,
          Colors.white,
          Icons.cancel_rounded,
          'Absent',
        ),
      AttendanceStatus.onDuty => (
          custom?.onDutyColor ?? cs.tertiary,
          Colors.white,
          Icons.work_rounded,
          'On Duty',
        ),
    };

    return Semantics(
      label: 'Attendance status: $label',
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: fg, size: 14),
            const SizedBox(width: 4),
            Text(
              label,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: fg,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
