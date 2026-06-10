import 'package:flutter/material.dart';

import '../../core/constants/ui_constants.dart';

/// Drag handle for bottom sheets — 44px tap target, optional shadow while dragging.
class BottomSheetDragHandle extends StatelessWidget {
  const BottomSheetDragHandle({
    super.key,
    this.dragExtent = 0,
  });

  /// Non-zero when the parent [DraggableScrollableSheet] is being dragged.
  final double dragExtent;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final showShadow = dragExtent > 0.02;

    return SizedBox(
      height: 44,
      child: Center(
        child: AnimatedContainer(
          duration: kAnimFast,
          decoration: showShadow
              ? BoxDecoration(
                  boxShadow: [
                    BoxShadow(
                      color: cs.shadow.withValues(alpha: 0.12),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                )
              : null,
          child: Container(
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: cs.outlineVariant,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ),
      ),
    );
  }
}
