import 'package:cryonix/core/constants/ui_constants.dart';
import 'package:cryonix/core/providers.dart';
import 'package:cryonix/core/startup_notifier.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with TickerProviderStateMixin {
  late final AnimationController _iconController;
  late final AnimationController _titleController;
  late final AnimationController _subtitleController;
  late final AnimationController _exitController;

  late final Animation<double> _iconFade;
  late final Animation<double> _iconScale;
  late final Animation<Offset> _iconSlide;
  late final Animation<double> _titleFade;
  late final Animation<Offset> _titleSlide;
  late final Animation<double> _subtitleFade;
  late final Animation<Offset> _subtitleSlide;
  late final Animation<double> _exitFade;

  AuthVerificationState? _pendingRoute;
  bool _exitStarted = false;
  bool _routingSequenceActive = false;

  @override
  void initState() {
    super.initState();
    _iconController = AnimationController(vsync: this, duration: kAnimEntrance);
    _titleController = AnimationController(
      vsync: this,
      duration: kAnimEntrance,
    );
    _subtitleController = AnimationController(
      vsync: this,
      duration: kAnimEntrance,
    );
    _exitController = AnimationController(
      vsync: this,
      duration: kAnimSplashExit,
    );

    final iconCurve = CurvedAnimation(
      parent: _iconController,
      curve: kCurveEnter,
    );
    _iconFade = Tween<double>(begin: 0, end: 1).animate(iconCurve);
    _iconScale = Tween<double>(begin: 0.9, end: 1).animate(iconCurve);
    _iconSlide = Tween<Offset>(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(iconCurve);

    final titleCurve = CurvedAnimation(
      parent: _titleController,
      curve: kCurveEnter,
    );
    _titleFade = Tween<double>(begin: 0, end: 1).animate(titleCurve);
    _titleSlide = Tween<Offset>(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(titleCurve);

    final subtitleCurve = CurvedAnimation(
      parent: _subtitleController,
      curve: kCurveEnter,
    );
    _subtitleFade = Tween<double>(begin: 0, end: 1).animate(subtitleCurve);
    _subtitleSlide = Tween<Offset>(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(subtitleCurve);

    _exitFade = Tween<double>(
      begin: 1,
      end: 0,
    ).animate(CurvedAnimation(parent: _exitController, curve: kCurveExit));
    _exitController.addStatusListener(_onExitStatus);

    _iconController.forward();
    Future<void>.delayed(kSplashTitleDelay, () {
      if (mounted) _titleController.forward();
    });
    Future<void>.delayed(kSplashSubtitleDelay, () {
      if (mounted) _subtitleController.forward();
    });
  }

  void _onExitStatus(AnimationStatus status) {
    if (status != AnimationStatus.completed || _pendingRoute == null) return;
    if (!mounted) return;
    switch (_pendingRoute!) {
      case AuthVerificationState.authenticatedVerified:
        context.go('/home', extra: true);
        break;
      case AuthVerificationState.authenticatedUnverified:
        context.go('/verify-email', extra: true);
        break;
      case AuthVerificationState.unauthenticated:
        context.go('/auth', extra: true);
        break;
    }
  }

  @override
  void dispose() {
    _iconController.dispose();
    _titleController.dispose();
    _subtitleController.dispose();
    _exitController.removeStatusListener(_onExitStatus);
    _exitController.dispose();
    super.dispose();
  }

  void _navigateWhenReady(AuthVerificationState route) {
    if (_exitStarted) return;
    _exitStarted = true;
    _pendingRoute = route;
    _exitController.forward();
  }

  Widget _animatedBlock({
    required Animation<double> fade,
    required Animation<Offset> slide,
    required Widget child,
  }) {
    return FadeTransition(
      opacity: fade,
      child: SlideTransition(position: slide, child: child),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    final startupState = ref.watch(startupProvider);

    // Reset routing trigger if the startup state changes away from ready (e.g. on Retry)
    if (startupState.status != StartupStatus.ready) {
      _routingSequenceActive = false;
    }

    // Watch for readiness to transition routes
    ref.listen<StartupState>(startupProvider, (previous, current) async {
      if (current.status == StartupStatus.ready && !_routingSequenceActive) {
        _routingSequenceActive = true;
        await ref.read(themeNotifierProvider.notifier).loadTheme();
        if (!mounted) return;
        try {
          final route = await ref.read(authStateProvider.future);
          if (mounted) {
            _navigateWhenReady(route);
          }
        } catch (_) {
          if (mounted) {
            _navigateWhenReady(AuthVerificationState.unauthenticated);
          }
        }
      }
    });

    // Check if ready upon initial build
    if (startupState.status == StartupStatus.ready && !_routingSequenceActive) {
      _routingSequenceActive = true;
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        await ref.read(themeNotifierProvider.notifier).loadTheme();
        if (!mounted) return;
        try {
          final route = await ref.read(authStateProvider.future);
          if (mounted) {
            _navigateWhenReady(route);
          }
        } catch (_) {
          if (mounted) {
            _navigateWhenReady(AuthVerificationState.unauthenticated);
          }
        }
      });
    }

    if (startupState.status == StartupStatus.error) {
      return Scaffold(
        backgroundColor: cs.surfaceContainerLow,
        body: Center(
          child: FadeTransition(
            opacity: _exitFade,
            child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: cs.errorContainer,
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Icon(
                      Icons.warning_amber_rounded,
                      size: 44,
                      color: cs.onErrorContainer,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Startup Initialization Failed',
                    style: tt.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: cs.onSurface,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  if (startupState.failedTaskName != null) ...[
                    Text(
                      'Failed task: ${startupState.failedTaskName}',
                      style: tt.bodyMedium?.copyWith(
                        color: cs.onSurfaceVariant,
                        fontWeight: FontWeight.w600,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                  ],
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: cs.surfaceContainerHigh,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      startupState.errorMessage ?? 'An unknown error occurred.',
                      style: tt.bodySmall?.copyWith(
                        color: cs.error,
                        fontFamily: 'monospace',
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 32),
                  FilledButton.icon(
                    onPressed: () {
                      ref.read(startupProvider.notifier).retry();
                    },
                    icon: const Icon(Icons.refresh_rounded),
                    label: const Text('Retry Setup'),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: cs.surfaceContainerLow,
      body: Center(
        child: FadeTransition(
          opacity: _exitFade,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              FadeTransition(
                opacity: _iconFade,
                child: SlideTransition(
                  position: _iconSlide,
                  child: ScaleTransition(
                    scale: _iconScale,
                    child: Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: cs.primaryContainer,
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: Icon(
                        Icons.school_rounded,
                        size: 44,
                        color: cs.onPrimaryContainer,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              _animatedBlock(
                fade: _titleFade,
                slide: _titleSlide,
                child: Text(
                  'Cryonix',
                  style: tt.headlineLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: cs.onSurface,
                    letterSpacing: -0.5,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              _animatedBlock(
                fade: _subtitleFade,
                slide: _subtitleSlide,
                child: Text(
                  'Attendance Management',
                  style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
                ),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: 200,
                height: 4,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(2),
                  child: LinearProgressIndicator(
                    value: startupState.progressPercent,
                    backgroundColor: cs.surfaceContainerHighest,
                    color: cs.primary,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 20,
                child: Text(
                  startupState.currentTaskName ?? 'Starting setup...',
                  style: tt.bodySmall?.copyWith(
                    color: cs.onSurfaceVariant,
                    letterSpacing: 0.2,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
