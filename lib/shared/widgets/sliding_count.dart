import 'package:flutter/material.dart';

import '../../core/constants/ui_constants.dart';

/// Count label that slides up when [value] changes.
class SlidingCount extends StatelessWidget {
  const SlidingCount({
    super.key,
    required this.value,
    this.style,
  });

  final int value;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: kAnimFast,
      switchInCurve: kCurveEnter,
      switchOutCurve: kCurveExit,
      transitionBuilder: (child, animation) {
        final offset = Tween<Offset>(
          begin: const Offset(0, 0.4),
          end: Offset.zero,
        ).animate(animation);
        return SlideTransition(
          position: offset,
          child: FadeTransition(opacity: animation, child: child),
        );
      },
      child: Text(
        '$value',
        key: ValueKey<int>(value),
        style: style,
      ),
    );
  }
}
