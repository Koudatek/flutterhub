import 'dart:io';
import 'windows_path_updater.dart';
import 'unix_path_updater.dart';

/// Platform-specific PATH updater
class PlatformPathUpdater {
  /// Updates the system PATH for the current platform
  Future<void> updatePath(String flutterBinPath) async {
    if (Platform.isWindows) {
      final updater = WindowsPathUpdater();
      await updater.updateUserPath(flutterBinPath);
    } else if (Platform.isLinux || Platform.isMacOS) {
      final updater = UnixPathUpdater();
      await updater.updatePath(flutterBinPath);
    } else {
      throw UnsupportedError('Unsupported platform: ${Platform.operatingSystem}');
    }
  }
}
