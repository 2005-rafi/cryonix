import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/app_strings.dart';
import '../../../core/constants.dart';
import '../../../core/constants/domain_enums.dart';
import '../../../shared/animations/staggered_list_item.dart';
import '../../../shared/animations/staggered_sheet_action.dart';
import '../../../shared/empty_state_widget.dart';
import '../../../shared/loading_indicator.dart';
import '../../../shared/widgets/bottom_sheet_handle.dart';
import '../../../shared/widgets/error_snackbar.dart';
import '../providers.dart';
import '../providers/attendance_ui_providers.dart';
import '../widgets/session_distribution_bar.dart';
import '../../../models/session_summary.dart';

/// The "History" tab extracted from AttendanceScreen.
///
/// Uses cursor-based pagination to avoid loading all sessions at once.
class HistoryTab extends ConsumerStatefulWidget {
  final String classroomId;

  const HistoryTab({super.key, required this.classroomId});

  @override
  ConsumerState<HistoryTab> createState() => _HistoryTabState();
}

class _HistoryTabState extends ConsumerState<HistoryTab> {
  static const _pageSize = 20;

  final _scrollController = ScrollController();
  final List<_HistoryItem> _items = [];
  DateTime? _cursor;
  bool _isLoading = false;
  bool _hasMore = true;

  @override
  void initState() {
    super.initState();
    _loadNextPage();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      _loadNextPage();
    }
  }

  Future<void> _loadNextPage() async {
    if (_isLoading || !_hasMore) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final repo = ref.read(attendanceRepositoryProvider);
      final groups = await repo.getSessionsPage(
        widget.classroomId,
        cursor: _cursor,
        limit: _pageSize,
      );

      int newCount = 0;
      for (final group in groups) {
        _items.add(_HistoryItem.header(group.date));
        for (final session in group.sessions) {
          _items.add(_HistoryItem.session(session));
          newCount++;
        }
      }

      setState(() {
        _isLoading = false;
        _hasMore = newCount >= _pageSize;
        if (groups.isNotEmpty) {
          _cursor = groups.last.sessions.last.date;
        }
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Failed to load sessions';
      });
    }
  }

  String? _errorMessage;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final staggerPlayed = ref.watch(
      historyStaggerPlayedProvider(widget.classroomId),
    );

    if (_items.isNotEmpty && !staggerPlayed) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref
                .read(historyStaggerPlayedProvider(widget.classroomId).notifier)
                .state =
            true;
      });
    }

    if (_isLoading && _items.isEmpty) {
      return const Scaffold(body: SessionListLoading());
    }

    if (_errorMessage != null && _items.isEmpty) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 48, color: cs.error),
              const SizedBox(height: 16),
              Text(_errorMessage!, style: tt.titleMedium),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: _loadNextPage,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (!_isLoading && _items.isEmpty) {
      return Scaffold(
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => _showRecentlyDeleted(context, ref),
          icon: const Icon(Icons.delete_outline),
          label: const Text('Recently Deleted'),
        ),
        body: RefreshIndicator(
          onRefresh: () async {
            setState(() {
              _items.clear();
              _cursor = null;
              _hasMore = true;
            });
            await _loadNextPage();
          },
          child: ListView(
            children: [
              SizedBox(
                height: MediaQuery.of(context).size.height * 0.7,
                child: EmptyStateWidget(
                  icon: Icons.history_rounded,
                  title: AppStrings.noSessionsTitle,
                  description: AppStrings.noSessionsBody,
                ),
              ),
            ],
          ),
        ),
      );
    }

    var sessionCardIndex = 0;

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showRecentlyDeleted(context, ref),
        icon: const Icon(Icons.delete_outline),
        label: const Text('Recently Deleted'),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          setState(() {
            _items.clear();
            _cursor = null;
            _hasMore = true;
          });
          await _loadNextPage();
        },
        child: ListView.builder(
          controller: _scrollController,
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
          physics: const AlwaysScrollableScrollPhysics(),
          itemCount: _items.length + (_isLoading ? 1 : 0),
          itemBuilder: (context, index) {
            if (index == _items.length) {
              return const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Center(child: CircularProgressIndicator()),
              );
            }

            final item = _items[index];
            if (item.isHeader) {
              return Padding(
                padding: const EdgeInsets.fromLTRB(4, 16, 4, 8),
                child: Text(
                  DateFormat('EEEE, d MMMM y').format(item.date!),
                  style: tt.labelLarge?.copyWith(
                    color: cs.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.2,
                  ),
                ),
              );
            }

            final session = item.session!;
            final staggerIndex = sessionCardIndex++;
            final total =
                session.presentCount +
                session.absentCount +
                session.onDutyCount;
            final rate = total > 0
                ? (session.presentCount / total * 100).toStringAsFixed(0)
                : '0';

            final card = Card(
              margin: const EdgeInsets.only(bottom: 10),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: () => context.push('/session/${session.sessionId}'),
                onLongPress: () => _showSessionActions(context, ref, session),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  session.label,
                                  style: tt.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  DateFormat('d MMM y').format(session.date),
                                  style: tt.bodySmall?.copyWith(
                                    color: cs.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: cs.secondaryContainer,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              '$rate%',
                              style: tt.labelSmall?.copyWith(
                                color: cs.onSecondaryContainer,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.more_vert_rounded),
                            iconSize: 18,
                            visualDensity: VisualDensity.compact,
                            color: cs.onSurfaceVariant,
                            onPressed: () =>
                                _showSessionActions(context, ref, session),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _MiniStat('P', session.presentCount, cs.primary),
                          _MiniStat('A', session.absentCount, cs.error),
                          _MiniStat('OD', session.onDutyCount, cs.tertiary),
                        ],
                      ),
                      const SizedBox(height: 12),
                      SessionDistributionBar(
                        presentCount: session.presentCount,
                        absentCount: session.absentCount,
                        onDutyCount: session.onDutyCount,
                      ),
                    ],
                  ),
                ),
              ),
            );

            if (!staggerPlayed) {
              return StaggeredListItem(index: staggerIndex, child: card);
            }
            return card;
          },
        ),
      ),
    );
  }

  void _showSessionActions(
    BuildContext context,
    WidgetRef ref,
    SessionSummary session,
  ) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const BottomSheetDragHandle(),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
              child: Text(
                '${session.label} — ${DateFormat('d MMM y').format(session.date)}',
                style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
            ),
            const Divider(height: 1),
            StaggeredSheetAction(
              index: 0,
              child: ListTile(
                leading: Icon(Icons.edit_rounded, color: cs.primary),
                title: const Text('Edit session'),
                onTap: () {
                  Navigator.pop(ctx);
                  context.push(
                    '/edit-session/${widget.classroomId}/${session.sessionId}',
                  );
                },
              ),
            ),
            StaggeredSheetAction(
              index: 1,
              child: ListTile(
                leading: Icon(Icons.copy_all_rounded, color: cs.secondary),
                title: const Text('Copy roll numbers'),
                subtitle: const Text('Categorized by status to clipboard'),
                onTap: () async {
                  Navigator.pop(ctx);
                  await _copyRollNumbers(context, ref, session);
                },
              ),
            ),
            StaggeredSheetAction(
              index: 2,
              child: ListTile(
                leading: Icon(Icons.delete_outline_rounded, color: cs.error),
                title: Text(
                  'Delete session',
                  style: TextStyle(color: cs.error),
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  _showDeleteConfirm(context, ref, session);
                },
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Future<void> _copyRollNumbers(
    BuildContext context,
    WidgetRef ref,
    SessionSummary session,
  ) async {
    try {
      final repo = ref.read(attendanceRepositoryProvider);
      final records = await repo.getRecordsForSession(session.sessionId);

      final present = records
          .where((r) => r.status == AttendanceStatus.present)
          .map((r) => r.rollNumber)
          .join(', ');
      final absent = records
          .where((r) => r.status == AttendanceStatus.absent)
          .map((r) => r.rollNumber)
          .join(', ');
      final onDuty = records
          .where((r) => r.status == AttendanceStatus.onDuty)
          .map((r) => r.rollNumber)
          .join(', ');

      final sb = StringBuffer();
      if (present.isNotEmpty) sb.writeln('Present: $present');
      if (absent.isNotEmpty) sb.writeln('Absent: $absent');
      if (onDuty.isNotEmpty) sb.writeln('On-Duty: $onDuty');

      await Clipboard.setData(ClipboardData(text: sb.toString().trim()));

      if (context.mounted) {
        ErrorSnackBar.show(
          context,
          message: 'Roll numbers copied to clipboard',
          type: ErrorSnackBarType.success,
        );
      }
    } catch (e) {
      if (context.mounted) {
        ErrorSnackBar.show(
          context,
          message: 'Failed to copy roll numbers.',
          type: ErrorSnackBarType.error,
        );
      }
    }
  }

  void _showDeleteConfirm(
    BuildContext context,
    WidgetRef ref,
    SessionSummary session,
  ) {
    final cs = Theme.of(context).colorScheme;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: Icon(Icons.warning_amber_rounded, color: cs.error),
        title: const Text('Delete Session?'),
        content: Text(
          'This will delete the session on ${DateFormat('d MMM y').format(session.date)} and its attendance records. It can be restored within 30 days.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: cs.error,
              foregroundColor: cs.onError,
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await ref.read(deleteSessionProvider)(
                  session.sessionId,
                  widget.classroomId,
                );
                if (context.mounted) {
                  ErrorSnackBar.show(
                    context,
                    message: 'Session moved to recently deleted',
                    type: ErrorSnackBarType.success,
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ErrorSnackBar.show(
                    context,
                    message: 'Failed to delete session. Please try again.',
                    type: ErrorSnackBarType.error,
                  );
                }
              }
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showRecentlyDeleted(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Consumer(
        builder: (ctx, ref, child) {
          final deletedAsync = ref.watch(
            deletedSessionsProvider(widget.classroomId),
          );
          final cs = Theme.of(ctx).colorScheme;
          final tt = Theme.of(ctx).textTheme;

          return DraggableScrollableSheet(
            expand: false,
            initialChildSize: 0.7,
            maxChildSize: 0.9,
            builder: (_, scrollController) => Column(
              children: [
                const BottomSheetDragHandle(),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 8,
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.delete_outline),
                      const SizedBox(width: 8),
                      Text(
                        'Recently Deleted',
                        style: tt.titleLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Text(
                    'Sessions are permanently removed after 30 days.',
                    style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                  ),
                ),
                const Divider(height: 24),
                Expanded(
                  child: deletedAsync.when(
                    data: (sessions) {
                      if (sessions.isEmpty) {
                        return const Center(
                          child: Text('No recently deleted sessions.'),
                        );
                      }
                      return ListView.builder(
                        controller: scrollController,
                        itemCount: sessions.length,
                        itemBuilder: (ctx, index) {
                          final s = sessions[index];
                          return ListTile(
                            title: Text(
                              '${DateFormat('d MMM y').format(s.date)} — ${s.label}',
                            ),
                            subtitle: Text(
                              '${s.presentCount} P · ${s.absentCount} A · ${s.onDutyCount} OD',
                            ),
                            trailing: FilledButton.tonalIcon(
                              onPressed: () async {
                                await ref.read(restoreSessionProvider)(
                                  s.sessionId,
                                  widget.classroomId,
                                );
                                if (ctx.mounted) {
                                  ErrorSnackBar.show(
                                    ctx,
                                    message: 'Session restored',
                                    type: ErrorSnackBarType.success,
                                  );
                                }
                              },
                              icon: const Icon(Icons.restore_rounded, size: 18),
                              label: const Text('Restore'),
                            ),
                          );
                        },
                      );
                    },
                    loading: () => const LoadingIndicator(),
                    error: (e, _) => Center(child: Text('Error: $e')),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

// ── Private helpers ──────────────────────────────────────────────────────────

class _HistoryItem {
  final bool isHeader;
  final DateTime? date;
  final SessionSummary? session;

  const _HistoryItem._({required this.isHeader, this.date, this.session});
  factory _HistoryItem.header(DateTime date) =>
      _HistoryItem._(isHeader: true, date: date);
  factory _HistoryItem.session(SessionSummary s) =>
      _HistoryItem._(isHeader: false, session: s);
}

class _MiniStat extends StatelessWidget {
  final String label;
  final int count;
  final Color color;
  const _MiniStat(this.label, this.count, this.color);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(
          '$count $label',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
