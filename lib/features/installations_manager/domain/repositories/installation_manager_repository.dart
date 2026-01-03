import 'package:flutterhub/features/installations_manager/domain/entities/installer_entities.dart';

/// Repository for all installation manager operations
abstract class InstallationManagerRepository {
  // Version detection and management
  
  /// Détecte toutes les versions de Flutter installées sur le système
  Future<List<FlutterVersion>> detectInstalledVersions();
  
  /// Récupère la dernière version stable de Flutter disponible
  Future<String> getLatestStableVersion();
  
  /// Récupère toutes les versions stables de Flutter disponibles
  Future<List<Map<String, dynamic>>> getAllStableReleases();
  
  /// Récupère les informations sur la dernière version de Flutter
  Future<FlutterSdkInfo> getLatestSdkInfo();

  // Installation operations
  
  /// Installe une nouvelle version de Flutter
  /// [force] : Si vrai, force l'installation même si une version est déjà installée
  Future<InstallationStatus> installFlutterSdk({bool force = false});
  
  /// Met à jour la version de Flutter actuellement installée
  Future<InstallationStatus> updateFlutterSdk();
  
  /// Télécharge l'archive Flutter
  Future<String> downloadSdk(FlutterSdkInfo sdkInfo);
  
  /// Extrait l'archive Flutter
  Future<void> extractSdk(FlutterSdkInfo sdkInfo);
  
  /// Met à jour le PATH système pour inclure le répertoire bin de Flutter
  Future<void> updatePath(String flutterBinPath);

  // Status checking
  
  /// Vérifie si Flutter est installé
  Future<bool> isFlutterInstalled();
  
  /// Trouve le chemin d'installation de Flutter
  Future<String?> findFlutterPath();
  
  /// Exécute la commande flutter doctor
  Future<DoctorResult> runFlutterDoctor();
  
  /// Vérifie si une mise à jour est disponible
  Future<bool> isUpdateAvailable();
  
  /// Récupère le répertoire d'installation par défaut pour Flutter
  Future<String> getDefaultInstallDirectory();
}
