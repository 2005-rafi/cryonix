import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../database/app_database.dart';
import '../../../shared/widgets/bottom_sheet_handle.dart';
import '../providers.dart';

class AddClassroomForm extends ConsumerStatefulWidget {
  final Classroom? existing;
  const AddClassroomForm({super.key, this.existing});

  @override
  ConsumerState<AddClassroomForm> createState() => _AddClassroomFormState();
}

class _AddClassroomFormState extends ConsumerState<AddClassroomForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _subjectController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.existing?.name ?? '');
    _subjectController =
        TextEditingController(text: widget.existing?.subject ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _subjectController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final repo = ref.read(classroomRepositoryProvider);
    if (widget.existing != null) {
      await repo.updateClassroom(
        widget.existing!.id,
        _nameController.text.trim(),
        _subjectController.text.trim(),
      );
    } else {
      await repo.createClassroom(
        _nameController.text.trim(),
        _subjectController.text.trim(),
      );
    }
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final saveLabel =
        widget.existing != null ? 'Save Changes' : 'Create Classroom';

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.55,
      minChildSize: 0.4,
      maxChildSize: 0.92,
      builder: (context, scrollController) {
        return Column(
          children: [
            const BottomSheetDragHandle(),
            Expanded(
              child: SingleChildScrollView(
                controller: scrollController,
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        widget.existing != null
                            ? 'Edit Classroom'
                            : 'New Classroom',
                        style:
                            tt.titleLarge?.copyWith(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 20),
                      TextFormField(
                        controller: _nameController,
                        decoration: const InputDecoration(
                          labelText: 'Classroom Name',
                          hintText: 'e.g. Grade 10A',
                          prefixIcon: Icon(Icons.class_outlined),
                        ),
                        validator: (v) =>
                            v == null || v.trim().isEmpty ? 'Required' : null,
                        textCapitalization: TextCapitalization.words,
                        textInputAction: TextInputAction.next,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _subjectController,
                        decoration: const InputDecoration(
                          labelText: 'Subject',
                          hintText: 'Optional',
                          prefixIcon: Icon(Icons.book_outlined),
                        ),
                        textCapitalization: TextCapitalization.words,
                        textInputAction: TextInputAction.done,
                        onFieldSubmitted: (_) => _submit(),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 20),
              child: FilledButton(
                onPressed: _submit,
                child: Text(saveLabel),
              ),
            ),
          ],
        );
      },
    );
  }
}
