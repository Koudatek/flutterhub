import 'dart:io';
import 'package:path/path.dart' as path;

/// Unix-specific PATH updater (Linux/macOS)
class UnixPathUpdater {
  /// Updates PATH by modifying shell configuration files
  Future<void> updatePath(String flutterBinPath) async {
    final shell = Platform.environment['SHELL'] ?? '/bin/bash';
    final home = Platform.environment['HOME'] ?? '';

    // Determine which config file to modify
    String configFile;
    if (shell.contains('zsh')) {
      configFile = path.join(home, '.zshrc');
    } else if (shell.contains('bash')) {
      configFile = path.join(home, '.bashrc');
    } else {
      // Default to .profile
      configFile = path.join(home, '.profile');
    }

    final config = File(configFile);
    String content = '';

    if (await config.exists()) {
      content = await config.readAsString();
    }

    // Check if Flutter PATH is already added
    if (content.contains('export PATH="\$PATH:$flutterBinPath"') ||
        content.contains("export PATH=\$PATH:$flutterBinPath")) {
      return;
    }

    // Add Flutter to PATH
    content += '\n# Flutter SDK\nexport PATH="\$PATH:$flutterBinPath"\n';

    await config.writeAsString(content);
  }
}
