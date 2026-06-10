import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/ui_constants.dart';
import 'animation_motion.dart';

/// Slide + fade transition for forward navigation (8% from the right).
Widget cryonixTransitionBuilder(
  BuildContext context,
  Animation<double> animation,
  Animation<double> secondaryAnimation,
  Widget child,
) {
  if (isReduceMotion(context)) {
    return FadeTransition(
      opacity: CurvedAnimation(parent: animation, curve: kCurveEnter),
      child: child,
    );
  }

  final curved = CurvedAnimation(parent: animation, curve: kCurveEnter);

  return FadeTransition(
    opacity: Tween<double>(begin: 0, end: 1).animate(curved),
    child: SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(kPageTransitionSlideFraction, 0),
        end: Offset.zero,
      ).animate(curved),
      child: child,
    ),
  );
}

/// Fade-only transition for routes entered from the splash screen.
Widget cryonixFadeTransitionBuilder(
  BuildContext context,
  Animation<double> animation,
  Animation<double> secondaryAnimation,
  Widget child,
) {
  final curved = CurvedAnimation(parent: animation, curve: kCurveEnter);
  return FadeTransition(
    opacity: Tween<double>(begin: 0, end: 1).animate(curved),
    child: child,
  );
}

/// [CustomTransitionPage] using Cryonix motion language for GoRouter routes.
CustomTransitionPage<void> cryonixTransitionPage({
  required GoRouterState state,
  required Widget child,
}) {
  return CustomTransitionPage<void>(
    key: state.pageKey,
    child: child,
    transitionDuration: kAnimSlow,
    reverseTransitionDuration: kAnimSlow,
    transitionsBuilder: cryonixTransitionBuilder,
  );
}

/// Fade transition when navigating from splash (no horizontal slide).
CustomTransitionPage<void> cryonixFadeTransitionPage({
  required GoRouterState state,
  required Widget child,
}) {
  return CustomTransitionPage<void>(
    key: state.pageKey,
    child: child,
    transitionDuration: kAnimSlow,
    reverseTransitionDuration: kAnimSlow,
    transitionsBuilder: cryonixFadeTransitionBuilder,
  );
}

/// True when [GoRouterState.extra] marks navigation from splash.
bool isSplashOriginTransition(GoRouterState state) => state.extra == true;

CustomTransitionPage<void> cryonixAuthFlowPage({
  required GoRouterState state,
  required Widget child,
}) {
  if (isSplashOriginTransition(state)) {
    return cryonixFadeTransitionPage(state: state, child: child);
  }
  return cryonixTransitionPage(state: state, child: child);
}
