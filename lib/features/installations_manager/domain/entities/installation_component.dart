enum TargetPlatform { android, ios, web, desktop }

class InstallationComponent {
  final String name;
  final String version;
  final String downloadSize;
  final String diskSize;
  final bool isInstalled;
  final bool isRequired;
  final List<TargetPlatform> supportedTargets;
  final String? checkCommand; // Command to verify installation
  final String? iconName;

  const InstallationComponent({
    required this.name,
    required this.version,
    required this.downloadSize,
    required this.diskSize,
    this.isInstalled = false,
    this.isRequired = false,
    this.supportedTargets = const [],
    this.checkCommand,
    this.iconName,
  });

  InstallationComponent copyWith({
    String? name,
    String? version,
    String? downloadSize,
    String? diskSize,
    bool? isInstalled,
    bool? isRequired,
    List<TargetPlatform>? supportedTargets,
    String? checkCommand,
    String? iconName,
  }) {
    return InstallationComponent(
      name: name ?? this.name,
      version: version ?? this.version,
      downloadSize: downloadSize ?? this.downloadSize,
      diskSize: diskSize ?? this.diskSize,
      isInstalled: isInstalled ?? this.isInstalled,
      isRequired: isRequired ?? this.isRequired,
      supportedTargets: supportedTargets ?? this.supportedTargets,
      checkCommand: checkCommand ?? this.checkCommand,
      iconName: iconName ?? this.iconName,
    );
  }

  bool isSupportedOnCurrentPlatform(String os) {
    // Platform-specific filtering
    if (name == 'Xcode' && os != 'macOS') return false;
    if (name == 'Android Studio' && supportedTargets.contains(TargetPlatform.android)) return true;
    return true; // Most components are cross-platform
  }
}
