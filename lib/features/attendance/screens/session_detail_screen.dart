import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants.dart';
import '../../../database/app_database.dart';
import '../../../models/record_with_student.dart';
import '../../../shared/animations/staggered_list_item.dart';
import '../../../core/app_strings.dart';
import '../../../shared/empty_state_widget.dart';
import '../../../shared/loading_indicator.dart';
import '../../../shared/cryonix_scaffold.dart';
import '../../../shared/widgets/status_chip_display.dart';
import '../../../shared/widgets/error_snackbar.dart';
import '../../../theme/app_custom_colors.dart';
import '../providers.dart';

class SessionDetailScreen extends ConsumerWidget {
  final String sessionId;
  const SessionDetailScreen({super.key, required this.sessionId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recordsAsync = ref.watch(sessionRecordsProvider(sessionId));
    final sessionAsync = ref.watch(sessionByIdProvider(sessionId));

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        if (context.canPop()) {
          context.pop();
        }
      },
      child: CryonixScaffold(
        appBar: AppBar(
          title: const Text('Session Details'),
          // Explicit back button — consistent for both gesture and tap (F6 fix).
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              if (context.canPop()) context.pop();
            },
          ),
          actions: [
            recordsAsync.when(
              data: (records) {
                if (records.isEmpty) return const SizedBox.shrink();
                return Semantics(
                  label: 'Copy roll numbers to clipboard',
                  button: true,
                  child: IconButton(
                    icon: const Icon(Icons.copy_all_rounded),
                    tooltip: 'Copy Roll Numbers',
                    onPressed: () {
                      final present = records.where((r) => r.status == AttendanceStatus.present).map((r) => r.rollNumber).join(', ');
                      final absent = records.where((r) => r.status == AttendanceStatus.absent).map((r) => r.rollNumber).join(', ');
                      final onDuty = records.where((r) => r.status == AttendanceStatus.onDuty).map((r) => r.rollNumber).join(', ');
  
                      final sb = StringBuffer();
                      if (present.isNotEmpty) sb.writeln('Present: $present');
                      if (absent.isNotEmpty) sb.writeln('Absent: $absent');
                      if (onDuty.isNotEmpty) sb.writeln('On-Duty: $onDuty');
  
                      Clipboard.setData(ClipboardData(text: sb.toString().trim()));
                      ErrorSnackBar.show(
                        context,
                        message: 'Roll numbers copied to clipboard',
                        type: ErrorSnackBarType.success,
                      );
                    },
                  ),
                );
              },
              loading: () => const SizedBox.shrink(),
              error: (_, _) => const SizedBox.shrink(),
            ),
          ],
        ),
  
        body: recordsAsync.when(
          data: (records) {
            if (records.isEmpty) {
              return EmptyStateWidget(
                icon: Icons.people_outline_rounded,
                title: AppStrings.noRecords,
                description: AppStrings.recordsFinal,
              );
            }
  
            int presentCount = 0, absentCount = 0, onDutyCount = 0;
            for (final r in records) {
              if (r.status == AttendanceStatus.present) {
                presentCount++;
              } else if (r.status == AttendanceStatus.absent) {
                absentCount++;
              } else if (r.status == AttendanceStatus.onDuty) {
                onDutyCount++;
              }
            }
  
            final total = presentCount + absentCount + onDutyCount;
            final rate = total > 0 ? presentCount / total : 0.0;
  
            return _SessionDetailBody(
              sessionAsync: sessionAsync,
              records: records,
              presentCount: presentCount,
              absentCount: absentCount,
              onDutyCount: onDutyCount,
              rate: rate,
            );
          },
          loading: () => const LoadingIndicator(),
          error: (err, _) => Center(child: Text('Error: $err')),
        ),
      ),
    );
  }
}


class _SessionDetailBody extends StatelessWidget {
  const _SessionDetailBody({
    required this.sessionAsync,
    required this.records,
    required this.presentCount,
    required this.absentCount,
    required this.onDutyCount,
    required this.rate,
  });

  final AsyncValue<AttendanceSession?> sessionAsync;
  final List<RecordWithStudent> records;
  final int presentCount;
  final int absentCount;
  final int onDutyCount;
  final double rate;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final custom = Theme.of(context).extension<AppCustomColors>();

    return Stack(
      children: [
        Column(
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
              color: cs.surfaceContainerHighest,
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _AnimatedStatBadge(
                        label: 'Present',
                        target: presentCount,
                        color: custom?.presentColor ?? cs.primary,
                        onColor: cs.onPrimary,
                      ),
                      _AnimatedStatBadge(
                        label: 'Absent',
                        target: absentCount,
                        color: custom?.absentColor ?? cs.error,
                        onColor: cs.onError,
                      ),
                      _AnimatedStatBadge(
                        label: 'On-Duty',
                        target: onDutyCount,
                        color: custom?.onDutyColor ?? cs.tertiary,
                        onColor: cs.onTertiary,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: rate),
                    duration: kAnimSlow,
                    curve: kCurveEnter,
                    builder: (context, value, _) {
                      return ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: value,
                          backgroundColor: cs.surfaceContainerHigh,
                          color: custom?.presentColor ?? cs.primary,
                          minHeight: 6,
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${(rate * 100).toStringAsFixed(1)}% attendance rate',
                    style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.only(bottom: 80),
                itemCount: records.length,
                separatorBuilder: (context, index) =>
                    Divider(height: 1, color: cs.outlineVariant),
                itemBuilder: (context, index) {
                  final record = records[index];

                  final tile = Semantics(
                    label: '${record.studentName}, Roll ${record.rollNumber}, status: ${record.status.name}',
                    child: ListTile(
                      contentPadding:
                          const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                      leading: CircleAvatar(
                        backgroundColor: cs.surfaceContainerHigh,
                        child: Text(
                          record.rollNumber.length > 3
                              ? record.rollNumber.substring(0, 3)
                              : record.rollNumber,
                          style: tt.labelSmall?.copyWith(
                            color: cs.onSurfaceVariant,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      title: Text(record.studentName, style: tt.bodyLarge),
                      subtitle: Text(
                        record.rollNumber,
                        style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                      ),
                      trailing: StatusChipDisplay(status: record.status),
                    ),
                  );

                  if (index < 8) {
                    return StaggeredListItem(index: index, child: tile);
                  }
                  return tile;
                },
              ),
            ),
          ],
        ),
        // Sticky Edit Session FAB — always visible regardless of scroll position
        Positioned(
          bottom: 16,
          right: 16,
          child: sessionAsync.when(
            data: (session) {
              if (session == null) return const SizedBox.shrink();
              return FloatingActionButton.extended(
                onPressed: () {
                  context.push(
                    '/edit-session/${session.classroomId}/${session.id}',
                  );
                },
                icon: const Icon(Icons.edit_rounded),
                label: const Text('Edit Session'),
                heroTag: 'edit-session-fab',
              );
            },
            loading: () => const SizedBox.shrink(),
            error: (_, _) => const SizedBox.shrink(),
          ),
        ),
      ],
    );
  }

}


class _AnimatedStatBadge extends StatelessWidget {
  const _AnimatedStatBadge({
    required this.label,
    required this.target,
    required this.color,
    required this.onColor,
  });

  final String label;
  final int target;
  final Color color;
  final Color onColor;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    return Column(
      children: [
        TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: target.toDouble()),
          duration: kAnimSlow,
          curve: kCurveEnter,
          builder: (context, value, _) {
            return Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(16),
              ),
              alignment: Alignment.center,
              child: Text(
                value.round().toString(),
                style: tt.headlineSmall?.copyWith(
                  color: onColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 6),
        Text(label, style: tt.bodySmall),
      ],
    );
  }
}
