import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../presentation/screens/splash/splash_screen.dart';
import '../../presentation/screens/camera/camera_screen.dart';
import '../../presentation/screens/editor/editor_screen.dart';
import '../../presentation/screens/settings/settings_screen.dart';

/// App 路由配置
final appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    // Splash Screen
    GoRoute(
      path: '/',
      builder: (context, state) => const SplashScreen(),
    ),

    // Camera Screen
    GoRoute(
      path: '/camera',
      builder: (context, state) => const CameraScreen(),
    ),

    // Editor Screen
    GoRoute(
      path: '/editor',
      builder: (context, state) => const EditorScreen(),
    ),

    // Settings Screen
    GoRoute(
      path: '/settings',
      builder: (context, state) => const SettingsScreen(),
    ),
  ],
);
