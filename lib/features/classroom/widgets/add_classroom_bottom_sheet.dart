import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../database/app_database.dart';
import '../providers.dart';

class AddClassroomBottomSheet extends ConsumerStatefulWidget {
  final Classroom? existing;
  const AddClassroomBottomSheet({super.key, this.existing});

  @override
  ConsumerState<AddClassroomBottomSheet> createState() => _AddClassroomBottomSheetState();
}

class _AddClassroomBottomSheetState extends ConsumerState<AddClassroomBottomSheet> {
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
      await repo.updateClassroom(widget.existing!.id,
          _nameController.text.trim(), _subjectController.text.trim());
    } else {
      await repo.createClassroom(
          _nameController.text.trim(), _subjectController.text.trim());
    }
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.outlineVariant,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Text(
                widget.existing != null ? 'Edit Classroom' : 'New Classroom',
                style: tt.titleLarge?.copyWith(fontWeight: FontWeight.w600),
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
              const SizedBox(height: 24),
              FilledButton(
                onPressed: _submit,
                child: Text(widget.existing != null ? 'Save Changes' : 'Create Classroom'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
