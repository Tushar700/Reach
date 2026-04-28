import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../features/auth/screens/splash_screen.dart';
import '../../features/auth/screens/login_screen.dart';
import '../../features/auth/screens/signup_screen.dart';
import '../../features/onboarding/screens/onboarding_screen.dart';
import '../../features/dashboard/screens/dashboard_screen.dart';
import '../../features/mentor/screens/mentor_chat_screen.dart';
import '../../features/tasks/screens/tasks_screen.dart';
import '../../features/habits/screens/habits_screen.dart';
import '../../features/mood/screens/mood_screen.dart';
import '../../features/analytics/screens/analytics_screen.dart';
import '../../features/calendar/screens/calendar_screen.dart';
import '../../features/profile/screens/profile_screen.dart';
import '../../features/focus/screens/focus_screen.dart';

class AppRoutes {
  static const splash = '/';
  static const onboarding = '/onboarding';
  static const login = '/login';
  static const signup = '/signup';
  static const dashboard = '/dashboard';
  static const mentor = '/mentor';
  static const tasks = '/tasks';
  static const habits = '/habits';
  static const mood = '/mood';
  static const analytics = '/analytics';
  static const calendar = '/calendar';
  static const profile = '/profile';
  static const focus = '/focus';
}

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: AppRoutes.splash,
    redirect: (context, state) {
      final session = Supabase.instance.client.auth.currentSession;
      final isAuth = session != null;
      final isOnAuthPage = [
        AppRoutes.login, AppRoutes.signup,
        AppRoutes.splash, AppRoutes.onboarding,
      ].contains(state.matchedLocation);
      if (!isAuth && !isOnAuthPage) return AppRoutes.login;
      return null;
    },
    routes: [
      GoRoute(path: AppRoutes.splash, builder: (_, __) => const SplashScreen()),
      GoRoute(path: AppRoutes.onboarding, builder: (_, __) => const OnboardingScreen()),
      GoRoute(path: AppRoutes.login, builder: (_, __) => const LoginScreen()),
      GoRoute(path: AppRoutes.signup, builder: (_, __) => const SignupScreen()),
      GoRoute(path: AppRoutes.dashboard, builder: (_, __) => const DashboardScreen()),
      GoRoute(path: AppRoutes.mentor, builder: (_, __) => const MentorChatScreen()),
      GoRoute(path: AppRoutes.tasks, builder: (_, __) => const TasksScreen()),
      GoRoute(path: AppRoutes.habits, builder: (_, __) => const HabitsScreen()),
      GoRoute(path: AppRoutes.mood, builder: (_, __) => const MoodScreen()),
      GoRoute(path: AppRoutes.analytics, builder: (_, __) => const AnalyticsScreen()),
      GoRoute(path: AppRoutes.calendar, builder: (_, __) => const CalendarScreen()),
      GoRoute(path: AppRoutes.profile, builder: (_, __) => const ProfileScreen()),
      GoRoute(path: AppRoutes.focus, builder: (_, __) => const FocusScreen()),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(child: Text('Page not found: ${state.error}')),
    ),
  );
});
