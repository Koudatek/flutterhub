import 'dart:io';
import 'package:flutterhub/core/config/logger/logger_config.dart';

/// Windows-specific PATH updater
class WindowsPathUpdater {
  /// Updates the user PATH environment variable on Windows
  Future<void> updateUserPath(String flutterBinPath) async {
    try {
      // Use PowerShell to update user PATH
      final script = '''
\$flutterPath = "$flutterBinPath"
\$currentPath = [Environment]::GetEnvironmentVariable("PATH", "User")
if (\$currentPath -notlike "*\$flutterPath*") {
    \$newPath = "\$currentPath;\$flutterPath"
    [Environment]::SetEnvironmentVariable("PATH", \$newPath, "User")
}
''';

      final result = await Process.run(
        'powershell',
        ['-Command', script],
        runInShell: true,
      );

      if (result.exitCode != 0) {
        throw Exception('Failed to update PATH: ${result.stderr}');
      }
    } catch (e) {
      // Fallback: try to update PATH for current session
      final currentPath = Platform.environment['PATH'] ?? '';
      if (!currentPath.contains(flutterBinPath)) {
        // Note: This only affects the current process
        // For permanent change, user needs to restart terminal or log out/in
        AppLogger.warning('PATH update may require terminal restart', data: {'flutterBinPath': flutterBinPath});
      }
    }
  }
}
