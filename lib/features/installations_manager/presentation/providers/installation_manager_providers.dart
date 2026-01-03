import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/installation_component.dart' as comp;
import 'package:dio/dio.dart';
import 'package:flutter_archive/flutter_archive.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:flutterhub/core/config/logger/logger_config.dart';
import 'package:flutterhub/features/installations_manager/data/datasources/installation_manager_local_datasource.dart';
import 'package:flutterhub/features/installations_manager/data/datasources/installation_manager_remote_datasource.dart';
import 'package:flutterhub/features/installations_manager/data/repositories/installation_manager_repository_impl.dart';
import 'package:flutterhub/features/installations_manager/domain/entities/installer_entities.dart';
import 'package:flutterhub/features/installations_manager/domain/repositories/installation_manager_repository.dart';
import 'package:flutterhub/features/installations_manager/domain/usecases/installation_manager_usecases.dart';

final dioProvider = Provider<Dio>((ref) => Dio());

final installationManagerLocalDataSourceProvider = Provider<InstallationManagerLocalDataSource>((ref) {
  return const InstallationManagerLocalDataSourceImpl();
});

final installationManagerRemoteDataSourceProvider = Provider<InstallationManagerRemoteDataSource>((ref) {
  final dio = ref.watch(dioProvider);
  return InstallationManagerRemoteDataSourceImpl(dio: dio);
});

// Repository
final installationManagerRepositoryProvider = Provider<InstallationManagerRepository>((ref) {
  final localDataSource = ref.watch(installationManagerLocalDataSourceProvider);
  final remoteDataSource = ref.watch(installationManagerRemoteDataSourceProvider);

  return InstallationManagerRepositoryImpl(
    localDataSource: localDataSource,
    remoteDataSource: remoteDataSource,
  );
});

// Use cases
final detectInstalledFlutterVersionsUseCaseProvider = Provider<DetectInstalledFlutterVersionsUseCase>((ref) {
  final repository = ref.watch(installationManagerRepositoryProvider);
  return DetectInstalledFlutterVersionsUseCase(repository: repository);
});

final getLatestStableFlutterVersionUseCaseProvider = Provider<GetLatestStableFlutterVersionUseCase>((ref) {
  final repository = ref.watch(installationManagerRepositoryProvider);
  return GetLatestStableFlutterVersionUseCase(repository: repository);
});

final getAllStableFlutterReleasesUseCaseProvider = Provider<GetAllStableFlutterReleasesUseCase>((ref) {
  final repository = ref.watch(installationManagerRepositoryProvider);
  return GetAllStableFlutterReleasesUseCase(repository: repository);
});

final checkFlutterVersionUpdateUseCaseProvider = Provider<CheckFlutterVersionUpdateUseCase>((ref) {
  return const CheckFlutterVersionUpdateUseCase();
});

final getFlutterInstallationStateUseCaseProvider = Provider<GetFlutterInstallationStateUseCase>((ref) {
  final detectUseCase = ref.watch(detectInstalledFlutterVersionsUseCaseProvider);
  final getLatestUseCase = ref.watch(getLatestStableFlutterVersionUseCaseProvider);
  final checkUpdateUseCase = ref.watch(checkFlutterVersionUpdateUseCaseProvider);

  return GetFlutterInstallationStateUseCase(
    detectVersionsUseCase: detectUseCase,
    getLatestVersionUseCase: getLatestUseCase,
    checkUpdateUseCase: checkUpdateUseCase,
  );
});

// Installation use cases - now fully migrated from flutter_installer
final installFlutterSdkUseCaseProvider = Provider<InstallFlutterSdkUseCase>((ref) {
  final repository = ref.watch(installationManagerRepositoryProvider);
  return InstallFlutterSdkUseCase(repository: repository);
});

final updateFlutterSdkUseCaseProvider = Provider<UpdateFlutterSdkUseCase>((ref) {
  final installUseCase = ref.watch(installFlutterSdkUseCaseProvider);
  return UpdateFlutterSdkUseCase(installUseCase: installUseCase);
});

// State providers
final flutterVersionsProvider = FutureProvider<List<FlutterVersion>>((ref) {
  final useCase = ref.watch(detectInstalledFlutterVersionsUseCaseProvider);
  return useCase();
});

final latestStableFlutterVersionProvider = FutureProvider<String?>((ref) {
  final useCase = ref.watch(getLatestStableFlutterVersionUseCaseProvider);
  return useCase();
});

final allStableFlutterReleasesProvider = FutureProvider<List<Map<String, dynamic>>>((ref) {
  final useCase = ref.watch(getAllStableFlutterReleasesUseCaseProvider);
  return useCase();
});

final flutterInstallationStateProvider = FutureProvider<FlutterInstallationState>((ref) {
  final useCase = ref.watch(getFlutterInstallationStateUseCaseProvider);
  return useCase();
});

// Update state notifier - now fully implemented with migrated installation manager
final updateFlutterSdkStateProvider = NotifierProvider<UpdateFlutterNotifier, InstallationStatus>(UpdateFlutterNotifier.new);

class UpdateFlutterNotifier extends Notifier<InstallationStatus> {
  @override
  InstallationStatus build() {
    return InstallationStatus.notStarted;
  }

  Future<void> updateSdk() async {
    state = InstallationStatus.downloading;
    try {
      // Use the migrated installation manager repository
      final repository = ref.read(installationManagerRepositoryProvider);
      final status = await repository.updateFlutterSdk();
      state = status;
    } catch (e) {
      AppLogger.error('Update failed in provider', error: e);
      
      // Vérifier si c'est une erreur de fichiers verrouillés
      if (e.toString().contains('another application') || 
          e.toString().contains('processus ne peut pas accéder')) {
        // Pour les erreurs de fichiers verrouillés, on pourrait afficher un état spécial
        // ou permettre à l'utilisateur de réessayer plus tard
        state = InstallationStatus.failed;
      } else {
        state = InstallationStatus.failed;
      }
      
      rethrow; // Permettre à l'UI de gérer l'erreur
    }
  }
}

// ============================================================================
// NEW: Complete Installation Provider (OS Detection + Components)
// ============================================================================

final installProvider = NotifierProvider<InstallNotifier, Map<String, dynamic>>(InstallNotifier.new);

class InstallNotifier extends Notifier<Map<String, dynamic>> {
  @override
  Map<String, dynamic> build() {
    final os = _detectOS();
    final components = _loadComponentsSync(os);
    return {
      'os': os,
      'components': components,
      'targets': {for (var t in comp.TargetPlatform.values) t: false},
      'isLoadingVersions': false,
      'downloadPath': _getDefaultDownloadPath(),
      'isInstallingFlutter': false,
    };
  }

  String _detectOS() {
    return Platform.isWindows ? 'Windows' : Platform.isMacOS ? 'macOS' : Platform.isLinux ? 'Linux' : 'Unknown';
  }

  String _getDefaultDownloadPath() {
    final os = _detectOS();
    switch (os) {
      case 'Windows':
        return '${Platform.environment['USERPROFILE']}\\Downloads';
      case 'macOS':
      case 'Linux':
        return '${Platform.environment['HOME']}/Downloads';
      default:
        return Platform.environment['HOME'] ?? '/tmp';
    }
  }

  List<comp.InstallationComponent> _loadComponentsSync(String os) {
    // Real versions and sizes as of November 14, 2025 (will be updated by fetchLatestVersions)
    List<comp.InstallationComponent> components = [
      comp.InstallationComponent(
        name: 'Git',
        version: '2.51.2', // Will be updated to latest
        downloadSize: '~50 MB',
        diskSize: '~150 MB',
        checkCommand: 'git --version',
        supportedTargets: comp.TargetPlatform.values, // All platforms
        iconName: 'git',
      ),
      comp.InstallationComponent(
        name: 'Visual Studio Code',
        version: '1.106', // Will be updated to latest
        downloadSize: os == 'Windows' ? '97 MB' : os == 'macOS' ? '217 MB' : '93 MB',
        diskSize: '<500 MB',
        checkCommand: 'code --version',
        supportedTargets: comp.TargetPlatform.values,
        iconName: 'vscode',
      ),
      comp.InstallationComponent(
        name: 'Flutter SDK',
        version: '3.38.0',
        downloadSize: '~1.2 GB',
        diskSize: '~2.5 GB',
        checkCommand: 'flutter --version',
        supportedTargets: comp.TargetPlatform.values,
        iconName: 'flutter',
      ),
      comp.InstallationComponent(
        name: 'Android Studio',
        version: 'Otter 2025.2.1', // Will be updated to latest
        downloadSize: '~1.2 GB',
        diskSize: '~4 GB',
        checkCommand: Platform.isWindows ? 'studio.bat --version' : 'studio.sh --version',
        supportedTargets: [comp.TargetPlatform.android],
        iconName: 'android_studio',
      ),
      if (os == 'macOS')
        comp.InstallationComponent(
          name: 'Xcode',
          version: '26.1.1',
          downloadSize: '12.1 GB',
          diskSize: '~15 GB',
          checkCommand: 'xcodebuild -version',
          supportedTargets: [comp.TargetPlatform.ios],
          iconName: 'xcode',
        ),
      // Web-specific components
      comp.InstallationComponent(
        name: 'Google Chrome',
        version: '131.0', // Will be updated to latest
        downloadSize: os == 'Windows' ? '110 MB' : os == 'macOS' ? '180 MB' : '120 MB',
        diskSize: '<500 MB',
        checkCommand: os == 'Windows' ? 'where chrome' : 'which google-chrome',
        supportedTargets: [comp.TargetPlatform.web],
        iconName: 'chrome',
      ),
      // Desktop-specific components (follows Flutter official docs)
      if (os == 'Windows')
        comp.InstallationComponent(
          name: 'Visual Studio',
          version: '2022', // Will be updated to latest
          downloadSize: '~10 GB',
          diskSize: '~20 GB',
          checkCommand: 'where devenv', // Visual Studio IDE check
          supportedTargets: [comp.TargetPlatform.desktop],
          iconName: 'visual_studio',
        ),
      if (os == 'Linux')
        comp.InstallationComponent(
          name: 'Clang',
          version: 'System', // Usually 14+
          downloadSize: '~500 MB',
          diskSize: '~1 GB',
          checkCommand: 'clang --version',
          supportedTargets: [comp.TargetPlatform.desktop],
          iconName: 'clang',
        ),
    ];

    // Return components with default installation status (will be checked later)
    return components.map((c) => c.copyWith(isInstalled: false)).toList();
  }

  Future<bool> _checkInstalled(String? command) async {
    if (command == null) return false;
    try {
      final result = await Process.run(command.split(' ').first, command.split(' ').skip(1).toList());
      return result.exitCode == 0;
    } catch (e) {
      return false;
    }
  }

  void updateTargets(Set<comp.TargetPlatform> selectedTargets) {
    final updatedComponents = (state['components'] as List<comp.InstallationComponent>).map((component) {
      bool required = false;

      // Git and VS Code are always required
      if (component.name == 'Git' || component.name == 'Visual Studio Code' || component.name == 'Flutter SDK') {
        required = true;
      }

      // Platform-specific requirements
      if (selectedTargets.contains(comp.TargetPlatform.android) && component.name == 'Android Studio') {
        required = true;
      }
      if (selectedTargets.contains(comp.TargetPlatform.ios) && component.name == 'Xcode') {
        required = true;
      }
      if (selectedTargets.contains(comp.TargetPlatform.web) && component.name == 'Google Chrome') {
        required = true;
      }
      if (selectedTargets.contains(comp.TargetPlatform.desktop) && 
          (component.name == 'Visual Studio' || component.name == 'Clang')) {
        required = true;
      }

      return component.copyWith(isRequired: required);
    }).toList();

    state = {...state, 'components': updatedComponents, 'targets': {for (var t in comp.TargetPlatform.values) t: selectedTargets.contains(t)}};
  }

  Future<void> checkInstallationStatus() async {
    final components = state['components'] as List<comp.InstallationComponent>;
    final updatedComponents = <comp.InstallationComponent>[];

    for (final component in components) {
      final isInstalled = await _checkInstalled(component.checkCommand);
      updatedComponents.add(component.copyWith(isInstalled: isInstalled));
    }

    state = {...state, 'components': updatedComponents};
  }

  Future<void> fetchLatestVersions() async {
    state = {...state, 'isLoadingVersions': true};

    final components = state['components'] as List<comp.InstallationComponent>;
    final updatedComponents = <comp.InstallationComponent>[];

    // Get latest Flutter version using existing use case
    final flutterUseCase = ref.read(getLatestStableFlutterVersionUseCaseProvider);
    final latestFlutterVersion = await flutterUseCase() ?? '';

    for (final component in components) {
      String latestVersion = ''; // No default version
      
      try {
        switch (component.name) {
          case 'Git':
            latestVersion = await _fetchGitLatestVersion();
            break;
          case 'Visual Studio Code':
            latestVersion = await _fetchVSCodeLatestVersion();
            break;
          case 'Flutter SDK':
            latestVersion = latestFlutterVersion;
            break;
          case 'Android Studio':
            latestVersion = await _fetchAndroidStudioLatestVersion();
            break;
          case 'Google Chrome':
            latestVersion = await _fetchChromeLatestVersion();
            break;
          case 'Visual Studio':
            latestVersion = await _fetchVSBuildToolsLatestVersion(); // Reuse for full VS
            break;
          case 'Clang':
            latestVersion = await _fetchClangLatestVersion();
            break;
        }
      } catch (e) {
        // Keep default version if fetch fails
        print('Failed to fetch latest version for ${component.name}: $e');
      }

      updatedComponents.add(component.copyWith(version: latestVersion));
    }

    state = {
      ...state, 
      'components': updatedComponents,
      'isLoadingVersions': false
    };
  }

  Future<String> _fetchGitLatestVersion() async {
    try {
      final response = await Dio().get('https://api.github.com/repos/git/git/releases/latest');
      final data = response.data as Map<String, dynamic>;
      final tag = data['tag_name'] as String;
      return tag.startsWith('v') ? tag.substring(1) : tag;
    } catch (e) {
      return '';
    }
  }

  Future<String> _fetchVSCodeLatestVersion() async {
    try {
      final response = await Dio().get('https://api.github.com/repos/microsoft/vscode/releases/latest');
      final data = response.data as Map<String, dynamic>;
      final tag = data['tag_name'] as String;
      return tag.startsWith('v') ? tag.substring(1) : tag;
    } catch (e) {
      return '';
    }
  }

  Future<String> _fetchAndroidStudioLatestVersion() async {
    try {
      // Android Studio releases are a bit different, let's try their update API
      final response = await Dio().get('https://developer.android.com/studio#downloads');
      // This is a simple regex approach - in production, use proper HTML parsing
      final regex = RegExp(r'Android Studio\s+([0-9]+\.[0-9]+\.[0-9]+(?:\.[0-9]+)?)');
      final match = regex.firstMatch(response.data.toString());
      if (match != null) {
        return match.group(1)!;
      }
    } catch (e) {
      // No fallback
    }
    return '';
  }

  Future<String> _fetchChromeLatestVersion() async {
    try {
      final response = await Dio().get('https://chromedriver.chromium.org/downloads');
      // Extract version from HTML - simplified approach
      final regex = RegExp(r'ChromeDriver\s+([0-9]+(?:\.[0-9]+)+)');
      final match = regex.firstMatch(response.data.toString());
      if (match != null) {
        return match.group(1)!;
      }
    } catch (e) {
      // No fallback
    }
    return '';
  }

  Future<String> _fetchVSBuildToolsLatestVersion() async {
    // Visual Studio uses year-based versioning, latest is 2022
    return '2022';
  }

  Future<String> _fetchClangLatestVersion() async {
    try {
      // Check LLVM releases
      final response = await Dio().get('https://api.github.com/repos/llvm/llvm-project/releases/latest');
      final data = response.data as Map<String, dynamic>;
      final tag = data['tag_name'] as String;
      // Extract version from llvmorg-XX.Y.Z
      final regex = RegExp(r'llvmorg-(\d+(?:\.\d+)*)');
      final match = regex.firstMatch(tag);
      if (match != null) {
        return match.group(1)!;
      }
    } catch (e) {
      // No fallback
    }
    return '';
  }

  String getDownloadUrl(String componentName, String version, String os) {
    switch (componentName) {
      case 'Git':
        return _getGitDownloadUrl(version, os);
      case 'Visual Studio Code':
        return _getVSCodeDownloadUrl(version, os);
      case 'Android Studio':
        return _getAndroidStudioDownloadUrl(version, os);
      case 'Google Chrome':
        return _getChromeDownloadUrl(version, os);
      case 'Visual Studio':
        return _getVisualStudioDownloadUrl(version, os);
      case 'Clang':
        return _getClangDownloadUrl(version, os);
      case 'Flutter SDK':
        return _getFlutterSdkDownloadUrl(version, os);
      case 'Xcode':
        return _getXcodeDownloadUrl(version, os);
      default:
        return '';
    }
  }

  String _getGitDownloadUrl(String version, String os) {
    // Git releases: https://github.com/git/git/releases
    final baseUrl = 'https://github.com/git/git/releases/download/v$version';
    switch (os) {
      case 'Windows':
        return '$baseUrl/Git-$version-64-bit.exe';
      case 'macOS':
        return '$baseUrl/git-$version-intel-universal-mavericks.dmg';
      case 'Linux':
        return '$baseUrl/git-$version.tar.gz';
      default:
        return '';
    }
  }

  String _getVSCodeDownloadUrl(String version, String os) {
    // VS Code releases: https://code.visualstudio.com/download
    final baseUrl = 'https://code.visualstudio.com/sha/download?build=stable&os=';
    switch (os) {
      case 'Windows':
        return '${baseUrl}win32-x64-user';
      case 'macOS':
        return '${baseUrl}darwin-universal';
      case 'Linux':
        return '${baseUrl}linux-x64';
      default:
        return '';
    }
  }

  String _getAndroidStudioDownloadUrl(String version, String os) {
    // Android Studio downloads: https://developer.android.com/studio
    final baseUrl = 'https://redirector.gvt1.com/edgedl/android/studio';
    switch (os) {
      case 'Windows':
        return '$baseUrl/ide-zips/$version/android-studio-$version-windows.zip';
      case 'macOS':
        return '$baseUrl/ide-zips/$version/android-studio-$version-mac.zip';
      case 'Linux':
        return '$baseUrl/ide-zips/$version/android-studio-$version-linux.tar.gz';
      default:
        return '';
    }
  }

  String _getChromeDownloadUrl(String version, String os) {
    // Chrome downloads: https://www.google.com/chrome/
    final baseUrl = 'https://dl.google.com/chrome';
    switch (os) {
      case 'Windows':
        return '$baseUrl/install/latest/chrome_installer.exe';
      case 'macOS':
        return '$baseUrl/mac/stable/GGRO/googlechrome.dmg';
      case 'Linux':
        return '$baseUrl/linux/direct/google-chrome-stable_current_amd64.deb';
      default:
        return '';
    }
  }

  String _getVisualStudioDownloadUrl(String version, String os) {
    // Visual Studio full IDE: https://visualstudio.microsoft.com/downloads/
    if (os == 'Windows') {
      return 'https://visualstudio.microsoft.com/thank-you-downloading-visual-studio/?sku=Community&rel=$version';
    }
    return '';
  }

  String _getClangDownloadUrl(String version, String os) {
    // Clang/LLVM downloads: https://releases.llvm.org/
    if (os == 'Linux') {
      return 'https://github.com/llvm/llvm-project/releases/download/llvmorg-$version/clang+llvm-$version-x86_64-linux-gnu-ubuntu-18.04.tar.xz';
    }
    return '';
  }

  String _getFlutterSdkDownloadUrl(String version, String os) {
    // Flutter SDK downloads are handled by the existing remote datasource
    // This would return the URL from the Flutter releases API
    return 'https://storage.googleapis.com/flutter_infra_release/releases/stable/${os.toLowerCase()}/flutter_${os.toLowerCase()}_$version-stable.zip';
  }

  String _getXcodeDownloadUrl(String version, String os) {
    // Xcode from App Store or developer.apple.com
    if (os == 'macOS') {
      return 'https://developer.apple.com/download/all/?q=Xcode%20$version';
    }
    return '';
  }

  Future<void> installFlutterSdk() async {
    state = {...state, 'isInstallingFlutter': true};

    try {
      final components = state['components'] as List<comp.InstallationComponent>;
      final flutterComponent = components.firstWhere(
        (c) => c.name == 'Flutter SDK',
        orElse: () => throw Exception('Flutter SDK component not found'),
      );

      final downloadPath = state['downloadPath'] as String;
      final os = state['os'] as String;

      if (flutterComponent.version.isEmpty) {
        throw Exception('Flutter SDK version not available');
      }

      if (downloadPath.isEmpty) {
        throw Exception('Installation path not specified');
      }

      // Create installation directory if it doesn't exist
      final installDir = Directory(downloadPath);
      if (!await installDir.exists()) {
        await installDir.create(recursive: true);
      }

      // Get download URL
      final downloadUrl = _getFlutterSdkDownloadUrl(flutterComponent.version, os);
      
      // Get temporary directory for download
      final tempDir = await getTemporaryDirectory();
      final zipFilePath = path.join(tempDir.path, 'flutter_${os.toLowerCase()}_${flutterComponent.version}.zip');
      
      // Download Flutter SDK
      final dio = Dio();
      await dio.download(downloadUrl, zipFilePath, onReceiveProgress: (received, total) {
        if (total != -1) {
          print('Download progress: ${(received / total * 100).toStringAsFixed(0)}%');
        }
      });

      // Extract the zip file
      final zipFile = File(zipFilePath);
      await ZipFile.extractToDirectory(
        zipFile: zipFile,
        destinationDir: installDir,
      );

      // Clean up zip file
      await zipFile.delete();

      // Update installation status
      await checkInstallationStatus();

    } catch (e) {
      state = {...state, 'isInstallingFlutter': false};
      throw Exception('Failed to install Flutter SDK: $e');
    }

    state = {...state, 'isInstallingFlutter': false};
  }

  void refreshVersions() async {
    await checkInstallationStatus();
    await fetchLatestVersions();
  }

  void updateDownloadPath(String path) {
    state = {...state, 'downloadPath': path};
  }
}