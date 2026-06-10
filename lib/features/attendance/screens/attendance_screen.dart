import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../shared/cryonix_scaffold.dart';
import 'package:cryonix/features/classroom/providers.dart';
import '../../classroom/widgets/pulsing_tab.dart';
import '../models/attendance_route_args.dart';
import '../widgets/taking_tab.dart';
import '../widgets/history_tab.dart';

class AttendanceScreen extends ConsumerStatefulWidget {
  final String classroomId;
  final AttendanceRouteArgs? routeArgs;

  const AttendanceScreen({
    super.key,
    required this.classroomId,
    this.routeArgs,
  });

  @override
  ConsumerState<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends ConsumerState<AttendanceScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _historyTabPulse = 0;

  @override
  void initState() {
    super.initState();
    final initialTab = widget.routeArgs?.initialTabIndex ?? 0;
    _tabController = TabController(
      length: 2,
      vsync: this,
      initialIndex: initialTab.clamp(0, 1),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _onSaveSuccess() {
    _tabController.animateTo(1);
    setState(() => _historyTabPulse++);
  }

  @override
  Widget build(BuildContext context) {
    final classroomAsync = ref.watch(classroomProvider(widget.classroomId));
    final cs = Theme.of(context).colorScheme;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        context.go('/attendance-overview');
      },
      child: CryonixScaffold(
        appBar: AppBar(
          title: classroomAsync.when(
          data: (c) => Text('${c?.name ?? "Class"} — Attendance'),
          loading: () => const Text('Attendance'),
          error: (e, _) => const Text('Attendance'),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: cs.primary,
          labelColor: cs.primary,
          unselectedLabelColor: cs.onSurfaceVariant,
          tabs: [
            const Tab(icon: Icon(Icons.edit_calendar_outlined), text: 'Take'),
            PulsingTab(
              icon: Icons.history_rounded,
              label: 'History',
              pulseTrigger: _historyTabPulse,
            ),
          ],
        ),
      ),
      body: TabBarView(
        key: const PageStorageKey<String>('attendance_tab_view'),
        controller: _tabController,
        children: [
          TakingTab(
            classroomId: widget.classroomId,
            initialDate: widget.routeArgs?.initialDate,
            onSaveSuccess: _onSaveSuccess,
          ),
          HistoryTab(classroomId: widget.classroomId),
        ],
      ),
      ),
    );
  }
}
