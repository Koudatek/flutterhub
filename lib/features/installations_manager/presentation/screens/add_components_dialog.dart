import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

/// Separate widget for the Add Components dialog
class AddComponentsDialog extends ConsumerStatefulWidget {
  const AddComponentsDialog({super.key, required this.version, required this.onInstall});

  final String version;
  final Future<void> Function(List<String> selectedComponents) onInstall;

  @override
  ConsumerState<AddComponentsDialog> createState() => _AddComponentsDialogState();
}

class _AddComponentsDialogState extends ConsumerState<AddComponentsDialog> {
  // Track selected components
  final Map<String, bool> _selectedComponents = {
    'android_sdk': true,
    'openjdk': true,
    'ios_support': false,
    'chrome': true,
    'windows_desktop': true,
    'linux_desktop': true,
  };

  // Component definitions with sizes
  final Map<String, Map<String, dynamic>> _componentDetails = {
    'android_sdk': {
      'name': 'Android SDK & Build Tools',
      'downloadSize': '1.26 GB',
      'diskSize': '2.99 GB',
      'icon': Icons.android,
      'iconColor': const Color(0xFF3DDC84),
    },
    'openjdk': {
      'name': 'OpenJDK (Zulu)',
      'downloadSize': '112 MB',
      'diskSize': '227 MB',
      'icon': Icons.code,
      'iconColor': const Color(0xFFED8B00),
    },
    'ios_support': {
      'name': 'iOS Build Support (macOS only)',
      'downloadSize': '252 MB',
      'diskSize': '1.14 GB',
      'icon': Icons.apple,
      'iconColor': Colors.grey,
    },
    'chrome': {
      'name': 'Chrome (for Web debugging)',
      'downloadSize': '95 MB',
      'diskSize': '280 MB',
      'icon': Icons.language,
      'iconColor': const Color(0xFF4285F4),
    },
    'windows_desktop': {
      'name': 'Windows Desktop Support',
      'downloadSize': '180 MB',
      'diskSize': '620 MB',
      'icon': Icons.window,
      'iconColor': const Color(0xFF0078D4),
    },
    'linux_desktop': {
      'name': 'Linux Desktop Support',
      'downloadSize': '65 MB',
      'diskSize': '263 MB',
      'icon': Icons.desktop_windows,
      'iconColor': const Color(0xFFFCC624),
    },
  };

  // Installed dev tools (hardcoded for now)
  final List<Map<String, String>> _installedDevTools = [
    {'name': 'Android Studio Koala 2024.1.1', 'size': '1.59 GB'},
    {'name': 'Visual Studio Code', 'size': '280 MB'},
    {'name': 'Git for Windows/Linux/macOS', 'size': '45 MB'},
  ];

  @override
  Widget build(BuildContext context) {
    final hasSelection = _selectedComponents.values.any((selected) => selected);

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
                Row(
                  children: [
                    Text('Install Flutter ${widget.version}',
                      style: GoogleFonts.inter(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      )),
                    const SizedBox(width: 12),
                    // LTS badge if applicable
                    if (_isLTSVersion(widget.version.split(' ').length > 1 ? widget.version.split(' ')[1] : widget.version))
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFF424242),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text('LTS', style: GoogleFonts.inter(
                          color: const Color(0xFF64B5F6),
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        )),
                      ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 8),
            // Disk space info
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                'Required: 7.25 GB    Available: 143.75 GB',
                style: GoogleFonts.inter(
                  color: const Color(0xFFBBBBBB),
                  fontSize: 12,
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Content
            Expanded(
              child: ListView(
                children: [
                  // Dev tools section
                  _buildSectionTitle('Dev tools'),
                  ..._installedDevTools.map((tool) => _buildInstalledTool(tool['name']!, tool['size']!)),
                  const SizedBox(height: 24),

                  // Platforms & Components section
                  _buildSectionTitle('Platforms & Components'),
                  ..._componentDetails.entries.map((entry) =>
                    _buildComponentRow(entry.key, entry.value)),
                ],
              ),
            ),

            const SizedBox(height: 24),
            // Bottom buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFFBBBBBB),
                  ),
                  child: Text('Back', style: GoogleFonts.inter(fontSize: 14)),
                ),
                ElevatedButton(
                  onPressed: hasSelection ? _handleInstall : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0078D4),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    disabledBackgroundColor: const Color(0xFF424242),
                  ),
                  child: Text('Install', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w500)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: GoogleFonts.inter(
          color: const Color(0xFF0078D4),
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildInstalledTool(String name, String size) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF2A2A2A),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(name, style: GoogleFonts.inter(
            color: Colors.white,
            fontSize: 14,
          )),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFF2D5016),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text('Installed', style: GoogleFonts.inter(
                  color: const Color(0xFF00FF00),
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                )),
              ),
              const SizedBox(width: 16),
              Text(size, style: GoogleFonts.inter(
                color: const Color(0xFF888888),
                fontSize: 12,
              )),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildComponentRow(String key, Map<String, dynamic> details) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: CheckboxListTile(
        value: _selectedComponents[key],
        onChanged: (value) {
          setState(() {
            _selectedComponents[key] = value ?? false;
          });
        },
        title: Text(
          details['name'],
          style: GoogleFonts.inter(
            color: Colors.white,
            fontSize: 14,
          ),
        ),
        secondary: Icon(
          details['icon'],
          color: details['iconColor'],
          size: 24,
        ),
        subtitle: Row(
          children: [
            Text(
              'Download: ${details['downloadSize']}',
              style: GoogleFonts.inter(
                color: const Color(0xFF888888),
                fontSize: 12,
              ),
            ),
            const SizedBox(width: 24),
            Text(
              'Disk: ${details['diskSize']}',
              style: GoogleFonts.inter(
                color: const Color(0xFF888888),
                fontSize: 12,
              ),
            ),
          ],
        ),
        controlAffinity: ListTileControlAffinity.leading,
        activeColor: const Color(0xFF0078D4),
        checkColor: Colors.white,
        tileColor: const Color(0xFF252525),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
      ),
    );
  }

  void _handleInstall() {
    final selectedComponents = _selectedComponents.entries
        .where((entry) => entry.value)
        .map((entry) => entry.key)
        .toList();

    Navigator.pop(context); // Close components dialog
    widget.onInstall(selectedComponents);
  }

  bool _isLTSVersion(String version) {
    // Simple heuristic for LTS versions
    final parts = version.split('.');
    if (parts.length >= 2) {
      final minor = int.tryParse(parts[1]) ?? 0;
      return [10, 13, 16, 22, 24].contains(minor);
    }
    return false;
  }
}
