import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/constants/ui_constants.dart';
import 'animation_motion.dart';

/// Wraps a list child with a one-time fade + slide-up entrance on first insert.
///
/// Delay is [index] × [delayStep], capped at [kStaggerMaxDelay].
/// Apply in Phase 3+ screens; does not replay when the parent list rebuilds
/// unless the widget is removed and re-inserted.
class StaggeredListItem extends StatefulWidget {
  const StaggeredListItem({
    super.key,
    required this.index,
    required this.child,
    this.delayStep = kStaggerItemStep,
    this.animate = true,
  });

  final int index;
  final Widget child;
  final Duration delayStep;

  /// When false, renders [child] without animation (e.g. returning navigation).
  final bool animate;

  @override
  State<StaggeredListItem> createState() => _StaggeredListItemState();
}

class _StaggeredListItemState extends State<StaggeredListItem>
    with SingleTickerProviderStateMixin {
  bool _entranceStarted = false;

  late final AnimationController _controller;
  late final Animation<double> _fade;
  late final Animation<double> _slideY;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: kAnimEntrance,
    );
    final curved = CurvedAnimation(
      parent: _controller,
      curve: kCurveEnter,
    );
    _fade = Tween<double>(begin: 0, end: 1).animate(curved);
    _slideY = Tween<double>(
      begin: kStaggerSlideOffset,
      end: 0,
    ).animate(curved);

    if (!widget.animate) {
      _controller.value = 1;
      return;
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_entranceStarted) return;
    _entranceStarted = true;
    if (!widget.animate) return;

    if (isReduceMotion(context)) {
      _controller.value = 1;
      return;
    }

    final delayMs = math.min(
      widget.index * widget.delayStep.inMilliseconds,
      kStaggerMaxDelay.inMilliseconds,
    );
    if (delayMs == 0) {
      _controller.forward();
    } else {
      Future<void>.delayed(Duration(milliseconds: delayMs), () {
        if (mounted) _controller.forward();
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Opacity(
          opacity: _fade.value,
          child: Transform.translate(
            offset: Offset(0, _slideY.value),
            child: child,
          ),
        );
      },
      child: widget.child,
    );
  }
}
