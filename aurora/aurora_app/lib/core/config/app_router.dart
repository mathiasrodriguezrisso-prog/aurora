
import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';

// Core
import '../presentation/screens/main_scaffold.dart';

// Auth
import '../../features/auth/presentation/screens/splash_screen.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/register_screen.dart';

// Onboarding
import '../../features/onboarding/presentation/screens/onboarding_screen.dart';

// Dashboard
import '../../features/dashboard/presentation/screens/home_screen.dart';

// Social
import '../../features/social/presentation/screens/feed_screen.dart';
import '../../features/social/presentation/screens/create_post_screen.dart';
import '../../features/social/presentation/screens/post_detail_screen.dart';
import '../../features/social/data/models/post_model.dart';

// Chat
import '../../features/chat/presentation/screens/chat_screen.dart';

// Profile
import '../../features/profile/presentation/screens/profile_screen.dart';
import '../../features/profile/presentation/screens/edit_profile_screen.dart';
import '../../features/profile/presentation/screens/settings_screen.dart';
import '../../features/profile/presentation/screens/public_profile_screen.dart';

// Grow
import '../../features/grow/presentation/screens/strain_selection_screen.dart';
import '../../features/grow/presentation/screens/grow_config_screen.dart';
import '../../features/grow/presentation/screens/start_date_screen.dart';
import '../../features/grow/presentation/screens/generating_plan_screen.dart';
import '../../features/grow/presentation/screens/plan_summary_screen.dart';
import '../../features/grow/presentation/screens/grow_active_screen.dart'; // Restored

// Custom Transition
Page<void> _slideUpTransition(BuildContext context, GoRouterState state, Widget child) {
  return CustomTransitionPage<void>(
    key: state.pageKey,
    child: child,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      // Slide up from bottom
      return SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 1),
          end: Offset.zero,
        ).animate(CurvedAnimation(parent: animation, curve: Curves.easeInOut)),
        child: child,
      );
    },
  );
}

Page<void> _slideRightTransition(BuildContext context, GoRouterState state, Widget child) {
  return CustomTransitionPage<void>(
    key: state.pageKey,
    child: child,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
       // Slide from right
       return SlideTransition(
         position: Tween<Offset>(
           begin: const Offset(1, 0),
           end: Offset.zero,
         ).animate(CurvedAnimation(parent: animation, curve: Curves.easeInOut)),
         child: child,
       );
    },
  );
}

final appRouter = GoRouter(
  initialLocation: '/splash',
  routes: [
    // --- Public / Auth ---
    GoRoute(
      path: '/splash',
      builder: (context, state) => const SplashScreen(),
    ),
    GoRoute(
      path: '/onboarding',
      builder: (context, state) => const OnboardingScreen(),
    ),
    GoRoute(
      path: '/login',
      builder: (context, state) => const LoginScreen(),
    ),
    GoRoute(
      path: '/register',
      builder: (context, state) => const RegisterScreen(),
    ),

    // --- Grow Setup Flow (No Bottom Nav) ---
    GoRoute(
      path: '/grow/strain',
      builder: (context, state) => const StrainSelectionScreen(),
    ),
    GoRoute(
      path: '/grow/config',
      builder: (context, state) => GrowConfigScreen(extra: state.extra as Map<String, dynamic>),
    ),
    GoRoute(
      path: '/grow/start-date',
      builder: (context, state) => StartDateScreen(extra: state.extra as Map<String, dynamic>),
    ),
    GoRoute(
      path: '/grow/generating',
      builder: (context, state) => GeneratingPlanScreen(extra: state.extra as Map<String, dynamic>),
    ),
    GoRoute(
      path: '/grow/summary',
      builder: (context, state) => PlanSummaryScreen(extra: state.extra as Map<String, dynamic>),
    ),

    // --- Overlays / Modals ---
    GoRoute(
      path: '/create-post',
      pageBuilder: (context, state) => _slideUpTransition(context, state, const CreatePostScreen()),
    ),
    GoRoute(
      path: '/chat',
      pageBuilder: (context, state) => _slideUpTransition(context, state, const ChatScreen()),
    ),
    GoRoute(
      path: '/edit-profile',
      builder: (context, state) => const EditProfileScreen(),
    ),
    GoRoute(
      path: '/settings',
      builder: (context, state) => const SettingsScreen(),
    ),
     GoRoute(
      path: '/public-profile',
      builder: (context, state) => const PublicProfileScreen(),
    ),

    // --- Detailed Screens ---
    GoRoute(
      path: '/post/:id',
      pageBuilder: (context, state) {
        final post = state.extra as PostModel?;
        if (post == null) return const MaterialPage(child: Scaffold(body: Center(child: Text('Post Not Found'))));
        return _slideRightTransition(context, state, PostDetailScreen(post: post));
      },
    ),

    // --- Shell Route (Persistent Bottom Nav) ---
    ShellRoute(
      builder: (context, state, child) => MainScaffold(child: child),
      routes: [
        GoRoute(
          path: '/home',
          pageBuilder: (context, state) => const NoTransitionPage(child: HomeScreen()),
        ),
        GoRoute(
          path: '/grow',
          pageBuilder: (context, state) => const NoTransitionPage(child: GrowActiveScreen()),
        ),
        GoRoute(
          path: '/social',
          pageBuilder: (context, state) => const NoTransitionPage(child: FeedScreen()),
        ),
        GoRoute(
          path: '/profile',
          pageBuilder: (context, state) => const NoTransitionPage(child: ProfileScreen()),
        ),
      ],
    ),
  ],
);
