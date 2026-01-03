import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutterhub/core/widgets/app_sidebar.dart';
import 'package:google_fonts/google_fonts.dart';

import '../providers/download_progress_provider.dart';

class InstallsInProgressPage extends ConsumerWidget {
  const InstallsInProgressPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final downloadState = ref.watch(downloadProgressProvider);

    return Row(
      children: [
        // Sidebar
        const AppSidebar(selectedIndex: 1),

        Expanded(
          child: Container(
            color: const Color(0xFF121212),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    'Installs',
                    style: GoogleFonts.inter(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),

                // Tabs
                Container(
                  height: 48,
                  decoration: const BoxDecoration(
                    border: Border(
                      bottom: BorderSide(color: Color(0xFF333333), width: 1),
                    ),
                  ),
                  child: Row(
                    children: [
                      _buildTab('All', isSelected: true),
                      _buildTab('Official releases', isSelected: false),
                      _buildTab('Pre-releases', isSelected: false),
                    ],
                  ),
                ),

                Expanded(
                  child: Row(
                    children: [
                      // Main content - Installation cards
                      Expanded(
                        flex: 3,
                        child: ListView(
                          padding: const EdgeInsets.all(24),
                          children: [
                            _buildInstallationCard(
                              version: 'Flutter ${downloadState.flutterVersion} (Stable)',
                              path: downloadState.installationPath,
                              platforms: downloadState.selectedPlatforms,
                              progressText: 'In progress (${downloadState.completedCount} of ${downloadState.totalCount} completed)',
                              progress: downloadState.overallProgress,
                            ),
                          ],
                        ),
                      ),

                      // Right panel - Detailed download list
                      Container(
                        width: 400,
                        color: const Color(0xFF2A2A2A),
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'In progress (${downloadState.completedCount} of ${downloadState.totalCount} completed)',
                              style: GoogleFonts.inter(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Expanded(
                              child: ListView(
                                children: downloadState.downloadItems.map((item) => _buildDownloadItem(item)).toList(),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTab(String text, {required bool isSelected}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: isSelected ? const Color(0xFF0078D4) : Colors.transparent,
            width: 2,
          ),
        ),
      ),
      child: Text(
        text,
        style: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: isSelected ? Colors.white : const Color(0xFFBBBBBB),
        ),
      ),
    );
  }

  Widget _buildInstallationCard({
    required String version,
    required String path,
    required List<String> platforms,
    required String progressText,
    required double progress,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF252525),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: const Color(0xFF02569B),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.flutter_dash,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Text(
                version,
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF2D5016),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Supported',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF00FF00),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            path,
            style: GoogleFonts.inter(
              fontSize: 14,
              color: const Color(0xFFBBBBBB),
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: platforms.map((platform) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF333333),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                platform,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: const Color(0xFFCCCCCC),
                ),
              ),
            )).toList(),
          ),
          const SizedBox(height: 16),
          Text(
            progressText,
            style: GoogleFonts.inter(
              fontSize: 14,
              color: const Color(0xFF0078D4),
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: progress,
            backgroundColor: const Color(0xFF333333),
            valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF0078D4)),
          ),
        ],
      ),
    );
  }

  Widget _buildDownloadItem(DownloadItem item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          // Status icon
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _getStatusColor(item.status),
            ),
            child: Icon(
              _getStatusIcon(item.status),
              color: Colors.white,
              size: 14,
            ),
          ),
          const SizedBox(width: 12),

          // Component name
          Expanded(
            child: Text(
              item.name,
              style: GoogleFonts.inter(
                fontSize: 14,
                color: Colors.white,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),

          // Status text
          if (item.status == DownloadStatus.downloading) ...[
            Text(
              '${item.progress}%',
              style: GoogleFonts.inter(
                fontSize: 12,
                color: const Color(0xFFBBBBBB),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              item.speedText,
              style: GoogleFonts.inter(
                fontSize: 12,
                color: const Color(0xFF888888),
              ),
            ),
          ] else if (item.status == DownloadStatus.queued)
            Text(
              'Download queued',
              style: GoogleFonts.inter(
                fontSize: 12,
                color: const Color(0xFF888888),
              ),
            )
          else if (item.status == DownloadStatus.installing)
            Text(
              'Installing...',
              style: GoogleFonts.inter(
                fontSize: 12,
                color: const Color(0xFFBBBBBB),
              ),
            )
          else if (item.status == DownloadStatus.completed)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFF2D5016),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Completed',
                style: GoogleFonts.inter(
                  fontSize: 10,
                  color: const Color(0xFF00FF00),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Color _getStatusColor(DownloadStatus status) {
    switch (status) {
      case DownloadStatus.downloading:
        return const Color(0xFF0078D4);
      case DownloadStatus.installing:
        return const Color(0xFFFFA500);
      case DownloadStatus.completed:
        return const Color(0xFF2D5016);
      case DownloadStatus.failed:
        return const Color(0xFF8B0000);
      case DownloadStatus.queued:
        return const Color(0xFF555555);
    }
  }

  IconData _getStatusIcon(DownloadStatus status) {
    switch (status) {
      case DownloadStatus.downloading:
        return Icons.cloud_download;
      case DownloadStatus.installing:
        return Icons.build;
      case DownloadStatus.completed:
        return Icons.check;
      case DownloadStatus.failed:
        return Icons.error;
      case DownloadStatus.queued:
        return Icons.radio_button_unchecked;
    }
  }
}
