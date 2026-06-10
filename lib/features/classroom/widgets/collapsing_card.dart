import 'package:flutter/material.dart';

import '../../../core/constants/ui_constants.dart';

/// Collapses [child] with fade + height when [isCollapsing] becomes true.
class CollapsingCard extends StatefulWidget {
  const CollapsingCard({
    super.key,
    required this.isCollapsing,
    required this.onCollapsed,
    required this.child,
  });

  final bool isCollapsing;
  final VoidCallback onCollapsed;
  final Widget child;

  @override
  State<CollapsingCard> createState() => _CollapsingCardState();
}

class _CollapsingCardState extends State<CollapsingCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _size;
  late final Animation<double> _fade;
  bool _notified = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: kAnimSlow);
    final curved = CurvedAnimation(parent: _controller, curve: kCurveExit);
    _size = Tween<double>(begin: 1, end: 0).animate(curved);
    _fade = Tween<double>(begin: 1, end: 0).animate(curved);
    _controller.addStatusListener(_onStatus);
    if (widget.isCollapsing) _controller.forward();
  }

  @override
  void didUpdateWidget(CollapsingCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isCollapsing && !oldWidget.isCollapsing) {
      _notified = false;
      _controller.forward(from: 0);
    }
  }

  void _onStatus(AnimationStatus status) {
    if (status == AnimationStatus.completed &&
        widget.isCollapsing &&
        !_notified) {
      _notified = true;
      widget.onCollapsed();
    }
  }

  @override
  void dispose() {
    _controller.removeStatusListener(_onStatus);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizeTransition(
      sizeFactor: _size,
      axisAlignment: -1,
      child: FadeTransition(
        opacity: _fade,
        child: widget.child,
      ),
    );
  }
}
