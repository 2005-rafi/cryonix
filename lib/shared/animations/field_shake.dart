import 'package:flutter/material.dart';

import '../../core/constants/ui_constants.dart';

/// Brief horizontal shake when [shakeTrigger] increments (validation errors).
class FieldShake extends StatefulWidget {
  const FieldShake({
    super.key,
    required this.child,
    this.shakeTrigger = 0,
  });

  final Widget child;
  final int shakeTrigger;

  @override
  State<FieldShake> createState() => _FieldShakeState();
}

class _FieldShakeState extends State<FieldShake>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _offset;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: kShakeDuration,
    );
    _offset = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0, end: kShakeOffset), weight: 1),
      TweenSequenceItem(tween: Tween(begin: kShakeOffset, end: -kShakeOffset), weight: 2),
      TweenSequenceItem(tween: Tween(begin: -kShakeOffset, end: kShakeOffset), weight: 2),
      TweenSequenceItem(tween: Tween(begin: kShakeOffset, end: -kShakeOffset), weight: 2),
      TweenSequenceItem(tween: Tween(begin: -kShakeOffset, end: 0), weight: 1),
    ]).animate(CurvedAnimation(parent: _controller, curve: Curves.linear));
  }

  @override
  void didUpdateWidget(FieldShake oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.shakeTrigger != oldWidget.shakeTrigger && widget.shakeTrigger > 0) {
      _controller.forward(from: 0);
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
      animation: _offset,
      builder: (context, child) => Transform.translate(
        offset: Offset(_offset.value, 0),
        child: child,
      ),
      child: widget.child,
    );
  }
}
