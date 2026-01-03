import 'dart:io';
import 'package:flutterhub/core/config/logger/logger_config.dart';
import 'package:flutterhub/features/installations_manager/domain/entities/installer_entities.dart';
import 'package:flutter_archive/flutter_archive.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

/// Local data source for installation manager operations
abstract class InstallationManagerLocalDataSource {
  Future<List<FlutterVersion>> detectInstalledVersions();
  Future<String> getDefaultInstallDirectory();
  Future<void> updatePath(String flutterBinPath);
}

class InstallationManagerLocalDataSourceImpl implements InstallationManagerLocalDataSource {
  const InstallationManagerLocalDataSourceImpl();

  @override
  Future<List<FlutterVersion>> detectInstalledVersions() async {
    try {
      AppLogger.info('Detecting installed Flutter versions');

      // Check if flutter command is available
      final result = await Process.run('flutter', ['--version'], runInShell: true);

      if (result.exitCode == 0) {
        final output = result.stdout.toString();
        // Parse version from output like "Flutter 3.24.3 • channel stable • https://github.com/flutter/flutter.git"
        final versionMatch = RegExp(r'Flutter (\d+\.\d+\.\d+)').firstMatch(output);
        final channelMatch = RegExp(r'channel (\w+)').firstMatch(output);

        if (versionMatch != null) {
          final version = versionMatch.group(1)!;
          final channel = channelMatch?.group(1) ?? 'stable';

          // Try to find the actual Flutter installation path
          String? actualPath = await _findFlutterSdkPath();

          final versions = [
            FlutterVersion(
              name: version,
              path: actualPath ?? 'Unknown path',
              status: channel,
              isDefault: true,
              installedComponents: ['flutter_sdk'], // TODO: Detect real components
            ),
          ];

          AppLogger.info('Flutter versions detected', data: {
            'count': versions.length,
            'versions': versions.map((v) => {
              'name': v.name,
              'path': v.path,
              'isDefault': v.isDefault,
              'status': v.status,
            }).toList(),
          });

          return versions;
        }
      }

      AppLogger.info('No Flutter installation detected');
      return [];
    } catch (e, stackTrace) {
      AppLogger.error('Error detecting installed Flutter versions', error: e, stackTrace: stackTrace);
      return [];
    }
  }

  @override
  Future<String> getDefaultInstallDirectory() async {
    final platform = Platform.operatingSystem;
    final home = Platform.environment['HOME'] ?? Platform.environment['USERPROFILE'] ?? '';

    switch (platform) {
      case 'windows':
        return '$home\\development\\flutter';
      case 'macos':
        return '$home/development/flutter';
      case 'linux':
      default:
        return '$home/development/flutter';
    }
  }

  @override
  Future<void> updatePath(String flutterBinPath) async {
    try {
      AppLogger.info('Updating PATH to include Flutter', data: {'path': flutterBinPath});
      
      final platform = Platform.operatingSystem;
      
      if (platform == 'windows') {
        // On Windows, update the user PATH environment variable
        final result = await Process.run(
          'setx',
          ['PATH', '%PATH%;$flutterBinPath'],
          runInShell: true,
        );
        
        if (result.exitCode != 0) {
          AppLogger.warning('Failed to update PATH via setx', error: result.stderr);
        }
      } else {
        // On Unix-like systems, update ~/.bashrc or ~/.zshrc
        final shellRcFiles = ['.bashrc', '.zshrc', '.profile'];
        final home = Platform.environment['HOME'] ?? '';
        
        for (final rcFile in shellRcFiles) {
          final rcPath = '$home/$rcFile';
          final rcFileObj = File(rcPath);
          
          if (await rcFileObj.exists()) {
            final content = await rcFileObj.readAsString();
            
            // Check if PATH is already updated
            if (!content.contains('export PATH=\"\/bin:\$PATH\"')) {
              await rcFileObj.writeAsString(
                '\n# Added by FlutterHub\nexport PATH=\"$flutterBinPath:\$PATH\"\n',
                mode: FileMode.append,
              );
              AppLogger.info('Updated PATH in $rcFile');
            }
          }
        }
      }
      
      AppLogger.info('PATH update completed');
    } catch (e) {
      AppLogger.error('Failed to update PATH', error: e);
      rethrow;
    }
  }

  Future<String?> _findFlutterSdkPath() async {
    try {
      // Try different commands based on platform
      final platform = Platform.operatingSystem;
      ProcessResult pathResult;

      if (platform == 'windows') {
        // On Windows, use 'where' instead of 'which'
        pathResult = await Process.run('where', ['flutter'], runInShell: true);
      } else {
        // On Unix-like systems, use 'which'
        pathResult = await Process.run('which', ['flutter'], runInShell: true);
      }

      if (pathResult.exitCode == 0) {
        final whichPath = pathResult.stdout.toString().trim().split('\n').first; // Take first line if multiple
        if (whichPath.isNotEmpty && whichPath != 'flutter') {
          // Remove '/bin/flutter' from the path to get the SDK root
          final flutterBinPath = platform == 'windows' ? r'\bin\flutter' : '/bin/flutter';
          if (whichPath.contains(flutterBinPath)) {
            final sdkPath = whichPath.replaceAll(flutterBinPath, '');
            if (await _directoryExists(sdkPath)) {
              return sdkPath;
            }
          }
          // If the replacement didn't work, try to find the flutter directory by going up
          final flutterDir = await _findFlutterDirectory(whichPath);
          if (flutterDir != null) {
            return flutterDir;
          }
        }
      }

      // Try common installation paths
      final commonPaths = await _getCommonFlutterPaths();
      for (final path in commonPaths) {
        if (await _directoryExists(path)) {
          return path;
        }
      }

      AppLogger.warning('Could not determine exact Flutter SDK path');
      return null;
    } catch (e) {
      AppLogger.error('Error finding Flutter SDK path', error: e);
      return null;
    }
  }

  Future<String?> _findFlutterDirectory(String executablePath) async {
    try {
      // Start from the executable path and go up until we find a directory containing 'flutter'
      var currentDir = Directory(executablePath).parent;

      for (int i = 0; i < 10; i++) { // Limit search to avoid infinite loop
        if (await _directoryExists(currentDir.path) &&
            await _containsFlutterFiles(currentDir.path)) {
          return currentDir.path;
        }
        currentDir = currentDir.parent;
        if (currentDir.path == currentDir.parent.path) break; // Reached root
      }
    } catch (e) {
      // Ignore errors in directory traversal
    }
    return null;
  }

  Future<List<String>> _getCommonFlutterPaths() async {
    final platform = Platform.operatingSystem;
    final home = Platform.environment['HOME'] ?? Platform.environment['USERPROFILE'] ?? '';

    switch (platform) {
      case 'windows':
        return [
          r'C:\flutter',
          r'C:\src\flutter',
          r'C:\tools\flutter',
          '$home\\flutter',
          '$home\\development\\flutter',
        ];
      case 'macos':
        return [
          '/usr/local/flutter',
          '/opt/flutter',
          '$home/flutter',
          '$home/development/flutter',
        ];
      case 'linux':
      default:
        return [
          '/usr/local/flutter',
          '/opt/flutter',
          '/home/flutter',
          '$home/flutter',
          '$home/development/flutter',
          '$home/Android/flutter',
        ];
    }
  }

  Future<bool> _directoryExists(String path) async {
    try {
      return await Directory(path).exists();
    } catch (e) {
      return false;
    }
  }

  Future<bool> _containsFlutterFiles(String path) async {
    try {
      final dir = Directory(path);
      final files = await dir.list().toList();
      return files.any((entity) =>
        entity is File && (entity.path.endsWith('pubspec.yaml') || entity.path.endsWith('flutter') || entity.path.endsWith('flutter.exe'))
      );
    } catch (e) {
      return false;
    }
  }
}
