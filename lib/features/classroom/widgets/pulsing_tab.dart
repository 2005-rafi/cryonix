import 'package:flutter/material.dart';

import '../../../core/constants/ui_constants.dart';

class PulsingTab extends StatefulWidget {
  const PulsingTab({
    super.key,
    required this.icon,
    required this.label,
    required this.pulseTrigger,
  });

  final IconData icon;
  final String label;
  final int pulseTrigger;

  @override
  State<PulsingTab> createState() => _PulsingTabState();
}

class _PulsingTabState extends State<PulsingTab>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: kAnimFast);
    _scale = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1, end: 0.9), weight: 50),
      TweenSequenceItem(tween: Tween(begin: 0.9, end: 1), weight: 50),
    ]).animate(CurvedAnimation(parent: _controller, curve: kCurveStandard));
  }

  @override
  void didUpdateWidget(PulsingTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.pulseTrigger != oldWidget.pulseTrigger) {
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
    return Tab(
      child: ScaleTransition(
        scale: _scale,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(widget.icon, size: 22),
            const SizedBox(height: 2),
            Text(widget.label),
          ],
        ),
      ),
    );
  }
}
