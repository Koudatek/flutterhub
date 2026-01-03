import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../features/dashboard/presentation/screens/dashboard_screen.dart';

/// Énumération des routes de l'application
enum AppRoute {
  dashboard('/', 'dashboard'),
  installFlutter('/install-flutter', 'install-flutter'),
  doctor('/doctor', 'doctor'),
  settings('/settings', 'settings');

  const AppRoute(this.path, this.name);

  final String path;
  final String name;
}

/// Extension pour faciliter la navigation avec les routes
extension AppRouteExtension on AppRoute {
  /// Navigue vers cette route
  void go(BuildContext context) => context.go(path);

  /// Remplace la pile de navigation par cette route
  void goNamed(BuildContext context) => context.goNamed(name);

  /// Navigue vers cette route en remplaçant la route actuelle
  void push(BuildContext context) => context.push(path);

  /// Navigue vers cette route nommée en remplaçant la route actuelle
  void pushNamed(BuildContext context) => context.pushNamed(name);
}

/// Configuration du routeur de l'application
class AppRouter {
  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  /// Builder pour les transitions de page personnalisées
  static Page<T> _buildPageTransition<T>(
    BuildContext context,
    GoRouterState state,
    Widget child, {
    Duration duration = const Duration(milliseconds: 400),
  }) {
    return CustomTransitionPage<T>(
      key: state.pageKey,
      child: child,
      transitionDuration: duration,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const begin = Offset(0.0, 0.05);
        const end = Offset.zero;

        final slideAnimation = Tween(begin: begin, end: end)
            .animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic));

        final fadeAnimation = Tween(begin: 0.0, end: 1.0)
            .animate(CurvedAnimation(parent: animation, curve: Curves.easeIn));

        return SlideTransition(
          position: slideAnimation,
          child: FadeTransition(
            opacity: fadeAnimation,
            child: child,
          ),
        );
      },
    );
  }

  /// Instance du routeur GoRouter
  static final GoRouter router = GoRouter(
    navigatorKey: navigatorKey,
    initialLocation: AppRoute.dashboard.path,
    routes: [
      // Route racine avec ShellRoute pour conserver la barre de navigation
      ShellRoute(
        builder: (context, state, child) => const DashboardScreen(),
        routes: [
          // Route du tableau de bord
          GoRoute(
            path: AppRoute.dashboard.path,
            name: AppRoute.dashboard.name,
            pageBuilder: (context, state) => const NoTransitionPage(
              child: SizedBox.shrink(),
            ),
          ),

          // Route pour l'installation de Flutter
          GoRoute(
            path: AppRoute.installFlutter.path,
            name: AppRoute.installFlutter.name,
            pageBuilder: (context, state) => const NoTransitionPage(
              child: SizedBox.shrink(),
            ),
          ),

          // Route pour Flutter Doctor
          GoRoute(
            path: AppRoute.doctor.path,
            name: AppRoute.doctor.name,
            pageBuilder: (context, state) => const NoTransitionPage(
              child: SizedBox.shrink(),
            ),
          ),

          // Route pour les paramètres
          GoRoute(
            path: AppRoute.settings.path,
            name: AppRoute.settings.name,
            pageBuilder: (context, state) => const NoTransitionPage(
              child: SizedBox.shrink(),
            ),
          ),
        ],
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text('Page non trouvée: ${state.uri.path}'),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => AppRoute.dashboard.go(context),
              child: const Text('Retour à l\'accueil'),
            ),
          ],
        ),
      ),
    ),
  );

  /// Méthode utilitaire pour obtenir le nom de la route depuis le chemin
  static String? getRouteNameFromPath(String path) {
    return AppRoute.values
        .where((route) => route.path == path)
        .map((route) => route.name)
        .firstOrNull;
  }

  /// Méthode utilitaire pour obtenir le chemin depuis le nom de la route
  static String? getPathFromRouteName(String name) {
    return AppRoute.values
        .where((route) => route.name == name)
        .map((route) => route.path)
        .firstOrNull;
  }
}
