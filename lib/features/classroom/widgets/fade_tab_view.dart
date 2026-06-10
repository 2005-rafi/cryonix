import 'package:flutter/material.dart';

/// Cross-fades tab children instead of horizontal page scroll.
class FadeTabView extends StatelessWidget {
  const FadeTabView({
    super.key,
    required this.controller,
    required this.children,
  });

  final TabController controller;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller.animation!,
      builder: (context, _) {
        final value = controller.animation!.value;
        return Stack(
          fit: StackFit.expand,
          children: List.generate(children.length, (i) {
            final distance = (value - i).abs();
            final opacity = (1 - distance).clamp(0.0, 1.0);
            return IgnorePointer(
              ignoring: opacity < 0.5,
              child: Opacity(
                opacity: opacity,
                child: children[i],
              ),
            );
          }),
        );
      },
    );
  }
}
