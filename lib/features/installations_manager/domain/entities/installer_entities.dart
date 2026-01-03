import 'package:flutter/cupertino.dart';
import 'package:equatable/equatable.dart';

/// Représente un composant à installer
class InstallationComponent {
  const InstallationComponent({
    required this.id,
    required this.name,
    required this.description,
    required this.category,
    required this.priority,
    this.downloadUrl,
    this.installPath,
    this.environmentVariables = const {},
    this.dependencies = const [],
    this.verificationCommand,
    this.postInstallCommands = const [],
    this.isOptional = false,
    this.estimatedSize,
    this.licenseRequired = false,
  });

  final String id;
  final String name;
  final String description;
  final ComponentCategory category;
  final int priority; // 1 = essentiel, 2 = important, 3 = optionnel
  final String? downloadUrl;
  final String? installPath;
  final Map<String, String> environmentVariables;
  final List<String> dependencies; // IDs des composants requis
  final String? verificationCommand;
  final List<String> postInstallCommands;
  final bool isOptional;
  final String? estimatedSize;
  final bool licenseRequired;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is InstallationComponent && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'InstallationComponent(id: $id, name: $name, category: $category, priority: $priority)';
  }
}

/// Catégories de composants
enum ComponentCategory {
  flutter('Flutter'),
  android('Android'),
  ios('iOS'),
  web('Web'),
  desktop('Desktop'),
  tools('Outils'),
  ide('IDE');

  const ComponentCategory(this.displayName);
  final String displayName;
}

/// État d'installation d'un composant
enum ComponentInstallStatus {
  notStarted('Non commencé'),
  downloading('Téléchargement'),
  extracting('Extraction'),
  installing('Installation'),
  configuring('Configuration'),
  verifying('Vérification'),
  completed('Terminé'),
  failed('Échec');

  const ComponentInstallStatus(this.displayName);
  final String displayName;
}

/// Résultat de l'analyse d'installation
class InstallationAnalysis {
  const InstallationAnalysis({
    required this.selectedPlatforms,
    required this.requiredComponents,
    required this.optionalComponents,
    required this.estimatedTotalSize,
    required this.estimatedTime,
    required this.hasLicensesToAccept,
  });

  final List<String> selectedPlatforms;
  final List<InstallationComponent> requiredComponents;
  final List<InstallationComponent> optionalComponents;
  final String? estimatedTotalSize;
  final Duration? estimatedTime;
  final bool hasLicensesToAccept;

  List<InstallationComponent> get allComponents => [
        ...requiredComponents,
        ...optionalComponents,
      ];

  @override
  String toString() {
    return 'InstallationAnalysis(platforms: $selectedPlatforms, required: ${requiredComponents.length}, optional: ${optionalComponents.length})';
  }
}

/// Informations détaillées sur un outil installé
class ToolItem {
  const ToolItem({
    required this.name,
    required this.status,
    required this.path,
    required this.icon,
    required this.iconColor,
    required this.platforms,
  });

  final String name;
  final String status;
  final String path;
  final IconData icon;
  final Color iconColor;
  final List<String> platforms;
}

/// Représente une version de Flutter installée
class FlutterVersion {
  const FlutterVersion({
    required this.name,
    required this.path,
    required this.status,
    required this.isDefault,
    this.installedComponents = const [],
  });

  final String name;
  final String path;
  final String status;
  final bool isDefault;
  final List<String> installedComponents;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is FlutterVersion && other.name == name && other.path == path;
  }

  @override
  int get hashCode => name.hashCode ^ path.hashCode;

  @override
  String toString() {
      return 'FlutterVersion(name: $name, path: $path, status: $status, isDefault: $isDefault)';
  }
}

/// Représente les informations d'une version de Flutter à installer
class FlutterSdkInfo with EquatableMixin {
  const FlutterSdkInfo({
    required this.version,
    required this.downloadUrl,
    required this.installPath,
    this.archivePath = '',
  });

  final String version;
  final String downloadUrl;
  final String installPath;
  final String archivePath;

  /// Crée une copie avec les champs mis à jour
  FlutterSdkInfo copyWith({
    String? version,
    String? downloadUrl,
    String? installPath,
    String? archivePath,
  }) {
    return FlutterSdkInfo(
      version: version ?? this.version,
      downloadUrl: downloadUrl ?? this.downloadUrl,
      installPath: installPath ?? this.installPath,
      archivePath: archivePath ?? this.archivePath,
    );
  }

  @override
  List<Object?> get props => [version, downloadUrl, installPath, archivePath];
}

/// État d'installation de Flutter
enum InstallationStatus {
  notStarted,
  downloading,
  extracting,
  updatingPath,
  runningDoctor,
  completed,
  failed,
}

/// Résultat de la commande flutter doctor
class DoctorResult with EquatableMixin {
  const DoctorResult({
    required this.output,
    required this.issues,
    required this.hasIssues,
  });

  /// Sortie brute de la commande
  final String output;
  
  /// Liste des problèmes détectés
  final List<String> issues;
  
  /// Indique si des problèmes ont été détectés
  final bool hasIssues;

  @override
  List<Object?> get props => [output, issues, hasIssues];

  @override
  String toString() => 'DoctorResult(hasIssues: $hasIssues, issues: ${issues.length})';
}

/// Résultat d'une opération d'installation/mise à jour
class InstallationResult with EquatableMixin {
  const InstallationResult({
    required this.success,
    this.message = '',
    this.details,
  });

  /// Indique si l'opération a réussi
  final bool success;
  
  /// Message décrivant le résultat
  final String message;
  
  /// Détails supplémentaires sur le résultat
  final Map<String, dynamic>? details;

  @override
  List<Object?> get props => [success, message, details];

  @override
  String toString() => 'InstallationResult(success: $success, message: $message)';
}
