import 'package:flutter/material.dart';

import '../../core/constants/ui_constants.dart';
import 'animation_motion.dart';

/// Fades in a bottom-sheet action row with [index] × 50ms delay.
class StaggeredSheetAction extends StatefulWidget {
  const StaggeredSheetAction({
    super.key,
    required this.index,
    required this.child,
  });

  final int index;
  final Widget child;

  @override
  State<StaggeredSheetAction> createState() => _StaggeredSheetActionState();
}

class _StaggeredSheetActionState extends State<StaggeredSheetAction> {
  double _opacity = 0;
  bool _started = false;

  @override
  void initState() {
    super.initState();
    final delay = Duration(milliseconds: widget.index * 50);
    if (delay == Duration.zero) {
      _opacity = 1;
    } else {
      Future<void>.delayed(delay, () {
        if (mounted) setState(() => _opacity = 1);
      });
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    if (isReduceMotion(context) && _opacity < 1) {
      setState(() => _opacity = 1);
    }
  }

  @override
  Widget build(BuildContext context) {
    final duration = motionDuration(context, kAnimFast);
    return AnimatedOpacity(
      opacity: _opacity,
      duration: duration,
      curve: kCurveEnter,
      child: widget.child,
    );
  }
}
