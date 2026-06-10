import 'package:flutter/material.dart';

import '../../../shared/empty_state_widget.dart';

class HomeEmptyState extends StatefulWidget {
  const HomeEmptyState({super.key, required this.onCreatePressed});

  final VoidCallback onCreatePressed;

  @override
  State<HomeEmptyState> createState() => _HomeEmptyStateState();
}

class _HomeEmptyStateState extends State<HomeEmptyState>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;
  late final Animation<double> _pulseScale;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _pulseScale = Tween<double>(begin: 1, end: 1.02).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return EmptyStateWidget(
      icon: Icons.class_outlined,
      title: 'No classrooms yet',
      description: 'Create your first classroom to get started.',
      cta: ScaleTransition(
        scale: _pulseScale,
        child: FilledButton.icon(
          onPressed: widget.onCreatePressed,
          icon: const Icon(Icons.add_rounded),
          label: const Text('Create Classroom'),
        ),
      ),
    );
  }
}
