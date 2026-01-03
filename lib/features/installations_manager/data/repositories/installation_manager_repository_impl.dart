import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_archive/flutter_archive.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

import 'package:flutterhub/core/config/logger/logger_config.dart';
import 'package:flutterhub/features/installations_manager/data/datasources/installation_manager_local_datasource.dart';
import 'package:flutterhub/features/installations_manager/data/datasources/installation_manager_remote_datasource.dart';
import 'package:flutterhub/features/installations_manager/domain/entities/installer_entities.dart';
import 'package:flutterhub/features/installations_manager/domain/repositories/installation_manager_repository.dart';

/// Implementation of InstallationManagerRepository
class InstallationManagerRepositoryImpl implements InstallationManagerRepository {
  InstallationManagerRepositoryImpl({
    required this.localDataSource,
    required this.remoteDataSource,
    Dio? dio,
  }) : _dio = dio ?? Dio();

  final InstallationManagerLocalDataSource localDataSource;
  final InstallationManagerRemoteDataSource remoteDataSource;
  final Dio _dio;

  @override
  Future<List<FlutterVersion>> detectInstalledVersions() async {
    AppLogger.info('Detecting installed Flutter versions');
    return localDataSource.detectInstalledVersions();
  }

  @override
  Future<String> getLatestStableVersion() async {
    AppLogger.info('Getting latest stable Flutter version');
    return remoteDataSource.getLatestStableVersion();
  }

  @override
  Future<List<Map<String, dynamic>>> getAllStableReleases() async {
    AppLogger.info('Getting all stable Flutter releases');
    return remoteDataSource.getAllReleases();
  }

  @override
  Future<FlutterSdkInfo> getLatestSdkInfo() async {
    AppLogger.info('Getting latest SDK info');
    final version = await getLatestStableVersion();
    
    final downloadUrl = await remoteDataSource.getDownloadUrlForVersion(version);
    final installDir = await getDefaultInstallDirectory();
    
    return FlutterSdkInfo(
      version: version,
      downloadUrl: downloadUrl,
      installPath: path.join(installDir, 'flutter_$version'),
    );
  }

  @override
  Future<InstallationStatus> installFlutterSdk({bool force = false}) async {
    AppLogger.info('Installing Flutter SDK', data: {'force': force});
    
    try {
      // Vérifier si déjà installé (sauf si force=true)
      if (!force) {
        final isInstalled = await isFlutterInstalled();
        if (isInstalled) {
          return InstallationStatus.completed;
        }
      }

      // Récupérer les infos de la dernière version
      final sdkInfo = await getLatestSdkInfo();
      
      // Télécharger l'archive
      final archivePath = await downloadSdk(sdkInfo);
      final sdkInfoWithArchive = sdkInfo.copyWith(archivePath: archivePath);
      
      // Extraire l'archive
      await extractSdk(sdkInfoWithArchive);
      
      // Mettre à jour le PATH
      final flutterBinPath = path.join(sdkInfo.installPath, 'bin');
      await updatePath(flutterBinPath);
      
      // Lancer flutter doctor
      final doctorResult = await runFlutterDoctor();
      
      return doctorResult.hasIssues 
          ? InstallationStatus.failed 
          : InstallationStatus.completed;
    } catch (e) {
      AppLogger.error('Failed to install Flutter SDK', error: e);
      return InstallationStatus.failed;
    }
  }

  @override
  Future<InstallationStatus> updateFlutterSdk() async {
    AppLogger.info('Updating Flutter SDK');
    
    try {
      // Vérifier si Flutter est installé
      if (!await isFlutterInstalled()) {
        return InstallationStatus.failed;
      }
      
      // Vérifier si Flutter n'est pas en cours d'utilisation
      if (await _isFlutterInUse()) {
        throw Exception('Flutter update failed: Flutter is currently in use by another application. Please close all Flutter-related applications (IDEs, terminals, emulators) and try again.');
      }
      
      // Mettre à jour via flutter upgrade
      final result = await Process.run(
        'flutter', 
        ['upgrade'],
        runInShell: true,
      );
      
      if (result.exitCode != 0) {
        final stderr = result.stderr.toString();
        AppLogger.error('Failed to update Flutter SDK', 
            error: stderr);
        
        // Vérifier si l'erreur est due à des fichiers verrouillés
        if (stderr.contains('Rename-Item') || 
            stderr.contains('processus ne peut pas accéder') || 
            stderr.contains('another process') ||
            stderr.contains('access denied') ||
            stderr.contains('being used by another process')) {
          AppLogger.warning('Flutter update failed due to locked files - Flutter may be in use by another application');
          throw Exception('Flutter update failed: Flutter is currently in use by another application. Please close all Flutter-related applications (IDEs, terminals) and try again.');
        }
        
        throw Exception('Flutter update failed: $stderr');
      }
      
      // Vérifier l'état après mise à jour
      final doctorResult = await runFlutterDoctor();
      
      return doctorResult.hasIssues 
          ? InstallationStatus.completed // Mise à jour réussie mais problèmes détectés
          : InstallationStatus.completed; // Tout est bon
    } catch (e) {
      AppLogger.error('Failed to update Flutter SDK', error: e);
      rethrow;
    }
  }

  @override
  Future<bool> isFlutterInstalled() async {
    AppLogger.debug('Checking if Flutter is installed');
    final path = await findFlutterPath();
    return path != null && await Directory(path).exists();
  }

  @override
  Future<String?> findFlutterPath() async {
    final versions = await detectInstalledVersions();
    return versions.isNotEmpty ? versions.first.path : null;
  }

  @override
  Future<DoctorResult> runFlutterDoctor() async {
    AppLogger.info('Running flutter doctor');
    
    try {
      final result = await Process.run(
        'flutter', 
        ['doctor', '-v'],
        runInShell: true,
      );
      
      final output = '${result.stdout}\n${result.stderr}';
      final hasIssues = result.exitCode != 0 || 
                       output.toLowerCase().contains('error') ||
                       output.toLowerCase().contains('warning');
      
      // Analyse simple des problèmes
      final issues = output
          .split('\n')
          .where((line) => line.contains('✗') || 
                          line.contains('!') || 
                          line.toLowerCase().contains('error') ||
                          line.toLowerCase().contains('warning'))
          .toList();
      
      return DoctorResult(
        output: output,
        issues: issues,
        hasIssues: hasIssues,
      );
    } catch (e) {
      AppLogger.error('Failed to run flutter doctor', error: e);
      return const DoctorResult(
        output: 'Failed to run flutter doctor',
        issues: ['Failed to execute flutter doctor'],
        hasIssues: true,
      );
    }
  }

  @override
  Future<String> downloadSdk(FlutterSdkInfo sdkInfo) async {
    AppLogger.info('Downloading Flutter SDK', data: {
      'version': sdkInfo.version,
      'url': sdkInfo.downloadUrl,
    });
    
    final tempDir = await getTemporaryDirectory();
    final archivePath = path.join(tempDir.path, 'flutter_${sdkInfo.version}.zip');
    
    try {
      await _dio.download(
        sdkInfo.downloadUrl,
        archivePath,
        onReceiveProgress: (received, total) {
          if (total != -1) {
            final progress = (received / total * 100).round();
            AppLogger.debug('Download progress: $progress%');
          }
        },
      );
      
      AppLogger.info('Download completed', data: {'path': archivePath});
      return archivePath;
    } catch (e) {
      AppLogger.error('Failed to download Flutter SDK', error: e);
      rethrow;
    }
  }

  @override
  Future<void> extractSdk(FlutterSdkInfo sdkInfo) async {
    AppLogger.info('Extracting Flutter SDK', data: {
      'archive': sdkInfo.archivePath,
      'destination': sdkInfo.installPath,
    });
    
    try {
      final archiveFile = File(sdkInfo.archivePath);
      final destinationDir = Directory(sdkInfo.installPath);
      
      // Créer le répertoire de destination s'il n'existe pas
      if (!await destinationDir.exists()) {
        await destinationDir.create(recursive: true);
      }
      
      // Extraire l'archive
      await ZipFile.extractToDirectory(
        zipFile: archiveFile,
        destinationDir: destinationDir,
      );
      
      AppLogger.info('Extraction completed', data: {'path': sdkInfo.installPath});
    } catch (e) {
      AppLogger.error('Failed to extract Flutter SDK', error: e);
      rethrow;
    }
  }

  @override
  Future<void> updatePath(String flutterBinPath) async {
    AppLogger.info('Updating PATH to include Flutter', data: {'path': flutterBinPath});
    await localDataSource.updatePath(flutterBinPath);
  }

  @override
  Future<bool> isUpdateAvailable() async {
    try {
      if (!await isFlutterInstalled()) {
        return true; // Si Flutter n'est pas installé, une mise à jour est disponible
      }
      
      final currentVersion = await _getInstalledFlutterVersion();
      final latestVersion = await getLatestStableVersion();
      
      return currentVersion != latestVersion;
    } catch (e) {
      AppLogger.error('Failed to check for updates', error: e);
      return false;
    }
  }
  
  Future<bool> _isFlutterInUse() async {
    try {
      // Vérifier si des processus courants qui utilisent Flutter sont en cours
      final flutterPath = await findFlutterPath();
      if (flutterPath == null) return false;
      
      final platform = Platform.operatingSystem;
      
      if (platform == 'windows') {
        // Sur Windows, utiliser tasklist pour vérifier les processus
        final result = await Process.run('tasklist', ['/FI', 'IMAGENAME eq dart.exe'], runInShell: true);
        if (result.exitCode == 0 && result.stdout.toString().contains('dart.exe')) {
          return true;
        }
        
        // Vérifier aussi flutter.exe
        final flutterResult = await Process.run('tasklist', ['/FI', 'IMAGENAME eq flutter.exe'], runInShell: true);
        if (flutterResult.exitCode == 0 && flutterResult.stdout.toString().contains('flutter.exe')) {
          return true;
        }
      } else {
        // Sur Unix-like systems, utiliser pgrep ou ps
        final result = await Process.run('pgrep', ['-f', 'dart|flutter'], runInShell: true);
        if (result.exitCode == 0 && result.stdout.toString().trim().isNotEmpty) {
          return true;
        }
      }
      
      return false;
    } catch (e) {
      // En cas d'erreur de détection, on suppose que c'est OK (false)
      AppLogger.debug('Could not check if Flutter is in use: $e');
      return false;
    }
  }
  
  Future<String> _getInstalledFlutterVersion() async {
    try {
      final result = await Process.run(
        'flutter',
        ['--version'],
        runInShell: true,
      );
      
      if (result.exitCode != 0) {
        throw Exception('Failed to get Flutter version');
      }
      
      // Exemple de sortie: "Flutter 3.7.0 • channel stable • https://github.com/flutter/flutter.git"
      final versionLine = (result.stdout as String).split('\n').first;
      final versionMatch = RegExp(r'Flutter (\d+\.\d+\.\d+)').firstMatch(versionLine);
      
      if (versionMatch == null) {
        throw Exception('Failed to parse Flutter version');
      }
      
      return versionMatch.group(1)!;
    } catch (e) {
      AppLogger.error('Failed to get installed Flutter version', error: e);
      rethrow;
    }
  }

  @override
  Future<String> getDefaultInstallDirectory() async {
    return localDataSource.getDefaultInstallDirectory();
  }
}
