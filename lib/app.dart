import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sse_frontend_mobil/config/app_theme.dart';
import 'package:sse_frontend_mobil/providers/auth_provider.dart';
import 'package:sse_frontend_mobil/screens/admin/manage_users_screen.dart';
import 'package:sse_frontend_mobil/screens/change_password_screen.dart';
import 'package:sse_frontend_mobil/screens/home_screen.dart';
import 'package:sse_frontend_mobil/screens/login_screen.dart';
import 'package:sse_frontend_mobil/screens/process_detail_screen.dart';
import 'package:sse_frontend_mobil/screens/process_list_screen.dart';
import 'package:sse_frontend_mobil/screens/notifications_screen.dart';
import 'package:sse_frontend_mobil/screens/record_step_screen.dart';
import 'package:sse_frontend_mobil/screens/create_process_screen.dart';
import 'package:sse_frontend_mobil/screens/metrics_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authProvider);

  return GoRouter(
    initialLocation: '/login',
    redirect: (context, state) {
      final isLoggedIn = authState.isAuthenticated;
      final isLoginRoute = state.matchedLocation == '/login';

      if (!isLoggedIn && !isLoginRoute) return '/login';
      if (isLoggedIn && isLoginRoute) return '/home';
      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/change-password',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>;
          return ChangePasswordScreen(
            username: extra['username'] as String,
            session: extra['session'] as String,
          );
        },
      ),
      GoRoute(
        path: '/home',
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        path: '/processes',
        builder: (context, state) => const ProcessListScreen(),
      ),
      GoRoute(
        path: '/admin/users',
        builder: (context, state) => const ManageUsersScreen(),
      ),
      GoRoute(
        path: '/process/:id',
        builder: (context, state) => ProcessDetailScreen(
          processId: state.pathParameters['id']!,
        ),
      ),
      GoRoute(
        path: '/process/:processId/step/:stepId',
        builder: (context, state) => RecordStepScreen(
          processId: state.pathParameters['processId']!,
          stepId: state.pathParameters['stepId']!,
        ),
      ),
      GoRoute(
        path: '/notifications',
        builder: (context, state) => const NotificationsScreen(),
      ),
      GoRoute(
        path: '/create-process',
        builder: (context, state) => const CreateProcessScreen(),
      ),
      GoRoute(
        path: '/metrics',
        builder: (context, state) => const MetricsScreen(),
      ),
    ],
  );
});

class App extends ConsumerWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'SSE Movil',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.themeData,
      routerConfig: router,
    );
  }
}
