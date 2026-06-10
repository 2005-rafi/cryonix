import 'package:flutter/material.dart';

import '../../core/constants/ui_constants.dart';

/// True when the platform accessibility setting requests reduced motion.
bool isReduceMotion(BuildContext context) =>
    MediaQuery.disableAnimationsOf(context);

/// Returns [Duration.zero] when reduced motion is enabled.
Duration motionDuration(BuildContext context, Duration duration) =>
    isReduceMotion(context) ? Duration.zero : duration;

/// Slide/scale animations should be skipped; opacity fades may still run.
Duration motionSlideScaleDuration(BuildContext context) =>
    motionDuration(context, kAnimSlow);

/// Standard UI animation duration respecting reduced motion.
Duration motionNormalDuration(BuildContext context) =>
    motionDuration(context, kAnimNormal);
