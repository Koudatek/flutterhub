import 'package:flutterhub/features/installations_manager/domain/entities/installer_entities.dart';
import 'package:flutterhub/features/installations_manager/domain/repositories/installation_manager_repository.dart';

/// Use case for detecting installed Flutter versions
class DetectInstalledFlutterVersionsUseCase {
  const DetectInstalledFlutterVersionsUseCase({
    required this.repository,
  });

  final InstallationManagerRepository repository;

  Future<List<FlutterVersion>> call() async {
    return repository.detectInstalledVersions();
  }
}

/// Use case for getting the latest stable Flutter version from remote
class GetLatestStableFlutterVersionUseCase {
  const GetLatestStableFlutterVersionUseCase({
    required this.repository,
  });

  final InstallationManagerRepository repository;

  Future<String?> call() async {
    return repository.getLatestStableVersion();
  }
}

/// Use case for getting all stable Flutter releases
class GetAllStableFlutterReleasesUseCase {
  const GetAllStableFlutterReleasesUseCase({
    required this.repository,
  });

  final InstallationManagerRepository repository;

  Future<List<Map<String, dynamic>>> call() async {
    return repository.getAllStableReleases();
  }
}

/// Use case for comparing versions to determine if update is needed
class CheckFlutterVersionUpdateUseCase {
  const CheckFlutterVersionUpdateUseCase();

  Future<bool> call({
    required FlutterVersion? installedVersion,
    required String? latestVersion,
  }) async {
    if (installedVersion == null || latestVersion == null) {
      return false;
    }

    // Simple version comparison - in production, use proper version parsing
    return installedVersion.name != latestVersion;
  }
}

/// Use case for determining the overall Flutter installation state
class GetFlutterInstallationStateUseCase {
  const GetFlutterInstallationStateUseCase({
    required this.detectVersionsUseCase,
    required this.getLatestVersionUseCase,
    required this.checkUpdateUseCase,
  });

  final DetectInstalledFlutterVersionsUseCase detectVersionsUseCase;
  final GetLatestStableFlutterVersionUseCase getLatestVersionUseCase;
  final CheckFlutterVersionUpdateUseCase checkUpdateUseCase;

  Future<FlutterInstallationState> call() async {
    final versions = await detectVersionsUseCase();
    final latestVersion = await getLatestVersionUseCase();

    if (versions.isEmpty) {
      return FlutterInstallationState.notInstalled;
    }

    final defaultVersion = versions.where((v) => v.isDefault).firstOrNull;
    if (defaultVersion != null) {
      final needsUpdate = await checkUpdateUseCase(
        installedVersion: defaultVersion,
        latestVersion: latestVersion,
      );

      return needsUpdate
          ? FlutterInstallationState.updateAvailable
          : FlutterInstallationState.installed;
    }

    return FlutterInstallationState.installed;
  }
}

/// Use case for installing Flutter SDK
class InstallFlutterSdkUseCase {
  const InstallFlutterSdkUseCase({
    required this.repository,
  });

  final InstallationManagerRepository repository;

  Future<InstallationStatus> call({bool force = false}) async {
    return repository.installFlutterSdk(force: force);
  }
}

/// Use case for updating Flutter SDK
class UpdateFlutterSdkUseCase {
  const UpdateFlutterSdkUseCase({
    required this.installUseCase,
  });

  final InstallFlutterSdkUseCase installUseCase;

  Future<InstallationStatus> call() async {
    // Force reinstallation to update to latest version
    return installUseCase(force: true);
  }
}

/// État d'installation de Flutter
enum FlutterInstallationState {
  notInstalled,
  installed,
  updateAvailable,
}
