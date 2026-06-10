import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../database/app_database.dart';
import '../../../shared/animations/staggered_sheet_action.dart';
import '../../../shared/confirm_dialog.dart';
import '../../../shared/widgets/bottom_sheet_handle.dart';
import 'add_classroom_form.dart';

void showClassroomOptionsSheet({
  required BuildContext context,
  required WidgetRef ref,
  required Classroom classroom,
  required void Function(Classroom) onEdit,
  required void Function(Classroom) onDeleteConfirmed,
}) {
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
                onEdit(classroom);
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
                  title: 'Delete Classroom',
                  message:
                      'Delete "${classroom.name}"? All students and records will be permanently removed.',
                  confirmLabel: 'Delete',
                );
                if (confirm == true) {
                  onDeleteConfirmed(classroom);
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

void showEditClassroomSheet(BuildContext context, Classroom classroom) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (ctx) => Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
      child: AddClassroomForm(existing: classroom),
    ),
  );
}
