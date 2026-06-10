import 'package:flutter/material.dart';

/// Wraps any input widget with the spacious padding and minimum touch target
/// specified in the UI/UX technical documentation.
class SpaciousFormField extends StatelessWidget {
  const SpaciousFormField({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
    child: ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 48),
      child: child,
    ),
  );
}
