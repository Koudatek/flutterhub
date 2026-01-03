import 'dart:io';
class PlatformService {
  static const String _unknown = 'unknown';

  /// Détecte l'OS actuel
  static String detectOS() {
    if (Platform.isWindows) return 'windows';
    if (Platform.isMacOS) return 'macos';
    if (Platform.isLinux) return 'linux';
    return _unknown;
  }

  /// Vérifie si l'OS supporte une plateforme de développement
  static bool supportsPlatform(String os, String platform) {
    final config = _getPlatformConfig(os);
    return config.supportedPlatforms.contains(platform);
  }

  /// Récupère les plateformes obligatoires pour un OS
  static List<String> getRequiredPlatforms(String os) {
    final config = _getPlatformConfig(os);
    return config.requiredPlatforms;
  }

  /// Récupère les plateformes optionnelles pour un OS
  static List<String> getOptionalPlatforms(String os) {
    final config = _getPlatformConfig(os);
    return config.optionalPlatforms;
  }

  /// Récupère la configuration pour un OS spécifique
  static PlatformConfig getPlatformConfig(String os) {
    return _getPlatformConfig(os);
  }

  /// Récupère la configuration pour un OS spécifique (privée)
  static PlatformConfig _getPlatformConfig(String os) {
    switch (os) {
      case 'windows':
        return _windowsConfig;
      case 'macos':
        return _macosConfig;
      case 'linux':
        return _linuxConfig;
      default:
        return _unknownConfig;
    }
  }

  /// Configuration pour Windows
  static const _windowsConfig = PlatformConfig(
    supportedPlatforms: ['android', 'web', 'windows'],
    requiredPlatforms: [], // Flutter SDK toujours requis
    optionalPlatforms: ['android', 'web', 'windows'],
    unsupportedPlatforms: ['ios', 'macos', 'linux'],
    recommendations: {
      'android': 'Recommandé pour la plupart des développeurs',
      'web': 'Facile à commencer, pas de configuration spéciale',
      'windows': 'Pour développer des apps desktop Windows natives',
      'ios': 'Impossible sur Windows - nécessite macOS avec Xcode',
    },
  );

  /// Configuration pour macOS
  static const _macosConfig = PlatformConfig(
    supportedPlatforms: ['android', 'ios', 'web', 'macos'],
    requiredPlatforms: [], // Flutter SDK toujours requis
    optionalPlatforms: ['android', 'ios', 'web', 'macos'],
    unsupportedPlatforms: ['windows', 'linux'],
    recommendations: {
      'ios': 'Recommandé sur macOS - nécessite Xcode',
      'android': 'Support complet avec Android Studio',
      'macos': 'Pour développer des apps desktop macOS natives',
      'web': 'Support complet avec Chrome/Safari',
    },
  );

  /// Configuration pour Linux
  static const _linuxConfig = PlatformConfig(
    supportedPlatforms: ['android', 'web', 'linux'],
    requiredPlatforms: [],
    optionalPlatforms: ['android', 'web', 'linux'],
    unsupportedPlatforms: ['ios', 'macos', 'windows'],
    recommendations: {
      'android': 'Support complet avec Android Studio',
      'linux': 'Pour développer des apps desktop Linux natives',
      'web': 'Support complet avec Chrome/Firefox',
      'ios': 'Impossible sur Linux - nécessite macOS avec Xcode',
    },
  );

  /// Configuration par défaut
  static const _unknownConfig = PlatformConfig(
    supportedPlatforms: ['web'],
    requiredPlatforms: [],
    optionalPlatforms: ['web'],
    unsupportedPlatforms: ['android', 'ios', 'windows', 'macos', 'linux'],
    recommendations: {
      'web': 'Seul support disponible - développement web uniquement',
    },
  );
}

/// Configuration d'une plateforme
class PlatformConfig {
  const PlatformConfig({
    required this.supportedPlatforms,
    required this.requiredPlatforms,
    required this.optionalPlatforms,
    required this.unsupportedPlatforms,
    required this.recommendations,
  });

  final List<String> supportedPlatforms;
  final List<String> requiredPlatforms;
  final List<String> optionalPlatforms;
  final List<String> unsupportedPlatforms;
  final Map<String, String> recommendations;
}

/// Informations détaillées sur une plateforme
class PlatformInfo {
  const PlatformInfo({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    required this.color,
    required this.requirements,
  });

  final String id;
  final String name;
  final String description;
  final String icon;
  final int color;
  final List<String> requirements;

  static const android = PlatformInfo(
    id: 'android',
    name: 'Android',
    description: 'Développer des applications Android natives',
    icon: 'android',
    color: 0xFF3DDC84,
    requirements: ['Android SDK', 'Android Studio', 'JDK'],
  );

  static const ios = PlatformInfo(
    id: 'ios',
    name: 'iOS',
    description: 'Développer des applications iOS natives',
    icon: 'ios',
    color: 0xFF007AFF,
    requirements: ['Xcode', 'iOS Simulator'],
  );

  static const web = PlatformInfo(
    id: 'web',
    name: 'Web',
    description: 'Développer pour le navigateur web',
    icon: 'web',
    color: 0xFF4285F4,
    requirements: ['Chrome ou autre navigateur moderne'],
  );

  static const windows = PlatformInfo(
    id: 'windows',
    name: 'Windows',
    description: 'Développer des applications desktop Windows',
    icon: 'computer',
    color: 0xFF0078D4,
    requirements: ['Visual Studio', 'Windows SDK'],
  );

  static const macos = PlatformInfo(
    id: 'macos',
    name: 'macOS',
    description: 'Développer des applications desktop macOS',
    icon: 'desktop_mac',
    color: 0xFF000000,
    requirements: ['Xcode', 'macOS SDK'],
  );

  static const linux = PlatformInfo(
    id: 'linux',
    name: 'Linux',
    description: 'Développer des applications desktop Linux',
    icon: 'computer',
    color: 0xFFFCC624,
    requirements: ['GTK development libraries'],
  );
}
