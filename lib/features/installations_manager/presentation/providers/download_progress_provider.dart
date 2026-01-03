import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/installation_component.dart' as comp;

enum DownloadStatus {
  queued,
  downloading,
  installing,
  completed,
  failed,
}

class DownloadItem {
  final String name;
  final DownloadStatus status;
  final int progress; // 0-100
  final String speedText; // e.g., "2.8 MB/s"
  final String componentName; // for matching with InstallationComponent

  const DownloadItem({
    required this.name,
    required this.status,
    this.progress = 0,
    this.speedText = '',
    required this.componentName,
  });

  DownloadItem copyWith({
    String? name,
    DownloadStatus? status,
    int? progress,
    String? speedText,
    String? componentName,
  }) {
    return DownloadItem(
      name: name ?? this.name,
      status: status ?? this.status,
      progress: progress ?? this.progress,
      speedText: speedText ?? this.speedText,
      componentName: componentName ?? this.componentName,
    );
  }
}

class DownloadProgressState {
  final String flutterVersion;
  final String installationPath;
  final List<String> selectedPlatforms;
  final List<DownloadItem> downloadItems;
  final int completedCount;
  final int totalCount;
  final double overallProgress;
  final bool isDownloading;

  const DownloadProgressState({
    required this.flutterVersion,
    required this.installationPath,
    required this.selectedPlatforms,
    required this.downloadItems,
    required this.completedCount,
    required this.totalCount,
    required this.overallProgress,
    required this.isDownloading,
  });

  DownloadProgressState copyWith({
    String? flutterVersion,
    String? installationPath,
    List<String>? selectedPlatforms,
    List<DownloadItem>? downloadItems,
    int? completedCount,
    int? totalCount,
    double? overallProgress,
    bool? isDownloading,
  }) {
    return DownloadProgressState(
      flutterVersion: flutterVersion ?? this.flutterVersion,
      installationPath: installationPath ?? this.installationPath,
      selectedPlatforms: selectedPlatforms ?? this.selectedPlatforms,
      downloadItems: downloadItems ?? this.downloadItems,
      completedCount: completedCount ?? this.completedCount,
      totalCount: totalCount ?? this.totalCount,
      overallProgress: overallProgress ?? this.overallProgress,
      isDownloading: isDownloading ?? this.isDownloading,
    );
  }

  // Calculate completed count and overall progress
  factory DownloadProgressState.fromItems({
    required String flutterVersion,
    required String installationPath,
    required List<String> selectedPlatforms,
    required List<DownloadItem> downloadItems,
  }) {
    final completedCount = downloadItems.where((item) => item.status == DownloadStatus.completed).length;
    final totalCount = downloadItems.length;
    final overallProgress = totalCount > 0 ? completedCount / totalCount : 0.0;
    final isDownloading = downloadItems.any((item) =>
      item.status == DownloadStatus.downloading || item.status == DownloadStatus.installing);

    return DownloadProgressState(
      flutterVersion: flutterVersion,
      installationPath: installationPath,
      selectedPlatforms: selectedPlatforms,
      downloadItems: downloadItems,
      completedCount: completedCount,
      totalCount: totalCount,
      overallProgress: overallProgress,
      isDownloading: isDownloading,
    );
  }
}

class DownloadProgressNotifier extends Notifier<DownloadProgressState> {
  @override
  DownloadProgressState build() {
    // Initialize with sample data - in real app, this would come from navigation arguments
    return DownloadProgressState.fromItems(
      flutterVersion: '3.38.0',
      installationPath: Platform.isWindows ? 'C:\\flutter' : '${Platform.environment['HOME']}/flutter',
      selectedPlatforms: ['Web', 'Android', 'iOS', 'Windows', 'macOS', 'Linux'],
      downloadItems: _createInitialDownloadItems(),
    );
  }

  List<DownloadItem> _createInitialDownloadItems() {
    return [
      const DownloadItem(
        name: 'Git',
        status: DownloadStatus.completed,
        componentName: 'Git',
      ),
      const DownloadItem(
        name: 'Visual Studio Code',
        status: DownloadStatus.completed,
        componentName: 'Visual Studio Code',
      ),
      const DownloadItem(
        name: 'Flutter SDK',
        status: DownloadStatus.downloading,
        progress: 45,
        speedText: '2.8 MB/s',
        componentName: 'Flutter SDK',
      ),
      const DownloadItem(
        name: 'Android SDK Command Line Tools',
        status: DownloadStatus.downloading,
        progress: 26,
        speedText: '3.2 MB/s',
        componentName: 'Android SDK Command Line Tools',
      ),
      const DownloadItem(
        name: 'Android SDK Build Tools',
        status: DownloadStatus.downloading,
        progress: 5,
        speedText: '3.33 MB/s',
        componentName: 'Android SDK Build Tools',
      ),
      const DownloadItem(
        name: 'OpenJDK',
        status: DownloadStatus.queued,
        componentName: 'OpenJDK',
      ),
      const DownloadItem(
        name: 'CMake',
        status: DownloadStatus.queued,
        componentName: 'CMake',
      ),
      const DownloadItem(
        name: 'Android SDK Platforms 36',
        status: DownloadStatus.queued,
        componentName: 'Android SDK Platforms 36',
      ),
      const DownloadItem(
        name: 'Android SDK Platforms 35',
        status: DownloadStatus.queued,
        componentName: 'Android SDK Platforms 35',
      ),
      const DownloadItem(
        name: 'Ninja',
        status: DownloadStatus.queued,
        componentName: 'Ninja',
      ),
      const DownloadItem(
        name: 'Android Emulator',
        status: DownloadStatus.queued,
        componentName: 'Android Emulator',
      ),
      const DownloadItem(
        name: 'Android SDK Platform Tools',
        status: DownloadStatus.queued,
        componentName: 'Android SDK Platform Tools',
      ),
    ];
  }

  void updateDownloadProgress(String componentName, int progress, String speedText) {
    final updatedItems = state.downloadItems.map((item) {
      if (item.componentName == componentName) {
        return item.copyWith(
          progress: progress,
          speedText: speedText,
          status: progress >= 100 ? DownloadStatus.installing : DownloadStatus.downloading,
        );
      }
      return item;
    }).toList();

    state = DownloadProgressState.fromItems(
      flutterVersion: state.flutterVersion,
      installationPath: state.installationPath,
      selectedPlatforms: state.selectedPlatforms,
      downloadItems: updatedItems,
    );
  }

  void markAsCompleted(String componentName) {
    final updatedItems = state.downloadItems.map((item) {
      if (item.componentName == componentName) {
        return item.copyWith(
          status: DownloadStatus.completed,
          progress: 100,
        );
      }
      return item;
    }).toList();

    state = DownloadProgressState.fromItems(
      flutterVersion: state.flutterVersion,
      installationPath: state.installationPath,
      selectedPlatforms: state.selectedPlatforms,
      downloadItems: updatedItems,
    );
  }

  void markAsFailed(String componentName) {
    final updatedItems = state.downloadItems.map((item) {
      if (item.componentName == componentName) {
        return item.copyWith(status: DownloadStatus.failed);
      }
      return item;
    }).toList();

    state = DownloadProgressState.fromItems(
      flutterVersion: state.flutterVersion,
      installationPath: state.installationPath,
      selectedPlatforms: state.selectedPlatforms,
      downloadItems: updatedItems,
    );
  }

  void startDownload(String componentName) {
    final updatedItems = state.downloadItems.map((item) {
      if (item.componentName == componentName) {
        return item.copyWith(status: DownloadStatus.downloading);
      }
      return item;
    }).toList();

    state = DownloadProgressState.fromItems(
      flutterVersion: state.flutterVersion,
      installationPath: state.installationPath,
      selectedPlatforms: state.selectedPlatforms,
      downloadItems: updatedItems,
    );
  }

  // Initialize with actual data from the installation dialog
  void initializeDownload({
    required String flutterVersion,
    required String installationPath,
    required List<comp.TargetPlatform> selectedTargets,
    required List<comp.InstallationComponent> components,
  }) {
    final platforms = _convertTargetsToPlatforms(selectedTargets);
    final downloadItems = _createDownloadItemsFromComponents(components);

    state = DownloadProgressState.fromItems(
      flutterVersion: flutterVersion,
      installationPath: installationPath,
      selectedPlatforms: platforms,
      downloadItems: downloadItems,
    );
  }

  List<String> _convertTargetsToPlatforms(List<comp.TargetPlatform> targets) {
    return targets.map((target) {
      switch (target) {
        case comp.TargetPlatform.android:
          return 'Android';
        case comp.TargetPlatform.ios:
          return 'iOS';
        case comp.TargetPlatform.web:
          return 'Web';
        case comp.TargetPlatform.desktop:
          return 'Desktop';
      }
    }).toList();
  }

  List<DownloadItem> _createDownloadItemsFromComponents(List<comp.InstallationComponent> components) {
    return components.where((c) => c.isRequired || c.isInstalled).map((component) {
      return DownloadItem(
        name: component.name,
        status: component.isInstalled ? DownloadStatus.completed : DownloadStatus.queued,
        componentName: component.name,
      );
    }).toList();
  }
}

final downloadProgressProvider = NotifierProvider<DownloadProgressNotifier, DownloadProgressState>(
  DownloadProgressNotifier.new,
);
