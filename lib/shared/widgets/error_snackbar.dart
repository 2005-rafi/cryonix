import 'dart:async';
import 'package:flutter/material.dart';
import '../../theme/app_custom_colors.dart';

/// Error snackbar type for determining appearance and behavior
enum ErrorSnackBarType {
  /// User cancelled the operation (surfaceContainer/secondaryContainer)
  cancelled,

  /// Network or retry warning (tertiaryContainer)
  warning,

  /// Actual authentication failure (errorContainer)
  error,

  /// Success notification
  success,
}

/// Displays a floating Material 3 snackbar with smooth animations.
/// Auto-dismisses after 2-3 seconds.
class ErrorSnackBar {
  static OverlayEntry? _currentOverlay;

  /// Show a snackbar with the specified message and type.
  static void show(
    BuildContext context, {
    required String message,
    ErrorSnackBarType type = ErrorSnackBarType.error,
    Duration duration = const Duration(seconds: 3),
    String? actionLabel,
    VoidCallback? onActionPressed,
  }) {
    // Dismiss any currently showing snackbar immediately
    dismiss();

    final overlayState = Overlay.of(context);
    late OverlayEntry overlayEntry;

    overlayEntry = OverlayEntry(
      builder: (context) {
        return _CustomSnackBarNotification(
          message: message,
          type: type,
          duration: duration,
          actionLabel: actionLabel,
          onActionPressed: onActionPressed,
          onDismiss: () {
            if (_currentOverlay == overlayEntry) {
              _currentOverlay = null;
            }
            overlayEntry.remove();
          },
        );
      },
    );

    _currentOverlay = overlayEntry;
    overlayState.insert(overlayEntry);
  }

  /// Dismisses the currently active snackbar.
  static void dismiss() {
    if (_currentOverlay != null) {
      try {
        _currentOverlay!.remove();
      } catch (_) {}
      _currentOverlay = null;
    }
  }
}

class _CustomSnackBarNotification extends StatefulWidget {
  final String message;
  final ErrorSnackBarType type;
  final Duration duration;
  final String? actionLabel;
  final VoidCallback? onActionPressed;
  final VoidCallback onDismiss;

  const _CustomSnackBarNotification({
    required this.message,
    required this.type,
    required this.duration,
    this.actionLabel,
    this.onActionPressed,
    required this.onDismiss,
  });

  @override
  State<_CustomSnackBarNotification> createState() => _CustomSnackBarNotificationState();
}

class _CustomSnackBarNotificationState extends State<_CustomSnackBarNotification>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fadeAnimation;
  late final Animation<Offset> _slideAnimation;
  bool _isDismissing = false;
  Timer? _dismissTimer;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    );

    // Slide down slightly from top
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -0.25),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    ));

    _controller.forward();

    // Schedule auto-dismiss
    _dismissTimer = Timer(widget.duration, () {
      if (mounted) {
        _dismiss();
      }
    });
  }

  void _dismiss() {
    if (_isDismissing) return;
    setState(() {
      _isDismissing = true;
    });
    _controller.reverse().then((_) {
      if (mounted) {
        widget.onDismiss();
      }
    });
  }

  @override
  void dispose() {
    _dismissTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final customColors = Theme.of(context).extension<AppCustomColors>();
    final presentColor = customColors?.presentColor ?? cs.primary;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Determine container color based on type
    final containerColor = switch (widget.type) {
      ErrorSnackBarType.cancelled => cs.surfaceContainer,
      ErrorSnackBarType.warning => cs.tertiaryContainer,
      ErrorSnackBarType.error => cs.errorContainer,
      ErrorSnackBarType.success => presentColor.withAlpha(isDark ? 35 : 30),
    };

    // Determine text/icon color
    final textColor = switch (widget.type) {
      ErrorSnackBarType.cancelled => cs.onSurface,
      ErrorSnackBarType.warning => cs.onTertiaryContainer,
      ErrorSnackBarType.error => cs.onErrorContainer,
      ErrorSnackBarType.success => presentColor,
    };

    final icon = switch (widget.type) {
      ErrorSnackBarType.cancelled => Icons.cancel_outlined,
      ErrorSnackBarType.warning => Icons.warning_amber_rounded,
      ErrorSnackBarType.error => Icons.error_outline_rounded,
      ErrorSnackBarType.success => Icons.check_circle_outline_rounded,
    };

    return SafeArea(
      child: Align(
        alignment: Alignment.topCenter,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: SlideTransition(
              position: _slideAnimation,
              child: Material(
                color: Colors.transparent,
                child: GestureDetector(
                  onTap: _dismiss,
                  child: Container(
                    decoration: BoxDecoration(
                      color: containerColor,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: const Color.fromRGBO(0, 0, 0, 0.08),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                        BoxShadow(
                          color: const Color.fromRGBO(0, 0, 0, 0.04),
                          blurRadius: 4,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(icon, color: textColor, size: 20),
                        const SizedBox(width: 12),
                        Flexible(
                          child: Text(
                            widget.message,
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: textColor,
                                  fontWeight: FontWeight.w500,
                                ),
                          ),
                        ),
                        if (widget.actionLabel != null && widget.onActionPressed != null) ...[
                          const SizedBox(width: 12),
                          TextButton(
                            onPressed: () {
                              widget.onActionPressed!();
                              _dismiss();
                            },
                            style: TextButton.styleFrom(
                              foregroundColor: textColor,
                              padding: const EdgeInsets.symmetric(horizontal: 8),
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            child: Text(
                              widget.actionLabel!,
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
