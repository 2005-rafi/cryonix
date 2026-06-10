import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cryonix/features/auth/providers.dart';
import 'package:cryonix/features/classroom/providers.dart';
import '../../../core/utils.dart';
import '../../../core/app_strings.dart';
import '../../../shared/animations/staggered_list_item.dart';
import '../../../shared/empty_state_widget.dart';
import '../../../shared/loading_indicator.dart';

class AttendanceOverviewScreen extends ConsumerWidget {
  const AttendanceOverviewScreen({super.key});

  String _lastTakenLabel(DateTime? date) {
    if (date == null) return 'No sessions yet';
    final now = DateTime.now();
    if (date.isSameDayAs(now)) return 'Last taken: Today';
    final yesterday = now.subtract(const Duration(days: 1));
    if (date.isSameDayAs(yesterday)) return 'Last taken: Yesterday';
    return 'Last taken: ${date.toDisplayDate()}';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    if (user == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final classroomsAsync = ref.watch(classroomListProvider(user.uid));
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        context.go('/home');
      },
      child: Scaffold(
        appBar: AppBar(title: const Text('Take Attendance')),
        body: classroomsAsync.when(
          data: (classrooms) {
          if (classrooms.isEmpty) {
            return EmptyStateWidget(
              icon: Icons.class_outlined,
              title: AppStrings.noClassroomsTitle,
              description: 'Create a classroom first to take attendance.',
            );
          }

          // Sort by last session date descending (cached in DB)
          final sorted = [...classrooms];
          sorted.sort((a, b) {
            final aDate = a.lastSessionAt;
            final bDate = b.lastSessionAt;
            if (aDate == null && bDate == null) return 0;
            if (aDate == null) return 1;
            if (bDate == null) return -1;
            return bDate.compareTo(aDate);
          });

          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            itemCount: sorted.length,
            itemBuilder: (context, index) {
              final c = sorted[index];
              final card = Card(
                margin: const EdgeInsets.only(bottom: 8),
                clipBehavior: Clip.antiAlias,
                child: Semantics(
                  label:
                      'Classroom: ${c.name}${c.subject != null && c.subject!.isNotEmpty ? ', subject: ${c.subject}' : ''}. ${_lastTakenLabel(c.lastSessionAt)}. Tap to take attendance.',
                  button: true,
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    leading: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: cs.primaryContainer,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.class_rounded,
                        color: cs.onPrimaryContainer,
                        size: 22,
                      ),
                    ),
                    title: Text(
                      c.name,
                      style: tt.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (c.subject != null && c.subject!.isNotEmpty)
                          Text(
                            c.subject!,
                            style: tt.bodySmall?.copyWith(
                              color: cs.onSurfaceVariant,
                            ),
                          ),
                        Text(
                          _lastTakenLabel(c.lastSessionAt),
                          style: tt.bodySmall?.copyWith(
                            color: cs.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                    trailing: Icon(
                      Icons.chevron_right_rounded,
                      color: cs.onSurfaceVariant,
                    ),
                    onTap: () => context.push('/attendance/${c.id}'),
                  ),
                ),
              );
              return index < 8
                  ? StaggeredListItem(index: index, child: card)
                  : card;
            },
          );
        },
        loading: () => const LoadingIndicator(),
        error: (e, _) => Center(
          child: Text('Error: $e', style: TextStyle(color: cs.error)),
        ),
      ),
      ),
    );
  }
}
