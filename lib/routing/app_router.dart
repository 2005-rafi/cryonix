import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../features/auth/screens/splash_screen.dart';
import 'package:cryonix/features/auth/providers.dart';
import 'auth_redirect.dart';
import '../features/classroom/screens/home_screen.dart';
import '../features/classroom/screens/classroom_detail_screen.dart';
import '../features/attendance/screens/attendance_screen.dart';
import '../features/attendance/models/attendance_route_args.dart';
import '../features/attendance/screens/session_detail_screen.dart';
import '../features/attendance/screens/edit_session_screen.dart';
import '../features/attendance/screens/attendance_overview_screen.dart';
import '../features/profile/screens/settings_screen.dart';
import '../features/navigation/scaffold_with_nav_bar.dart';
import '../shared/animations/page_transition.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  GoRouter — single authoritative gate for email-verification (Phase 2).
//
//  Redirect matrix:
//  ┌───────────────────────────┬──────────────────┬────────────────────────┐
//  │ authState                 │ current path     │ redirect               │
//  ├───────────────────────────┼──────────────────┼────────────────────────┤
//  │ unauthenticated           │ not /auth        │ /auth                  │
//  │ authenticatedUnverified   │ not /verify-email│ /verify-email          │
//  │ authenticatedVerified     │ /auth or /verify │ /home                  │
//  │ any loading               │ any              │ null (stay)            │
//  └───────────────────────────┴──────────────────┴────────────────────────┘
// ─────────────────────────────────────────────────────────────────────────────

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);

  return GoRouter(
    initialLocation: '/splash',
    redirect: (context, state) => resolveAuthRedirect(
      authLoading: authState.isLoading,
      verification: authState.value,
      currentPath: state.uri.path,
    ),
    routes: [
      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashScreen(),
      ),
      ShellRoute(
        builder: (context, state, child) {
          return ScaffoldWithNavBar(child: child);
        },
        routes: [
          GoRoute(
            path: '/home',
            pageBuilder: (context, state) {
              if (isSplashOriginTransition(state)) {
                return cryonixFadeTransitionPage(
                  state: state,
                  child: const HomeScreen(),
                );
              }
              return NoTransitionPage<void>(
                key: state.pageKey,
                child: const HomeScreen(),
              );
            },
          ),
          GoRoute(
            path: '/attendance-overview',
            pageBuilder: (context, state) => cryonixTransitionPage(
              state: state,
              child: const AttendanceOverviewScreen(),
            ),
          ),
          GoRoute(
            path: '/settings',
            pageBuilder: (context, state) => cryonixTransitionPage(
              state: state,
              child: const SettingsScreen(),
            ),
          ),
        ],
      ),
      GoRoute(
        path: '/classroom/:classroomId',
        pageBuilder: (context, state) {
          final classroomId = state.pathParameters['classroomId']!;
          return cryonixTransitionPage(
            state: state,
            child: ClassroomDetailScreen(classroomId: classroomId),
          );
        },
      ),
      GoRoute(
        path: '/attendance/:classroomId',
        pageBuilder: (context, state) {
          final classroomId = state.pathParameters['classroomId']!;
          final routeArgs = state.extra is AttendanceRouteArgs
              ? state.extra as AttendanceRouteArgs
              : null;
          return cryonixTransitionPage(
            state: state,
            child: AttendanceScreen(
              classroomId: classroomId,
              routeArgs: routeArgs,
            ),
          );
        },
      ),
      GoRoute(
        path: '/session/:sessionId',
        pageBuilder: (context, state) {
          final sessionId = state.pathParameters['sessionId']!;
          return cryonixTransitionPage(
            state: state,
            child: SessionDetailScreen(sessionId: sessionId),
          );
        },
      ),
      GoRoute(
        path: '/edit-session/:classroomId/:sessionId',
        pageBuilder: (context, state) {
          final classroomId = state.pathParameters['classroomId']!;
          final sessionId = state.pathParameters['sessionId']!;
          return cryonixTransitionPage(
            state: state,
            child: EditSessionScreen(classroomId: classroomId, sessionId: sessionId),
          );
        },
      ),
    ],
  );
});
