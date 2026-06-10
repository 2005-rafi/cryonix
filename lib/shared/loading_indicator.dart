import 'package:flutter/material.dart';

import 'widgets/skeleton_loading.dart';

class LoadingIndicator extends StatelessWidget {
  final String? message;

  const LoadingIndicator({super.key, this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(),
          if (message != null) ...[
            const SizedBox(height: 16),
            Text(
              message!,
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }
}

/// List skeleton for the home classroom list (Phase 6).
class ClassroomListLoading extends StatelessWidget {
  const ClassroomListLoading({super.key});

  @override
  Widget build(BuildContext context) => const ClassroomListSkeleton();
}

/// List skeleton for the attendance history tab (Phase 6).
class SessionListLoading extends StatelessWidget {
  const SessionListLoading({super.key});

  @override
  Widget build(BuildContext context) => const SessionListSkeleton();
}

/// List skeleton for the classroom student roster (Phase 6).
class StudentListLoading extends StatelessWidget {
  const StudentListLoading({super.key});

  @override
  Widget build(BuildContext context) => const StudentListSkeleton();
}
