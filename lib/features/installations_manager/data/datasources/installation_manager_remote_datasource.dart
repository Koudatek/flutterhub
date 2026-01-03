import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutterhub/core/config/logger/logger_config.dart';

/// Remote data source for installation manager operations
abstract class InstallationManagerRemoteDataSource {
  /// Gets the latest stable Flutter version
  Future<String> getLatestStableVersion();
  
  /// Gets all available Flutter releases
  Future<List<Map<String, dynamic>>> getAllReleases();
  
  /// Gets the download URL for a specific Flutter version
  /// 
  /// [version] The version of Flutter to get the download URL for
  /// Returns the download URL as a String
  Future<String> getDownloadUrlForVersion(String version);
}

class InstallationManagerRemoteDataSourceImpl implements InstallationManagerRemoteDataSource {
  const InstallationManagerRemoteDataSourceImpl({
    required this.dio,
  });

  final Dio dio;

  @override
  Future<String> getDownloadUrlForVersion(String version) async {
    try {
      AppLogger.info('Getting download URL for Flutter version', data: {'version': version});
      
      final platform = Platform.operatingSystem;
      final releaseUrl = _getPlatformReleaseUrl(platform);
      
      final response = await dio.get(releaseUrl);
      
      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        final releases = data['releases'] as List;
        
        // Trouver la version spécifique
        final release = releases.firstWhere(
          (r) => (r['version'] as String?) == version,
          orElse: () => null,
        );
        
        if (release != null) {
          final archive = release['archive'] as String?;
          if (archive != null && archive.isNotEmpty) {
            return archive;
          }
          
          // Si pas d'URL directe, construire l'URL standard
          final osName = _getOsName(platform);
          return 'https://storage.googleapis.com/flutter_infra_release/releases/stable/$osName/flutter_${osName}_$version-stable.zip';
        }
      }
      
      throw Exception('Could not find download URL for Flutter $version');
    } catch (e) {
      AppLogger.error('Failed to get download URL for Flutter $version', error: e);
      rethrow;
    }
  }
  
  @override
  Future<String> getLatestStableVersion() async {
    try {
      AppLogger.info('Getting latest stable Flutter version');
      final platform = Platform.operatingSystem;
      final releaseUrl = _getPlatformReleaseUrl(platform);

      final response = await dio.get(releaseUrl);

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        final currentRelease = data['current_release'] as Map<String, dynamic>?;

        if (currentRelease != null) {
          final stableVersion = currentRelease['stable'] as String?;
          if (stableVersion != null && stableVersion.isNotEmpty) {
            // Find the version number from releases list
            final releases = data['releases'] as List?;
            if (releases != null) {
              final stableRelease = releases.firstWhere(
                (release) =>
                  (release['hash'] as String?) == stableVersion &&
                  (release['channel'] as String?) == 'stable',
                orElse: () => null,
              );

              if (stableRelease != null) {
                final version = stableRelease['version'] as String?;
                if (version == null) {
                  throw Exception('Version not found in stable release');
                }
                AppLogger.info('Latest Flutter stable version found', data: {'version': version, 'platform': platform});
                return version;
              }
            }

            // Fallback: return the hash if version not found (shouldn't happen)
            AppLogger.info('Latest Flutter stable version hash found', data: {'hash': stableVersion, 'platform': platform});
            return stableVersion;
          }
        }
      }

      throw Exception('Failed to fetch latest Flutter version from official API');
    } catch (e, stackTrace) {
      AppLogger.error('Error fetching latest Flutter version from official API', error: e, stackTrace: stackTrace);
      throw Exception('Failed to get latest stable version: $e');
    }
  }

  @override
  Future<List<Map<String, dynamic>>> getAllReleases() async {
    try {
      AppLogger.info('Getting all Flutter releases');
      final platform = Platform.operatingSystem;
      final releaseUrl = _getPlatformReleaseUrl(platform);

      final response = await dio.get(releaseUrl);

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        final releases = data['releases'] as List?;
        
        if (releases != null) {
          // Convert to List<Map<String, dynamic>> and filter stable releases only for official releases
          // But return all channels for pre-releases functionality
          final allReleases = releases
            .cast<Map<String, dynamic>>()
            .toList();
          
          AppLogger.info('All Flutter releases found', data: {'count': allReleases.length});
          return allReleases;
        }
      }

      throw Exception('Failed to fetch Flutter releases from official API');
    } catch (e, stackTrace) {
      AppLogger.error('Error fetching Flutter releases from official API', error: e, stackTrace: stackTrace);
      throw Exception('Failed to get all releases: $e');
    }
  }

  String _getPlatformReleaseUrl(String platform) {
    switch (platform) {
      case 'windows':
        return 'https://storage.googleapis.com/flutter_infra_release/releases/releases_windows.json';
      case 'macos':
        return 'https://storage.googleapis.com/flutter_infra_release/releases/releases_macos.json';
      case 'linux':
        return 'https://storage.googleapis.com/flutter_infra_release/releases/releases_linux.json';
      default:
        throw UnsupportedError('Unsupported platform: $platform');
    }
  }

  String _getOsName(String platform) {
    switch (platform) {
      case 'windows':
        return 'windows';
      case 'macos':
        return 'macos';
      case 'linux':
        return 'linux';
      default:
        throw UnsupportedError('Unsupported platform: $platform');
    }
  }
}
