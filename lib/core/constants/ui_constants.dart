import 'package:flutter/material.dart';

/// UI-related constants: spacing, radius, elevation, layout metrics.
class AppSpacing {
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 16.0;
  static const double lg = 24.0;
  static const double xl = 32.0;
}

class AppRadius {
  static const BorderRadius sm = BorderRadius.all(Radius.circular(8));
  static const BorderRadius md = BorderRadius.all(Radius.circular(12));
  static const BorderRadius lg = BorderRadius.all(Radius.circular(16));
}

class AppElevation {
  static const double flat = 0.0;
  static const double low = 1.0;
  static const double medium = 3.0;
}

class AppLayout {
  static const double minButtonHeight = 48.0;
}

// ── Animation durations ─────────────────────────────────────────────────────
// Use these named values in animation code — no raw millisecond literals.

/// Micro-interactions: button press, chip color, toggle (feels instant).
const Duration kAnimFast = Duration(milliseconds: 150);

/// UI catching up to user action: validation, tab indicator, card enter.
const Duration kAnimNormal = Duration(milliseconds: 250);

/// Screen-level: bottom sheets, layout shifts, page transitions.
const Duration kAnimSlow = Duration(milliseconds: 350);

/// First render / staggered list entrance (once per screen visit).
const Duration kAnimEntrance = Duration(milliseconds: 400);

/// Splash content fade-out before routing to the next screen.
const Duration kAnimSplashExit = Duration(milliseconds: 200);

/// Splash stagger: title after icon, subtitle after title.
const Duration kSplashTitleDelay = Duration(milliseconds: 100);
const Duration kSplashSubtitleDelay = Duration(milliseconds: 180);

/// Form field horizontal shake on validation failure.
const Duration kShakeDuration = Duration(milliseconds: 300);
const double kShakeOffset = 6.0;

// ── Animation curves ────────────────────────────────────────────────────────

/// Default — gentle start and end.
const Curve kCurveStandard = Curves.easeInOut;

/// Elements entering the screen — decelerate into place.
const Curve kCurveEnter = Curves.easeOut;

/// Elements leaving the screen — accelerate away.
const Curve kCurveExit = Curves.easeIn;

/// Success / confirmation — subtle elastic, not theatrical.
const Curve kCurveSpring = _LowAmplitudeElasticCurve();

/// Blends [Curves.elasticOut] toward linear to keep bounce subtle.
class _LowAmplitudeElasticCurve extends Curve {
  const _LowAmplitudeElasticCurve();

  @override
  double transformInternal(double t) {
    final elastic = Curves.elasticOut.transform(t);
    return t + (elastic - t) * 0.35;
  }
}

/// Per-item stagger step for list entrance animations.
const Duration kStaggerItemStep = Duration(milliseconds: 40);

/// Maximum stagger delay for any list item index.
const Duration kStaggerMaxDelay = Duration(milliseconds: 200);

/// Vertical slide offset for staggered list items (subtle settle-in).
const double kStaggerSlideOffset = 12.0;

/// Horizontal slide fraction for page transitions (8% from the right).
const double kPageTransitionSlideFraction = 0.08;
