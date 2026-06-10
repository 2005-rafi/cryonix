import 'package:flutter/material.dart';

import '../animations/animation_motion.dart';

/// Horizontal shimmer wave across placeholder blocks (theme-aware).
class ShimmerBox extends StatefulWidget {
  const ShimmerBox({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius = 8,
  });

  final double width;
  final double height;
  final double borderRadius;

  @override
  State<ShimmerBox> createState() => _ShimmerBoxState();
}

class _ShimmerBoxState extends State<ShimmerBox>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (isReduceMotion(context)) {
        _controller.value = 0.5;
      } else {
        _controller.repeat();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final base = cs.surfaceContainerHigh;
    final highlight = cs.surfaceContainer;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.borderRadius),
            gradient: LinearGradient(
              begin: Alignment(-1 + 2 * _controller.value, 0),
              end: Alignment(-0.5 + 2 * _controller.value, 0),
              colors: [base, highlight, base],
            ),
          ),
        );
      },
    );
  }
}

/// Skeleton row matching a classroom card on the home screen.
class ClassroomCardSkeleton extends StatelessWidget {
  const ClassroomCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            ShimmerBox(width: 48, height: 48, borderRadius: 12),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  ShimmerBox(width: 120, height: 14, borderRadius: 4),
                  SizedBox(height: 8),
                  ShimmerBox(width: 80, height: 10, borderRadius: 4),
                ],
              ),
            ),
            const SizedBox(width: 12),
            ShimmerBox(width: 36, height: 24, borderRadius: 20),
          ],
        ),
      ),
    );
  }
}

/// Skeleton matching a session card in the history tab.
class SessionCardSkeleton extends StatelessWidget {
  const SessionCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  ShimmerBox(width: 140, height: 16, borderRadius: 4),
                  SizedBox(height: 10),
                  ShimmerBox(width: 180, height: 10, borderRadius: 4),
                ],
              ),
            ),
            const SizedBox(width: 8),
            ShimmerBox(width: 48, height: 8, borderRadius: 4),
            const SizedBox(width: 8),
            ShimmerBox(width: 40, height: 24, borderRadius: 20),
          ],
        ),
      ),
    );
  }
}

/// Skeleton matching a student list tile in classroom detail.
class StudentListTileSkeleton extends StatelessWidget {
  const StudentListTileSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          ShimmerBox(width: 40, height: 40, borderRadius: 20),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                ShimmerBox(width: 160, height: 14, borderRadius: 4),
                SizedBox(height: 6),
                ShimmerBox(width: 72, height: 10, borderRadius: 4),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class ClassroomListSkeleton extends StatelessWidget {
  const ClassroomListSkeleton({super.key, this.itemCount = 4});

  final int itemCount;

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
      itemCount: itemCount,
      itemBuilder: (context, index) => const ClassroomCardSkeleton(),
    );
  }
}

class SessionListSkeleton extends StatelessWidget {
  const SessionListSkeleton({super.key, this.itemCount = 5});

  final int itemCount;

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
      itemCount: itemCount,
      itemBuilder: (context, index) => const SessionCardSkeleton(),
    );
  }
}

class StudentListSkeleton extends StatelessWidget {
  const StudentListSkeleton({super.key, this.itemCount = 6});

  final int itemCount;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(0, 8, 0, 96),
      itemCount: itemCount,
      separatorBuilder: (context, index) =>
          const Divider(height: 1, indent: 72),
      itemBuilder: (context, index) => const StudentListTileSkeleton(),
    );
  }
}
