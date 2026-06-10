import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/ui_constants.dart';
import '../../../shared/animations/staggered_list_item.dart';
import '../../../shared/loading_indicator.dart';
import '../../auth/providers.dart';
import '../providers.dart';
import '../providers/home_ui_providers.dart';
import '../../../database/app_database.dart';
import '../repository/classroom_repository.dart';
import '../widgets/add_classroom_form.dart';
import '../widgets/classroom_options_sheet.dart';
import '../widgets/collapsing_card.dart';
import '../widgets/home_empty_state.dart';
import '../../../shared/widgets/error_snackbar.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen>
    with SingleTickerProviderStateMixin {
  final Map<String, Timer> _deleteTimers = {};
  Set<String> _previousClassroomIds = {};
  late final AnimationController _fabController;
  late final Animation<double> _fabScale;
  bool _fabVisible = false;
  late ClassroomRepository _repo;

  @override
  void initState() {
    super.initState();
    _fabController = AnimationController(vsync: this, duration: kAnimNormal);
    _fabScale = CurvedAnimation(parent: _fabController, curve: kCurveSpring);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _repo = ref.read(classroomRepositoryProvider);
  }

  @override
  void dispose() {
    for (final timer in _deleteTimers.values) {
      timer.cancel();
    }
    _flushPendingDeletes();
    _fabController.dispose();
    super.dispose();
  }

  void _flushPendingDeletes() {
    if (_deleteTimers.isEmpty) return;
    for (final id in _deleteTimers.keys) {
      _repo.deleteClassroom(id);
    }
  }

  void _trackNewClassrooms(List<Classroom> classrooms) {
    final ids = classrooms.map((c) => c.id).toSet();
    if (_previousClassroomIds.isNotEmpty) {
      final added = ids.difference(_previousClassroomIds);
      if (added.isNotEmpty) {
        ref.read(newlyAnimatedClassroomIdsProvider.notifier).state =
            Set<String>.from(added);
        Future<void>.delayed(kAnimEntrance, () {
          if (mounted) {
            ref.read(newlyAnimatedClassroomIdsProvider.notifier).state = {};
          }
        });
      }
    }
    _previousClassroomIds = ids;
  }

  void _updateFabVisibility(bool show) {
    if (show == _fabVisible) return;
    _fabVisible = show;
    if (show) {
      _fabController.forward(from: 0);
    } else {
      _fabController.reverse();
    }
  }

  void _scheduleDelete(Classroom classroom) {
    ref
        .read(collapsingClassroomIdsProvider.notifier)
        .update((s) => {...s, classroom.id});
  }

  void _onCardCollapsed(Classroom classroom) {
    ref
        .read(collapsingClassroomIdsProvider.notifier)
        .update((s) => {...s}..remove(classroom.id));
    ref
        .read(pendingDeleteClassroomIdsProvider.notifier)
        .update((s) => {...s, classroom.id});

    ErrorSnackBar.show(
      context,
      message: 'Deleted "${classroom.name}"',
      type: ErrorSnackBarType.success,
      duration: const Duration(seconds: 5),
      actionLabel: 'Undo',
      onActionPressed: () => _undoDelete(classroom.id),
    );

    _deleteTimers[classroom.id]?.cancel();
    _deleteTimers[classroom.id] = Timer(const Duration(seconds: 5), () {
      if (!mounted) return;
      final pending = ref.read(pendingDeleteClassroomIdsProvider);
      if (pending.contains(classroom.id)) {
        ref
            .read(pendingDeleteClassroomIdsProvider.notifier)
            .update((s) => {...s}..remove(classroom.id));
        ref.read(classroomRepositoryProvider).deleteClassroom(classroom.id);
      }
      _deleteTimers.remove(classroom.id);
    });
  }

  void _undoDelete(String classroomId) {
    _deleteTimers[classroomId]?.cancel();
    _deleteTimers.remove(classroomId);
    ref
        .read(pendingDeleteClassroomIdsProvider.notifier)
        .update((s) => {...s}..remove(classroomId));
    ref
        .read(newlyAnimatedClassroomIdsProvider.notifier)
        .update((s) => {...s, classroomId});
    Future<void>.delayed(kAnimEntrance, () {
      if (mounted) {
        ref
            .read(newlyAnimatedClassroomIdsProvider.notifier)
            .update((s) => {...s}..remove(classroomId));
      }
    });
  }

  void _showAddClassroomSheet({Classroom? existing}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: AddClassroomForm(existing: existing),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    if (user == null) {
      return const Scaffold(body: Center(child: Text('Not signed in')));
    }

    final filteredAsync = ref.watch(filteredClassroomsProvider(user.uid));
    final classroomsAsync = ref.watch(classroomListProvider(user.uid));
    final staggerPlayed = ref.watch(homeListStaggerPlayedProvider);
    final collapsing = ref.watch(collapsingClassroomIdsProvider);
    final newlyAnimated = ref.watch(newlyAnimatedClassroomIdsProvider);
    final cs = Theme.of(context).colorScheme;

    ref.listen<AsyncValue<List<Classroom>>>(classroomListProvider(user.uid), (
      previous,
      next,
    ) {
      next.whenData(_trackNewClassrooms);
    });

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final shouldQuit = await _showQuitConfirmationDialog(context);
        if (shouldQuit == true) {
          await SystemNavigator.pop();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Cryonix'),
        ),
        body: AnimatedSwitcher(
        duration: kAnimNormal,
        switchInCurve: kCurveEnter,
        switchOutCurve: kCurveExit,
        child: filteredAsync.when(
          data: (visible) {
            final rawList = classroomsAsync.value ?? [];

            if (visible.isNotEmpty && !staggerPlayed) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                ref.read(homeListStaggerPlayedProvider.notifier).state = true;
              });
            }

            _updateFabVisibility(visible.isNotEmpty);

            if (visible.isEmpty && rawList.isEmpty) {
              return HomeEmptyState(
                key: const ValueKey('home-empty'),
                onCreatePressed: () => _showAddClassroomSheet(),
              );
            }

            return ListView.builder(
              key: const ValueKey('classroom-list'),
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
              itemCount: visible.length,
              itemBuilder: (context, index) {
                final classroom = visible[index];
                final isNew = newlyAnimated.contains(classroom.id);
                final shouldStagger = !staggerPlayed || isNew;
                final staggerIndex = isNew ? 0 : index;

                final card = _ClassroomCard(
                  classroom: classroom,
                  onEdit: (c) => showEditClassroomSheet(context, c),
                  onDeleteConfirmed: _scheduleDelete,
                );

                final wrapped = CollapsingCard(
                  isCollapsing: collapsing.contains(classroom.id),
                  onCollapsed: () => _onCardCollapsed(classroom),
                  child: card,
                );

                if (!shouldStagger) return wrapped;

                return StaggeredListItem(index: staggerIndex, child: wrapped);
              },
            );
          },
          loading: () =>
              const ClassroomListLoading(key: ValueKey('classroom-skeleton')),
          error: (err, _) => Center(
            key: const ValueKey('classroom-error'),
            child: Text('Error: $err', style: TextStyle(color: cs.error)),
          ),
        ),
      ),
      floatingActionButton: ScaleTransition(
        scale: _fabScale,
        child: _fabVisible
            ? FloatingActionButton.extended(
                onPressed: () => _showAddClassroomSheet(),
                icon: const Icon(Icons.add_rounded),
                label: const Text('New Classroom'),
              )
            : const SizedBox.shrink(),
      ),
        ),
    );
  }

  Future<bool?> _showQuitConfirmationDialog(BuildContext context) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Exit Cryonix?'),
        content: const Text(
          'Are you sure you want to exit? Your attendance records are saved locally.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Stay'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Exit'),
          ),
        ],
      ),
    );
  }
}

class _ClassroomCard extends ConsumerWidget {
  final Classroom classroom;
  final void Function(Classroom) onEdit;
  final void Function(Classroom) onDeleteConfirmed;

  const _ClassroomCard({
    required this.classroom,
    required this.onEdit,
    required this.onDeleteConfirmed,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    void openOptions() {
      showClassroomOptionsSheet(
        context: context,
        ref: ref,
        classroom: classroom,
        onEdit: onEdit,
        onDeleteConfirmed: onDeleteConfirmed,
      );
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.push('/classroom/${classroom.id}'),
        onLongPress: openOptions,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: cs.primaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.class_rounded,
                  color: cs.onPrimaryContainer,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      classroom.name,
                      style: tt.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (classroom.subject != null &&
                        classroom.subject!.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        classroom.subject!,
                        style: tt.bodySmall?.copyWith(
                          color: cs.onSurfaceVariant,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: cs.secondaryContainer,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${classroom.studentCount}',
                  style: tt.labelMedium?.copyWith(
                    color: cs.onSecondaryContainer,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 4),
              Icon(Icons.chevron_right_rounded, color: cs.onSurfaceVariant),
              IconButton(
                icon: Icon(
                  Icons.more_vert,
                  size: 16,
                  color: cs.onSurfaceVariant.withValues(alpha: 0.6),
                ),
                onPressed: openOptions,
                visualDensity: VisualDensity.compact,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                tooltip: 'More options',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
