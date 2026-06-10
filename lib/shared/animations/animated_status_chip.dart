import 'package:flutter/material.dart';

import '../../core/constants/ui_constants.dart';

/// Attendance status chip with color cross-fade and tap scale feedback.
///
/// Animation state lives here so parent list rebuilds do not reset the controller.
/// Wire into taking grid / session detail in a later phase.
class AnimatedStatusChip extends StatefulWidget {
  const AnimatedStatusChip({
    super.key,
    required this.status,
    required this.label,
    required this.backgroundColor,
    required this.foregroundColor,
    required this.onTap,
    this.isSelected = true,
    this.inactiveBorderColor,
    this.minWidth = 44,
    this.minHeight = 44,
  });

  final String status;
  final String label;
  final Color backgroundColor;
  final Color foregroundColor;
  final VoidCallback onTap;
  final bool isSelected;
  final Color? inactiveBorderColor;
  final double minWidth;
  final double minHeight;

  @override
  State<AnimatedStatusChip> createState() => _AnimatedStatusChipState();
}

class _AnimatedStatusChipState extends State<AnimatedStatusChip>
    with TickerProviderStateMixin {
  late AnimationController _colorController;
  late AnimationController _scaleController;
  late Animation<Color?> _colorAnimation;
  late Animation<double> _scaleAnimation;

  Color _fromColor = Colors.transparent;
  Color _toColor = Colors.transparent;

  @override
  void initState() {
    super.initState();
    _fromColor = widget.backgroundColor;
    _toColor = widget.backgroundColor;

    _colorController = AnimationController(
      vsync: this,
      duration: kAnimFast,
    );
    _scaleController = AnimationController(
      vsync: this,
      duration: kAnimFast,
    );

    _colorAnimation = ColorTween(begin: _fromColor, end: _toColor).animate(
      CurvedAnimation(parent: _colorController, curve: kCurveStandard),
    );
    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(begin: 1.0, end: 0.95),
        weight: 50,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 0.95, end: 1.0),
        weight: 50,
      ),
    ]).animate(
      CurvedAnimation(parent: _scaleController, curve: kCurveSpring),
    );

    _colorController.value = 1;
  }

  Color _resolvedBackground(bool selected) =>
      selected ? widget.backgroundColor : Colors.transparent;

  @override
  void didUpdateWidget(AnimatedStatusChip oldWidget) {
    super.didUpdateWidget(oldWidget);
    final oldBg = _resolvedBackground(oldWidget.isSelected);
    final newBg = _resolvedBackground(widget.isSelected);
    if (oldBg != newBg || oldWidget.backgroundColor != widget.backgroundColor) {
      _fromColor = oldWidget.isSelected
          ? oldWidget.backgroundColor
          : Colors.transparent;
      _toColor = widget.isSelected ? widget.backgroundColor : Colors.transparent;
      _colorAnimation = ColorTween(begin: _fromColor, end: _toColor).animate(
        CurvedAnimation(parent: _colorController, curve: kCurveStandard),
      );
      _colorController
        ..reset()
        ..forward();
    }
  }

  @override
  void dispose() {
    _colorController.dispose();
    _scaleController.dispose();
    super.dispose();
  }

  void _handleTap() {
    _scaleController.forward(from: 0);
    widget.onTap();
  }

  @override
  Widget build(BuildContext context) {
    final borderColor = widget.isSelected
        ? (_colorAnimation.value ?? widget.backgroundColor)
        : (widget.inactiveBorderColor ??
            Theme.of(context).colorScheme.outlineVariant);

    return ScaleTransition(
      scale: _scaleAnimation,
      child: AnimatedBuilder(
        animation: _colorAnimation,
        builder: (context, child) {
          final bg = widget.isSelected
              ? (_colorAnimation.value ?? widget.backgroundColor)
              : Colors.transparent;
          return Material(
            color: bg,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
              side: BorderSide(color: borderColor, width: 1.5),
            ),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: _handleTap,
              child: Container(
                constraints: BoxConstraints(
                  minWidth: widget.minWidth,
                  minHeight: widget.minHeight,
                ),
                alignment: Alignment.center,
                child: Text(
                  widget.label,
                  style: TextStyle(
                    color: widget.isSelected
                        ? widget.foregroundColor
                        : Theme.of(context).colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
