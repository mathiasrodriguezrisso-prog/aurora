/// 📁 lib/core/config/app_router.dart
/// Configuración central de navegación mediante GoRouter.
/// Alineado con la verificación final de la Fase 6.
library;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Screens
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/register_screen.dart';
import '../../features/auth/presentation/screens/splash_screen.dart';
import '../../features/onboarding/presentation/screens/onboarding_screen.dart';
import '../../features/onboarding/presentation/screens/grow_setup_wizard.dart';
import '../../features/dashboard/presentation/screens/home_screen.dart';
import '../../features/grow/presentation/screens/grow_active_screen.dart';
import '../../features/climate/presentation/screens/climate_screen.dart';
import '../../features/social/presentation/screens/feed_screen.dart';
import '../../features/social/presentation/screens/create_post_screen.dart';
import '../../features/social/presentation/screens/post_detail_screen.dart';
import '../../features/profile/presentation/screens/profile_screen.dart';
import '../../features/profile/presentation/screens/edit_profile_screen.dart';
import '../../features/profile/presentation/screens/settings_screen.dart';
import '../../features/social/presentation/screens/public_profile_screen.dart';
import '../../features/notifications/presentation/screens/notification_screen.dart';
import '../../features/chat/presentation/screens/chat_screen.dart';

// Core
import '../presentation/screens/main_scaffold.dart';
import '../presentation/screens/error_screen.dart';
import '../../features/auth/presentation/providers/auth_providers.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _shellHomeKey = GlobalKey<NavigatorState>(debugLabel: 'shellHome');
final _shellGrowKey = GlobalKey<NavigatorState>(debugLabel: 'shellGrow');
final _shellFeedKey = GlobalKey<NavigatorState>(debugLabel: 'shellFeed');
final _shellProfileKey = GlobalKey<NavigatorState>(debugLabel: 'shellProfile');

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authProvider);

  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/splash',
    debugLogDiagnostics: true,
    
    redirect: (context, state) {
      final isSplash = state.matchedLocation == '/splash';
      final isAuth = state.matchedLocation == '/login' || state.matchedLocation == '/register';
      final isOnboarding = state.matchedLocation == '/onboarding';

      return authState.when(
        initial: () => isSplash ? null : '/splash',
        loading: () => isSplash ? null : '/splash',
        unauthenticated: () => (isAuth || isSplash || isOnboarding) ? null : '/login',
        authenticated: (user) {
          if (isAuth || isSplash) return '/home';
          return null;
        },
        error: (_) => isAuth ? null : '/login',
      );
    },

    routes: [
      // ── AUTENTICACIÓN ─────────────────────────────────────────────
      GoRoute(path: '/splash', builder: (context, state) => const SplashScreen()),
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      GoRoute(path: '/register', builder: (context, state) => const RegisterScreen()),
      GoRoute(path: '/onboarding', builder: (context, state) => const OnboardingScreen()),
      GoRoute(path: '/grow-setup', builder: (context, state) => const GrowSetupWizard()),

      // ── MAIN SHELL (TABS) ────────────────────────────────────────
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return MainScaffold(navigationShell: navigationShell);
        },
        branches: [
          StatefulShellBranch(
            navigatorKey: _shellHomeKey,
            routes: [
              GoRoute(path: '/home', builder: (context, state) => const HomeScreen()),
            ],
          ),
          StatefulShellBranch(
            navigatorKey: _shellGrowKey,
            routes: [
              GoRoute(path: '/grow', builder: (context, state) => const GrowActiveScreen()),
            ],
          ),
          StatefulShellBranch(
            navigatorKey: _shellFeedKey,
            routes: [
              GoRoute(path: '/feed', builder: (context, state) => const FeedScreen()),
            ],
          ),
          StatefulShellBranch(
            navigatorKey: _shellProfileKey,
            routes: [
              GoRoute(path: '/profile', builder: (context, state) => const ProfileScreen()),
            ],
          ),
        ],
      ),

      // ── TOP-LEVEL ROUTES ──────────────────────────────────────────
      
      // Climate top-level
      GoRoute(
        path: '/climate',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const ClimateScreen(),
      ),

      // Chat top-level
      GoRoute(
        path: '/chat',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const ChatScreen(),
      ),

      // Feed Creation & Detail
      GoRoute(
        path: '/feed/create',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const CreatePostScreen(),
      ),
      GoRoute(
        path: '/feed/post/:id',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return PostDetailScreen(postId: id);
        },
      ),

      // Profile Detail, Edit & Settings
      GoRoute(
        path: '/profile/:userId',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final userId = state.pathParameters['userId']!;
          return UserProfileScreen(userId: userId);
        },
      ),
      GoRoute(
        path: '/profile/edit',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const EditProfileScreen(),
      ),
      GoRoute(
        path: '/settings',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const SettingsScreen(),
      ),
      GoRoute(
        path: '/notifications',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const NotificationsScreen(),
      ),
    ],
    
    errorBuilder: (context, state) => ErrorScreen(error: state.error),
  );
});
