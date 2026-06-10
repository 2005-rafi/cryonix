import 'package:flutter/material.dart';

/// Semantic attendance and sync colors for Cryonix.
@immutable
class AppCustomColors extends ThemeExtension<AppCustomColors> {
  const AppCustomColors({
    required this.presentColor,
    required this.absentColor,
    required this.onDutyColor,
    required this.syncedColor,
    required this.unsyncedColor,
    required this.failedSyncColor,
  });

  final Color presentColor;
  final Color absentColor;
  final Color onDutyColor;
  final Color syncedColor;
  final Color unsyncedColor;
  final Color failedSyncColor;

  static const light = AppCustomColors(
    presentColor: Color(0xFF2E7D32),
    absentColor: Color(0xFFC62828),
    onDutyColor: Color(0xFFF9A825),
    syncedColor: Color(0xFF388E3C),
    unsyncedColor: Color(0xFF757575),
    failedSyncColor: Color(0xFFD32F2F),
  );

  static const dark = AppCustomColors(
    presentColor: Color(0xFF81C784),
    absentColor: Color(0xFFEF9A9A),
    onDutyColor: Color(0xFFFFD54F),
    syncedColor: Color(0xFFA5D6A7),
    unsyncedColor: Color(0xFFBDBDBD),
    failedSyncColor: Color(0xFFEF5350),
  );

  @override
  AppCustomColors copyWith({
    Color? presentColor,
    Color? absentColor,
    Color? onDutyColor,
    Color? syncedColor,
    Color? unsyncedColor,
    Color? failedSyncColor,
  }) {
    return AppCustomColors(
      presentColor: presentColor ?? this.presentColor,
      absentColor: absentColor ?? this.absentColor,
      onDutyColor: onDutyColor ?? this.onDutyColor,
      syncedColor: syncedColor ?? this.syncedColor,
      unsyncedColor: unsyncedColor ?? this.unsyncedColor,
      failedSyncColor: failedSyncColor ?? this.failedSyncColor,
    );
  }

  @override
  AppCustomColors lerp(ThemeExtension<AppCustomColors>? other, double t) {
    if (other is! AppCustomColors) return this;
    return AppCustomColors(
      presentColor: Color.lerp(presentColor, other.presentColor, t)!,
      absentColor: Color.lerp(absentColor, other.absentColor, t)!,
      onDutyColor: Color.lerp(onDutyColor, other.onDutyColor, t)!,
      syncedColor: Color.lerp(syncedColor, other.syncedColor, t)!,
      unsyncedColor: Color.lerp(unsyncedColor, other.unsyncedColor, t)!,
      failedSyncColor: Color.lerp(failedSyncColor, other.failedSyncColor, t)!,
    );
  }
}
