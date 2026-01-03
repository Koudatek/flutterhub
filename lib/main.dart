import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:window_manager/window_manager.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

import 'core/config/logger/logger_config.dart';
import 'core/config/routes/app_router.dart';
import 'core/theme/app_theme.dart';

// Initialisation des contrôleurs globaux
Future<void> _initControllers() async {
  if (!kIsWeb) {
    await windowManager.ensureInitialized();
    
    const windowOptions = WindowOptions(
      size: Size(1200, 800),
      minimumSize: Size(1000, 700),
      center: true,
      backgroundColor: Colors.transparent,
      skipTaskbar: false,
      titleBarStyle: TitleBarStyle.normal,
    );

    await windowManager.waitUntilReadyToShow(windowOptions, () async {
      await windowManager.show();
      await windowManager.focus();
    });
  }
}

void main() async {
  // Initialize logger first
  await AppLogger.init();
  
  // Now we can log
  AppLogger.info('Démarrage de l\'application FlutterHub');
  
  // Rest of your initialization
  WidgetsFlutterBinding.ensureInitialized();
  await _initControllers();
  
  runApp(
    const ProviderScope(
      child: FlutterHubApp(),
    ),
  );
}

class FlutterHubApp extends HookWidget {
  const FlutterHubApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'FlutterHub',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      routerConfig: AppRouter.router,
      debugShowCheckedModeBanner: false,
    );
  }
}
