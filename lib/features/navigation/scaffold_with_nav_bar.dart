import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

/// Shell host widget that wraps all bottom-nav-bar tab screens.
///
/// Back-navigation strategy (R2 from the hardening plan):
///  • Shell always intercepts the Android/iOS back gesture.
///  • Shows "Exit Cryonix?" confirmation dialog.
///  • Only exits via [SystemNavigator.pop()] when the user confirms.
///  • Never redirects to a specific tab — stays on the current tab.
class ScaffoldWithNavBar extends StatefulWidget {
  final Widget child;

  const ScaffoldWithNavBar({super.key, required this.child});

  @override
  State<ScaffoldWithNavBar> createState() => _ScaffoldWithNavBarState();
}

class _ScaffoldWithNavBarState extends State<ScaffoldWithNavBar>
    with WidgetsBindingObserver {

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  // WidgetsBindingObserver intercepts the back button at the OS level.
  // This fires BEFORE GoRouter can process the back event, making it
  // reliable for GoRouter 14 + Flutter 3.41 ShellRoute setups.
  @override
  Future<bool> didPopRoute() async {
    // Only handle the back button when this shell is the active surface
    // (i.e. no detail screen is pushed on top of the root navigator).
    final router = GoRouter.of(context);

    // If GoRouter's root navigator can pop (detail screen is on top),
    // let GoRouter handle it — return false to allow normal back handling.
    if (router.canPop()) {
      return false;
    }

    // We are at the shell root — show the quit confirmation dialog.
    if (!mounted) return true;
    final shouldQuit = await _showQuitConfirmationDialog();
    if (shouldQuit == true && mounted) {
      await SystemNavigator.pop();
    }
    // Return true to tell Flutter we handled the back event (suppress exit).
    return true;
  }

  Future<bool?> _showQuitConfirmationDialog() {
    return showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => AlertDialog(
        title: const Text('Exit Cryonix?'),
        content: const Text('Your attendance records are safe and synced.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Stay'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Exit'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // PopScope(canPop: false) as a belt-and-suspenders defence inside the
    // widget tree in addition to the WidgetsBindingObserver above.
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        if (!mounted) return;
        final shouldQuit = await _showQuitConfirmationDialog();
        if (shouldQuit == true && mounted) {
          await SystemNavigator.pop();
        }
      },
      child: Scaffold(
        body: widget.child,
        bottomNavigationBar: NavigationBar(
          selectedIndex: _calculateSelectedIndex(context),
          onDestinationSelected: (idx) => _onItemTapped(idx, context),
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.class_outlined),
              selectedIcon: Icon(Icons.class_),
              label: 'Classes',
            ),
            NavigationDestination(
              icon: Icon(Icons.check_circle_outline),
              selectedIcon: Icon(Icons.check_circle),
              label: 'Attendance',
            ),
            NavigationDestination(
              icon: Icon(Icons.settings_outlined),
              selectedIcon: Icon(Icons.settings),
              label: 'Settings',
            ),
          ],
        ),
      ),
    );
  }

  static int _calculateSelectedIndex(BuildContext context) {
    final String location = GoRouterState.of(context).uri.path;
    if (location.startsWith('/home')) return 0;
    if (location.startsWith('/attendance-overview')) return 1;
    if (location.startsWith('/settings')) return 2;
    return 0;
  }

  void _onItemTapped(int index, BuildContext context) {
    switch (index) {
      case 0:
        context.go('/home');
        break;
      case 1:
        context.go('/attendance-overview');
        break;
      case 2:
        context.go('/settings');
        break;
    }
  }
}
