import 'package:flutter/material.dart';

import '../core/constants/ui_constants.dart';
import 'animations/animation_motion.dart';

/// Shared empty state: icon → title → description → optional CTA (80ms stagger).
class EmptyStateWidget extends StatefulWidget {
  const EmptyStateWidget({
    super.key,
    required this.icon,
    required this.title,
    required this.description,
    this.cta,
    this.iconBackgroundColor,
    this.iconColor,
  });

  final IconData icon;
  final String title;
  final String description;
  final Widget? cta;
  final Color? iconBackgroundColor;
  final Color? iconColor;

  @override
  State<EmptyStateWidget> createState() => _EmptyStateWidgetState();
}

class _EmptyStateWidgetState extends State<EmptyStateWidget>
    with TickerProviderStateMixin {
  static const _staggerStep = Duration(milliseconds: 80);

  bool _entranceStarted = false;

  late final AnimationController _iconController;
  late final AnimationController _titleController;
  late final AnimationController _descController;
  late final AnimationController _ctaController;

  late final Animation<double> _iconFade;
  late final Animation<double> _iconScale;
  late final Animation<double> _titleFade;
  late final Animation<double> _descFade;
  late final Animation<double> _ctaFade;

  @override
  void initState() {
    super.initState();
    _iconController = AnimationController(
      vsync: this,
      duration: kAnimEntrance,
    );
    _titleController = AnimationController(
      vsync: this,
      duration: kAnimEntrance,
    );
    _descController = AnimationController(
      vsync: this,
      duration: kAnimEntrance,
    );
    _ctaController = AnimationController(
      vsync: this,
      duration: kAnimEntrance,
    );

    final iconCurve = CurvedAnimation(
      parent: _iconController,
      curve: kCurveEnter,
    );
    _iconFade = Tween<double>(begin: 0, end: 1).animate(iconCurve);
    _iconScale = Tween<double>(begin: 0.9, end: 1).animate(
      CurvedAnimation(parent: _iconController, curve: kCurveSpring),
    );

    _titleFade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _titleController, curve: kCurveEnter),
    );
    _descFade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _descController, curve: kCurveEnter),
    );
    _ctaFade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _ctaController, curve: kCurveEnter),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_entranceStarted) return;
    _entranceStarted = true;

    if (isReduceMotion(context)) {
      _iconController.value = 1;
      _titleController.value = 1;
      _descController.value = 1;
      _ctaController.value = 1;
      return;
    }

    _iconController.forward();
    Future<void>.delayed(_staggerStep, () {
      if (mounted) _titleController.forward();
    });
    Future<void>.delayed(_staggerStep * 2, () {
      if (mounted) _descController.forward();
    });
    if (widget.cta != null) {
      Future<void>.delayed(_staggerStep * 3, () {
        if (mounted) _ctaController.forward();
      });
    }
  }

  @override
  void dispose() {
    _iconController.dispose();
    _titleController.dispose();
    _descController.dispose();
    _ctaController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final bg = widget.iconBackgroundColor ?? cs.surfaceContainerHigh;
    final fg = widget.iconColor ?? cs.onSurfaceVariant;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            FadeTransition(
              opacity: _iconFade,
              child: ScaleTransition(
                scale: _iconScale,
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: bg,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Icon(widget.icon, size: 40, color: fg),
                ),
              ),
            ),
            const SizedBox(height: 20),
            FadeTransition(
              opacity: _titleFade,
              child: Text(
                widget.title,
                style: tt.titleLarge?.copyWith(fontWeight: FontWeight.w600),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 8),
            FadeTransition(
              opacity: _descFade,
              child: Text(
                widget.description,
                style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
                textAlign: TextAlign.center,
              ),
            ),
            if (widget.cta != null) ...[
              const SizedBox(height: 28),
              FadeTransition(
                opacity: _ctaFade,
                child: widget.cta!,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
