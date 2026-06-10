import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../shared/animations/staggered_list_item.dart';
import '../../../shared/animations/staggered_sheet_action.dart';
import '../../../shared/empty_state_widget.dart';
import '../../../shared/loading_indicator.dart';
import '../../../shared/widgets/bottom_sheet_handle.dart';
import '../../../shared/confirm_dialog.dart';
import '../../../shared/cryonix_scaffold.dart';

import '../../../shared/widgets/error_snackbar.dart';
import '../providers.dart';
import '../../../database/app_database.dart';
import '../../../services/csv_service.dart';
import '../widgets/csv_format_sheet.dart';
import '../widgets/fade_tab_view.dart';
import '../widgets/pulsing_tab.dart';

class ClassroomDetailScreen extends ConsumerStatefulWidget {
  final String classroomId;
  const ClassroomDetailScreen({super.key, required this.classroomId});

  @override
  ConsumerState<ClassroomDetailScreen> createState() =>
      _ClassroomDetailScreenState();
}

class _ClassroomDetailScreenState extends ConsumerState<ClassroomDetailScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  int _studentsTabPulse = 0;
  int _attendanceTabPulse = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _onTabTap(int index) {
    setState(() {
      if (index == 0) {
        _studentsTabPulse++;
      } else {
        _attendanceTabPulse++;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final classroomAsync = ref.watch(classroomProvider(widget.classroomId));
    final cs = Theme.of(context).colorScheme;

    return CryonixScaffold(
      appBar: AppBar(
        title: classroomAsync.when(
          data: (c) => Text(c?.name ?? 'Classroom'),
          loading: () => const Text('Loading...'),
          error: (e, _) => const Text('Classroom'),
        ),
        bottom: TabBar(
          controller: _tabController,
          onTap: _onTabTap,
          indicatorColor: cs.primary,
          labelColor: cs.primary,
          unselectedLabelColor: cs.onSurfaceVariant,
          tabs: [
            PulsingTab(
              icon: Icons.people_outline_rounded,
              label: 'Students',
              pulseTrigger: _studentsTabPulse,
            ),
            PulsingTab(
              icon: Icons.fact_check_outlined,
              label: 'Attendance',
              pulseTrigger: _attendanceTabPulse,
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline_rounded),
            tooltip: 'CSV format',
            onPressed: () => showCsvFormatSheet(context),
          ),
          IconButton(
            icon: const Icon(Icons.upload_file_rounded),
            tooltip: 'Import CSV',
            onPressed: () =>
                _handleCsvImport(context, ref, widget.classroomId),
          ),
        ],
      ),
      body: FadeTabView(
        controller: _tabController,
        children: [
          _StudentsTab(classroomId: widget.classroomId),
          _AttendanceOverviewTab(classroomId: widget.classroomId),
        ],
      ),
    );
  }

  Future<void> _handleCsvImport(
    BuildContext context,
    WidgetRef ref,
    String classroomId,
  ) async {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    try {
      final parsedResult = await CsvService().pickAndParse(
        onParsingStarted: () {
          if (!context.mounted) return;
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (ctx) => const Center(child: CircularProgressIndicator()),
          );
        },
      );

      if (context.mounted) {
        // Pop the loading dialog if it was shown
        if (Navigator.canPop(context)) {
          Navigator.pop(context);
        }
      }

      if (parsedResult == null) return;

      final parsedStudents = parsedResult.students;

      if (parsedStudents.isEmpty) {
        if (context.mounted) {
          ErrorSnackBar.show(
            context,
            message: 'No valid students found in file',
            type: ErrorSnackBarType.error,
          );
        }
        return;
      }

      if (!context.mounted) return;
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        builder: (ctx) => DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.6,
          maxChildSize: 0.9,
          builder: (_, scrollController) => Column(
            children: [
              const BottomSheetDragHandle(),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Import ${parsedStudents.length} students',
                        style: tt.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: ListView.builder(
                  controller: scrollController,
                  itemCount: parsedStudents.length,
                  itemBuilder: (c, i) {
                    final tile = ListTile(
                      leading: CircleAvatar(
                        backgroundColor: cs.secondaryContainer,
                        child: Text(
                          parsedStudents[i].rollNumber,
                          style: TextStyle(
                            fontSize: 11,
                            color: cs.onSecondaryContainer,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      title: Text(parsedStudents[i].name),
                    );
                    if (i < 5) {
                      return StaggeredListItem(
                        index: i,
                        delayStep: const Duration(milliseconds: 20),
                        child: tile,
                      );
                    }
                    return tile;
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(ctx),
                        child: const Text('Cancel'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton(
                        onPressed: () async {
                          Navigator.pop(ctx);
                          final result = await ref
                              .read(studentRepositoryProvider)
                              .insertStudentsBatch(classroomId, parsedStudents);
                          if (context.mounted) {
                            var message =
                                'Imported ${result.insertedCount} students.';
                            if (result.skippedRolls.isNotEmpty) {
                              message +=
                                  ' Skipped ${result.skippedRolls.length} duplicates.';
                            }
                            if (parsedResult.malformedCount > 0) {
                              message +=
                                  ' Skipped ${parsedResult.malformedCount} malformed.';
                            }
                            if (parsedResult.wasTruncated) {
                              message += ' Truncated to 500 rows.';
                            }
                            ErrorSnackBar.show(
                              context,
                              message: message,
                              type: ErrorSnackBarType.success,
                            );
                          }
                        },
                        child: const Text('Import'),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    } catch (e) {
      if (context.mounted) {
        if (Navigator.canPop(context)) {
          Navigator.pop(context);
        }
        ErrorSnackBar.show(
          context,
          message: 'Import failed. Please check the CSV format.',
          type: ErrorSnackBarType.error,
        );
      }
    }
  }
}

class _StudentsTab extends ConsumerWidget {
  final String classroomId;
  const _StudentsTab({required this.classroomId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final studentsAsync = ref.watch(studentsByClassroomProvider(classroomId));
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Scaffold(
      body: studentsAsync.when(
        data: (students) {
          if (students.isEmpty) {
            return EmptyStateWidget(
              icon: Icons.person_add_outlined,
              title: 'No students yet',
              description: 'Add manually or import a CSV file.',
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(0, 8, 0, 96),
            itemCount: students.length,
            separatorBuilder: (context, index) =>
                const Divider(height: 1, indent: 72),
            itemBuilder: (context, index) {
              final student = students[index];
              return ListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 4,
                ),
                leading: CircleAvatar(
                  backgroundColor: cs.secondaryContainer,
                  child: Text(
                    student.rollNumber.length > 3
                        ? student.rollNumber.substring(0, 3)
                        : student.rollNumber,
                    style: TextStyle(
                      fontSize: 11,
                      color: cs.onSecondaryContainer,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                title: Text(student.name, style: tt.bodyLarge),
                subtitle: Text(
                  student.rollNumber,
                  style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                ),
                onLongPress: () => _showStudentOptions(context, ref, student),
              );
            },
          );
        },
        loading: () => const StudentListLoading(),
        error: (err, _) => Center(child: Text('Error: $err')),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddStudentDialog(context, ref, null),
        child: const Icon(Icons.person_add_rounded),
      ),
    );
  }

  void _showStudentOptions(
    BuildContext context,
    WidgetRef ref,
    Student student,
  ) {
    final cs = Theme.of(context).colorScheme;
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
            StaggeredSheetAction(
              index: 0,
              child: ListTile(
                leading: Icon(Icons.edit_outlined, color: cs.onSurfaceVariant),
                title: const Text('Edit'),
                onTap: () {
                  Navigator.pop(ctx);
                  _showAddStudentDialog(context, ref, student);
                },
              ),
            ),
            StaggeredSheetAction(
              index: 1,
              child: ListTile(
                leading: Icon(Icons.delete_outline_rounded, color: cs.error),
                title: Text('Delete', style: TextStyle(color: cs.error)),
                onTap: () async {
                  Navigator.pop(ctx);
                  final confirm = await showConfirmDialog(
                    context,
                    title: 'Delete Student',
                    message:
                        'Remove ${student.name} from the roster? Past attendance will be preserved.',
                    confirmLabel: 'Delete',
                  );
                  if (confirm == true) {
                    ref
                        .read(studentRepositoryProvider)
                        .deleteStudent(student.id, classroomId);
                  }
                },
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  void _showAddStudentDialog(
    BuildContext context,
    WidgetRef ref,
    Student? existing,
  ) {
    final rollController = TextEditingController(
      text: existing?.rollNumber ?? '',
    );
    final nameController = TextEditingController(text: existing?.name ?? '');
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(existing != null ? 'Edit Student' : 'Add Student'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: rollController,
                decoration: const InputDecoration(
                  labelText: 'Roll Number',
                  prefixIcon: Icon(Icons.tag_rounded),
                ),
                textInputAction: TextInputAction.next,
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Name',
                  prefixIcon: Icon(Icons.person_outline_rounded),
                ),
                textCapitalization: TextCapitalization.words,
                textInputAction: TextInputAction.done,
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Required' : null,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              if (!formKey.currentState!.validate()) return;
              try {
                if (existing != null) {
                  await ref
                      .read(studentRepositoryProvider)
                      .updateStudent(
                        existing.id,
                        classroomId,
                        rollController.text.trim(),
                        nameController.text.trim(),
                      );
                } else {
                  await ref
                      .read(studentRepositoryProvider)
                      .addStudent(
                        classroomId,
                        rollController.text.trim(),
                        nameController.text.trim(),
                      );
                }
                if (ctx.mounted) {
                  Navigator.pop(ctx);
                  ErrorSnackBar.show(
                    ctx,
                    message: existing != null ? 'Student updated' : 'Student added',
                    type: ErrorSnackBarType.success,
                  );
                }
              } catch (e) {
                if (ctx.mounted) {
                  ErrorSnackBar.show(
                    ctx,
                    message: 'Failed to save student. Make sure the roll number is unique.',
                    type: ErrorSnackBarType.error,
                  );
                }
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}

class _AttendanceOverviewTab extends StatelessWidget {
  final String classroomId;
  const _AttendanceOverviewTab({required this.classroomId});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: cs.primaryContainer,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Icon(
                Icons.fact_check_rounded,
                size: 40,
                color: cs.onPrimaryContainer,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Attendance',
              style: tt.titleLarge?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text(
              'Manage sessions and take attendance for this classroom.',
              style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 28),
            FilledButton.icon(
              onPressed: () => context.push('/attendance/$classroomId'),
              icon: const Icon(Icons.playlist_add_check_rounded),
              label: const Text('Take Attendance'),
            ),
          ],
        ),
      ),
    );
  }
}
