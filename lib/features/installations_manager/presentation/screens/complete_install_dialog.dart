import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:file_picker/file_picker.dart';
import '../../domain/entities/installation_component.dart' as comp;
import '../providers/installation_manager_providers.dart';
import 'installs_in_progress_page.dart';
import '../providers/download_progress_provider.dart';

void showCompleteInstallDialog(BuildContext context, String flutterVersion) {
  showDialog(
    context: context,
    builder: (context) => CompleteInstallDialog(flutterVersion: flutterVersion),
  );
}

class CompleteInstallDialog extends ConsumerStatefulWidget {
  const CompleteInstallDialog({super.key, required this.flutterVersion});

  final String flutterVersion;

  @override
  ConsumerState<CompleteInstallDialog> createState() => _CompleteInstallDialogState();
}

class _CompleteInstallDialogState extends ConsumerState<CompleteInstallDialog> {
  final Set<comp.TargetPlatform> _selectedTargets = {};

  @override
  void initState() {
    super.initState();
    // Check installation status and fetch latest versions when dialog opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(installProvider.notifier).checkInstallationStatus();
      ref.read(installProvider.notifier).fetchLatestVersions();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(installProvider);
    final os = state['os'] ?? 'Unknown';
    final components = state['components'] as List<comp.InstallationComponent>? ?? [];
    final targets = state['targets'] as Map<comp.TargetPlatform, bool>? ?? {};
    final isLoadingVersions = state['isLoadingVersions'] ?? false;
    final downloadPath = state['downloadPath'] ?? '';
    final isInstallingFlutter = state['isInstallingFlutter'] ?? false;

    // Calculate total sizes
    final totalDownloadSize = _calculateTotalSize(components.where((c) => c.isRequired || c.isInstalled).toList(), true);
    final totalDiskSize = _calculateTotalSize(components.where((c) => c.isRequired || c.isInstalled).toList(), false);

    return Dialog(
      backgroundColor: const Color(0xFF1E1E1E),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        width: 900,
        height: 700,
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Install Flutter ${widget.flutterVersion}',
                      style: GoogleFonts.inter(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      )),
                    const SizedBox(height: 4),
                    Text('OS détecté : $os | Total requis : $totalDownloadSize download, $totalDiskSize disque',
                      style: GoogleFonts.inter(
                        color: const Color(0xFFBBBBBB),
                        fontSize: 12,
                      )),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Target Platform Selection
            Text('Sélectionnez vos cibles de développement :',
              style: GoogleFonts.inter(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              )),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 8,
              children: comp.TargetPlatform.values.map((target) {
                final isSelected = targets[target] ?? false;
                final isDisabled = (target == comp.TargetPlatform.ios && os != 'macOS');

                return FilterChip(
                  label: Text(_getTargetDisplayName(target),
                    style: GoogleFonts.inter(
                      color: isSelected ? Colors.white : const Color(0xFFBBBBBB),
                      fontSize: 12,
                    )),
                  selected: isSelected,
                  onSelected: isDisabled ? null : (selected) {
                    setState(() {
                      if (selected) {
                        _selectedTargets.add(target);
                      } else {
                        _selectedTargets.remove(target);
                      }
                    });
                    ref.read(installProvider.notifier).updateTargets(_selectedTargets);
                  },
                  backgroundColor: const Color(0xFF2A2A2A),
                  selectedColor: const Color(0xFF0078D4),
                  checkmarkColor: Colors.white,
                  disabledColor: const Color(0xFF424242),
                );
              }).toList(),
            ),

            const SizedBox(height: 24),

            // Download Path Selection
            Text('Répertoire d\'installation de Flutter SDK :',
              style: GoogleFonts.inter(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              )),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF252525),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: TextEditingController(text: downloadPath),
                      style: GoogleFonts.inter(
                        color: Colors.white,
                        fontSize: 14,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Chemin d\'installation de Flutter...',
                        hintStyle: GoogleFonts.inter(
                          color: const Color(0xFF888888),
                          fontSize: 14,
                        ),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.zero,
                      ),
                      onChanged: (value) {
                        ref.read(installProvider.notifier).updateDownloadPath(value);
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    onPressed: () => _selectDownloadDirectory(context),
                    icon: const Icon(Icons.folder_open, size: 16),
                    label: Text('Parcourir', style: GoogleFonts.inter(fontSize: 12)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0078D4),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Components List
            Text('Composants à installer (vérifiés automatiquement) :',
              style: GoogleFonts.inter(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              )),
            const SizedBox(height: 12),

            Expanded(
              child: ListView.builder(
                itemCount: components.length,
                itemBuilder: (context, index) {
                  final component = components[index];
                  final isRequired = component.isRequired;
                  final isInstalled = component.isInstalled;

                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF252525),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: isRequired ? const Color(0xFF0078D4) : Colors.transparent,
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        // Icon
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: _getComponentIconColor(component.name),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            _getComponentIcon(component.name),
                            color: Colors.white,
                            size: 20,
                          ),
                        ),

                        const SizedBox(width: 12),

                        // Component Info
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text('${component.name} ${component.version}',
                                    style: GoogleFonts.inter(
                                      color: Colors.white,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                    )),
                                  if (isLoadingVersions) ...[
                                    const SizedBox(width: 8),
                                    const SizedBox(
                                      width: 12,
                                      height: 12,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white54),
                                      ),
                                    ),
                                  ],
                                  if (isRequired) ...[
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF0078D4),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text('Requis',
                                        style: GoogleFonts.inter(
                                          color: Colors.white,
                                          fontSize: 10,
                                          fontWeight: FontWeight.w500,
                                        )),
                                    ),
                                  ],
                                  if (isInstalled) ...[
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF2D5016),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text('Installé',
                                        style: GoogleFonts.inter(
                                          color: const Color(0xFF00FF00),
                                          fontSize: 10,
                                          fontWeight: FontWeight.w500,
                                        )),
                                    ),
                                  ],
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text('Download: ${component.downloadSize} | Disk: ${component.diskSize}',
                                style: GoogleFonts.inter(
                                  color: const Color(0xFF888888),
                                  fontSize: 12,
                                )),
                            ],
                          ),
                        ),

                        // Checkbox (disabled if installed or required)
                        if (!isInstalled)
                          Checkbox(
                            value: isRequired,
                            onChanged: null, // Auto-managed
                            activeColor: const Color(0xFF0078D4),
                            checkColor: Colors.white,
                          ),
                      ],
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 24),

            // Bottom buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton.icon(
                  onPressed: () => ref.read(installProvider.notifier).refreshVersions(),
                  icon: const Icon(Icons.refresh, size: 16),
                  label: Text('Refresh', style: GoogleFonts.inter(fontSize: 14)),
                  style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFFBBBBBB),
                  ),
                ),
                Row(
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      style: TextButton.styleFrom(
                        foregroundColor: const Color(0xFFBBBBBB),
                      ),
                      child: Text('Cancel', style: GoogleFonts.inter(fontSize: 14)),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      onPressed: isInstallingFlutter ? null : _startInstallation,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0078D4),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        disabledBackgroundColor: const Color(0xFF424242),
                      ),
                      child: isInstallingFlutter
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : Text('Install Flutter SDK', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w500)),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _getTargetDisplayName(comp.TargetPlatform target) {
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
  }

  IconData _getComponentIcon(String name) {
    switch (name) {
      case 'Git':
        return Icons.account_tree;
      case 'Visual Studio Code':
        return Icons.code;
      case 'Flutter SDK':
        return Icons.flutter_dash;
      case 'Android Studio':
        return Icons.android;
      case 'Xcode':
        return Icons.apple;
      case 'Google Chrome':
        return Icons.public; // Web browser icon
      case 'Visual Studio':
        return Icons.developer_mode; // IDE icon
      case 'Clang':
        return Icons.memory; // Compiler icon
      default:
        return Icons.settings;
    }
  }

  Color _getComponentIconColor(String name) {
    switch (name) {
      case 'Git':
        return const Color(0xFFF05032);
      case 'Visual Studio Code':
        return const Color(0xFF007ACC);
      case 'Flutter SDK':
        return const Color(0xFF02569B);
      case 'Android Studio':
        return const Color(0xFF3DDC84);
      case 'Xcode':
        return const Color(0xFF000000);
      case 'Google Chrome':
        return const Color(0xFF4285F4); // Chrome blue
      case 'Visual Studio':
        return const Color(0xFF68217A); // Visual Studio purple
      case 'Clang':
        return const Color(0xFF0066CC); // Clang blue
      default:
        return const Color(0xFF0078D4);
    }
  }

  String _calculateTotalSize(List<comp.InstallationComponent> components, bool isDownload) {
    // Simple estimation - in real implementation, parse sizes properly
    double totalMB = 0;
    for (final component in components) {
      final sizeStr = isDownload ? component.downloadSize : component.diskSize;
      if (sizeStr.contains('GB')) {
        final gb = double.tryParse(sizeStr.replaceAll('~', '').replaceAll(' GB', '').replaceAll('<', '')) ?? 0;
        totalMB += gb * 1024;
      } else if (sizeStr.contains('MB')) {
        final mb = double.tryParse(sizeStr.replaceAll('~', '').replaceAll(' MB', '').replaceAll('<', '')) ?? 0;
        totalMB += mb;
      }
    }

    if (totalMB >= 1024) {
      return '~${(totalMB / 1024).round()} GB';
    } else {
      return '~${totalMB.round()} MB';
    }
  }

  Future<void> _selectDownloadDirectory(BuildContext context) async {
    try {
      String? selectedDirectory = await FilePicker.platform.getDirectoryPath();
      
      if (selectedDirectory != null) {
        ref.read(installProvider.notifier).updateDownloadPath(selectedDirectory);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur lors de la sélection du répertoire: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _startInstallation() async {
    try {
      // Initialize download progress provider with current data
      final state = ref.read(installProvider);
      final components = state['components'] as List<comp.InstallationComponent>;
      final downloadPath = state['downloadPath'] as String;
      final targets = state['targets'] as Map<comp.TargetPlatform, bool>;

      final selectedTargets = targets.entries
          .where((entry) => entry.value)
          .map((entry) => entry.key)
          .toList();

      ref.read(downloadProgressProvider.notifier).initializeDownload(
        flutterVersion: widget.flutterVersion,
        installationPath: downloadPath,
        selectedTargets: selectedTargets,
        components: components,
      );

      // Close dialog
      Navigator.pop(context);

      // Navigate to installs page
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const InstallsInProgressPage(),
        ),
      );

      // Start the actual installation in the background
      // For now, just simulate some progress updates
      _simulateInstallationProgress();

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur lors du démarrage de l\'installation: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _simulateInstallationProgress() async {
    final downloadNotifier = ref.read(downloadProgressProvider.notifier);

    // Simulate Flutter SDK download
    await Future.delayed(const Duration(seconds: 1));
    downloadNotifier.startDownload('Flutter SDK');

    for (int i = 0; i <= 100; i += 5) {
      await Future.delayed(const Duration(milliseconds: 200));
      downloadNotifier.updateDownloadProgress('Flutter SDK', i, '2.8 MB/s');
    }

    downloadNotifier.markAsCompleted('Flutter SDK');

    // Simulate other components
    final componentsToDownload = ['Android SDK Command Line Tools', 'Android SDK Build Tools'];

    for (final component in componentsToDownload) {
      await Future.delayed(const Duration(seconds: 1));
      downloadNotifier.startDownload(component);

      for (int i = 0; i <= 100; i += 10) {
        await Future.delayed(const Duration(milliseconds: 150));
        downloadNotifier.updateDownloadProgress(component, i, '${(2.5 + (i * 0.02)).toStringAsFixed(1)} MB/s');
      }

      downloadNotifier.markAsCompleted(component);
    }
  }
}
