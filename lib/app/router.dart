import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../features/auth/screens/auth_gate.dart';
import '../features/auth/screens/login_screen.dart';
import '../features/manager/screens/manager_main_screen.dart';
import '../features/manager/screens/category_measure_screen.dart';
import '../features/manager/screens/end_session_preview_screen.dart';
import '../features/owner/screens/owner_main_screen.dart';
import '../features/owner/screens/report_detail_screen.dart';
import '../features/guest/screens/welcome_screen.dart';
import '../features/guest/screens/guest_main_screen.dart';
import '../features/guest/screens/guest_result_screen.dart';
import '../features/guest/screens/guest_end_session_screen.dart';
import '../features/guest/models/guest_session_model.dart';
import '../models/measurement_model.dart';
import '../models/performance_report_model.dart';
import '../models/performance_session_model.dart';

final GlobalKey<NavigatorState> rootNavigatorKey =
    GlobalKey<NavigatorState>(debugLabel: 'root');

class AppRoutes {
  AppRoutes._();
  static const String home = '/';
  static const String welcome = '/welcome';
  static const String login = '/login';
  static const String manager = '/manager';
  static const String owner = '/owner';
  static const String category = '/category';
  static const String preview = '/preview';
  static const String reportDetail = '/report-detail';
  // Guest routes
  static const String guest = '/guest';
  static const String guestEndSession = '/guest-end-session';
  static const String guestResult = '/guest-result';
}

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: AppRoutes.home,
    debugLogDiagnostics: false,
    routes: [
      // Welcome is now the entry point
      GoRoute(
        path: AppRoutes.welcome,
        name: 'welcome',
        builder: (context, state) => const WelcomeScreen(),
      ),
      // Legacy home route → AuthGate (for deep links / internal redirects)
      GoRoute(
        path: AppRoutes.home,
        name: 'home',
        builder: (context, state) => const AuthGate(),
      ),
      GoRoute(
        path: AppRoutes.login,
        name: 'login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: AppRoutes.manager,
        name: 'manager',
        builder: (context, state) => const ManagerMainScreen(),
      ),
      GoRoute(
        path: AppRoutes.owner,
        name: 'owner',
        builder: (context, state) => const OwnerMainScreen(),
      ),
      GoRoute(
        path: AppRoutes.category,
        name: 'category',
        builder: (context, state) {
          final category = state.extra as PerformanceCategory? ?? PerformanceCategory.drink;
          return CategoryMeasureScreen(category: category);
        },
      ),
      GoRoute(
        path: AppRoutes.preview,
        name: 'preview',
        builder: (context, state) {
          final session = state.extra as PerformanceSessionModel;
          return EndSessionPreviewScreen(session: session);
        },
      ),
      GoRoute(
        path: AppRoutes.reportDetail,
        name: 'report-detail',
        builder: (context, state) {
          final report = state.extra as PerformanceReportModel;
          return ReportDetailScreen(report: report);
        },
      ),
      // Guest routes
      GoRoute(
        path: AppRoutes.guest,
        name: 'guest',
        builder: (context, state) => const GuestMainScreen(),
      ),
      GoRoute(
        path: AppRoutes.guestEndSession,
        name: 'guest-end-session',
        builder: (context, state) => const GuestEndSessionScreen(),
      ),
      GoRoute(
        path: AppRoutes.guestResult,
        name: 'guest-result',
        builder: (context, state) {
          final session = state.extra as GuestSessionModel;
          return GuestResultScreen(session: session);
        },
      ),
    ],
  );
});
