import 'package:flutter/material.dart';

/// A consistently-styled uppercase section label used across the app.
///
/// Extracted from `profile_screen.dart`'s private `_SectionHeader` so all
/// screens can share the same typographic treatment for section groupings.
///
/// Usage:
/// ```dart
/// AppSectionHeader(label: 'Overview'),
/// ```
class AppSectionHeader extends StatelessWidget {
  const AppSectionHeader({
    super.key,
    required this.label,
    this.trailing,
    this.topPadding = 4,
  });

  final String label;

  /// Optional widget placed at the trailing end of the header row (e.g. a
  /// "See all" button or a date picker icon).
  final Widget? trailing;

  /// Extra padding above the header. Default is 4.
  final double topPadding;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    final labelText = Text(
      label.toUpperCase(),
      style: tt.labelSmall?.copyWith(
        color: cs.onSurfaceVariant,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.8,
      ),
    );

    return Padding(
      padding: EdgeInsets.only(left: 4, top: topPadding, bottom: 0),
      child: trailing == null
          ? labelText
          : Row(
              children: [
                Expanded(child: labelText),
                trailing!,
              ],
            ),
    );
  }
}
