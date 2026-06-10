import 'package:flutter/material.dart';

/// Shared scaffold for all detail / edit screens.
///
/// Principles (from navigation hardening plan):
///  • R1: GoRouter owns the back stack — use [context.pop()] not [context.go()].
///  • R4: No [onPopRoute] parameter. GoRouter knows where to go.
///
/// Each screen that uses [CryonixScaffold] is responsible for its own
/// back-navigation strategy (PopScope if needed). This widget does NOT
/// add any PopScope — that is each screen's responsibility.
class CryonixScaffold extends StatelessWidget {
  const CryonixScaffold({
    super.key,
    this.appBar,
    this.customHeaderBuilder,
    required this.body,
    this.floatingActionButton,
    this.floatingActionButtonLocation,
    this.bottomNavigationBar,
    this.backgroundColor,
    this.resizeToAvoidBottomInset,
    this.extendBodyBehindAppBar = false,
  });

  final PreferredSizeWidget? appBar;
  final WidgetBuilder? customHeaderBuilder;
  final Widget body;
  final Widget? floatingActionButton;
  final FloatingActionButtonLocation? floatingActionButtonLocation;
  final Widget? bottomNavigationBar;
  final Color? backgroundColor;
  final bool? resizeToAvoidBottomInset;
  final bool extendBodyBehindAppBar;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: customHeaderBuilder != null
          ? PreferredSize(
              preferredSize: const Size.fromHeight(kToolbarHeight),
              child: customHeaderBuilder!(context),
            )
          : appBar,
      body: body,
      floatingActionButton: floatingActionButton,
      floatingActionButtonLocation: floatingActionButtonLocation,
      bottomNavigationBar: bottomNavigationBar,
      backgroundColor: backgroundColor,
      resizeToAvoidBottomInset: resizeToAvoidBottomInset,
      extendBodyBehindAppBar: extendBodyBehindAppBar,
    );
  }
}
