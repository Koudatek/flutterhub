import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutterhub/core/config/logger/logger_config.dart';
import 'package:flutterhub/features/installations_manager/domain/entities/installer_entities.dart';
import 'package:flutterhub/features/installations_manager/domain/usecases/installation_manager_usecases.dart';
import 'package:flutterhub/features/installations_manager/presentation/providers/installation_manager_providers.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'add_components_dialog.dart';
import 'complete_install_dialog.dart';

class InstallationsManagerScreen extends HookConsumerWidget {
  const InstallationsManagerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final searchController = useTextEditingController();
    final installationStateAsync = ref.watch(flutterInstallationStateProvider);
    final flutterVersionsAsync = ref.watch(flutterVersionsProvider);
    final latestVersionAsync = ref.watch(latestStableFlutterVersionProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF1e1e1e),
      body: Column(
        children: [
          // Header
          _buildHeader(),

          // Search bar and actions
          _buildSearchAndActions(searchController, context),

          // Content based on installation state
          Expanded(
            child: installationStateAsync.when(
              data: (state) => _buildContentBasedOnState(
                state,
                flutterVersionsAsync,
                latestVersionAsync,
              ),
              loading: () => _buildLoadingView(),
              error: (error, stack) => _buildErrorView(error),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(24),
      color: const Color(0xFF1e1e1e),
      child: Row(
        children: [
          Text(
            'Installations',
            style: GoogleFonts.inter(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchAndActions(TextEditingController searchController, BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      color: const Color(0xFF1e1e1e),
      child: Row(
        children: [
          // Search bar (hidden for now since we only have one item)
          const Spacer(),

          // Locate button
          Container(
            height: 40,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            decoration: BoxDecoration(
              color: const Color(0xFF3a3a3a),
              borderRadius: BorderRadius.circular(6),
            ),
            child: InkWell(
              onTap: () => _handleLocateFlutter(context),
              child: Center(
                child: Text(
                  'Locate',
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(width: 16),

          // Install Flutter button
          Container(
            height: 40,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            decoration: BoxDecoration(
              color: const Color(0xFF0078d4),
              borderRadius: BorderRadius.circular(6),
            ),
            child: InkWell(
              onTap: () => _handleInstallFlutter(context),
              child: Center(
                child: Text(
                  'Install Flutter',
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContentBasedOnState(
    FlutterInstallationState state,
    AsyncValue<List<FlutterVersion>> flutterVersionsAsync,
    AsyncValue<String?> latestVersionAsync,
  ) {
    switch (state) {
      case FlutterInstallationState.notInstalled:
        return _buildNotInstalledView();
      case FlutterInstallationState.installed:
        return flutterVersionsAsync.when(
          data: (versions) => versions.isNotEmpty
              ? _buildSingleFlutterVersionItem(versions.first, showUpdateButton: false, latestVersionAsync: latestVersionAsync)
              : _buildNotInstalledView(),
          loading: () => _buildLoadingView(),
          error: (error, stack) => _buildErrorView(error),
        );
      case FlutterInstallationState.updateAvailable:
        return flutterVersionsAsync.when(
          data: (versions) => versions.isNotEmpty
              ? _buildSingleFlutterVersionItem(versions.first, showUpdateButton: true, latestVersionAsync: latestVersionAsync)
              : _buildNotInstalledView(),
          loading: () => _buildLoadingView(),
          error: (error, stack) => _buildErrorView(error),
        );
    }
  }

  bool _isLTSVersion(String version) {
    // Simple heuristic for LTS versions (Flutter LTS versions)
    // This could be improved by checking official LTS designations
    final parts = version.split('.');
    if (parts.length >= 2) {
      final minor = int.tryParse(parts[1]) ?? 0;
      // Flutter LTS versions: 2.10, 2.13, 3.3, 3.10, 3.16, etc.
      return [10, 13, 16, 22, 24].contains(minor); // Update as needed
    }
    return false;
  }

  Widget _buildSingleFlutterVersionItem(FlutterVersion version, {required bool showUpdateButton, required AsyncValue<String?> latestVersionAsync}) {
    return Container(
      color: const Color(0xFF252525),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: latestVersionAsync.when(
          data: (latestVersion) => _buildFlutterVersionItem(version, showUpdateButton: showUpdateButton, latestVersion: latestVersion),
          loading: () => _buildFlutterVersionItem(version, showUpdateButton: showUpdateButton),
          error: (error, stack) => _buildFlutterVersionItem(version, showUpdateButton: showUpdateButton),
        ),
      ),
    );
  }

  Widget _buildNotInstalledView() {
    return Container(
      color: const Color(0xFF252525),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.flutter_dash,
              color: Colors.grey[600],
              size: 64,
            ),
            const SizedBox(height: 16),
            Text(
              'Flutter n\'est pas installé',
              style: GoogleFonts.inter(
                color: Colors.grey[400],
                fontSize: 18,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Utilisez "Install Flutter" pour installer la dernière version stable',
              style: GoogleFonts.inter(
                color: Colors.grey[600],
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  void _handleLocateFlutter(BuildContext context) async {
    // Cette méthode sera appelée depuis le contexte de build, donc nous aurons accès à ref
    // Pour l'instant, on utilise une approche simplifiée
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Recherche d\'installations Flutter...'),
        backgroundColor: Colors.blue,
      ),
    );
  }

  void _handleInstallFlutter(BuildContext context) async {
    showInstallFlutterDialog(context);
  }

  void _handleUpdateFlutter(WidgetRef ref) async {
    final updateNotifier = ref.read(updateFlutterSdkStateProvider.notifier);
    await updateNotifier.updateSdk();
  }

  void showInstallFlutterDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => InstallFlutterDialog(),
    );
  }

  Widget _buildFlutterVersionItem(FlutterVersion version, {required bool showUpdateButton, String? latestVersion}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF252525),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[700]!, width: 1),
      ),
      child: Row(
        children: [
          // Icon
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFF02569B),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.flutter_dash,
              color: Colors.white,
              size: 20,
            ),
          ),

          const SizedBox(width: 16),

          // Version info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      version.name,
                      style: GoogleFonts.inter(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: _getStatusColor(version.status),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        version.status,
                        style: GoogleFonts.inter(
                          color: _getStatusTextColor(version.status),
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    if (version.isDefault) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0d47a1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'Default',
                          style: GoogleFonts.inter(
                            color: const Color(0xFF64b5f6),
                            fontSize: 9,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),

                const SizedBox(height: 4),

                Text(
                  'Path: ${version.path}',
                  style: GoogleFonts.inter(
                    color: const Color(0xFFbbbbbb),
                    fontSize: 12,
                  ),
                ),

                if (version.installedComponents.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Components: ${version.installedComponents.join(', ')}',
                    style: GoogleFonts.inter(
                      color: const Color(0xFF888888),
                      fontSize: 11,
                    ),
                  ),
                ],

                const SizedBox(height: 8),

                // Platform tags
                Row(
                  children: ['Web', 'Android', 'iOS', 'Windows', 'macOS', 'Linux']
                      .map((platform) {
                    return Container(
                      margin: const EdgeInsets.only(right: 6),
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFF333333),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        platform,
                        style: GoogleFonts.inter(
                          color: const Color(0xFFcccccc),
                          fontSize: 10,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),

          // Action buttons
          Row(
            children: [
              if (showUpdateButton) ...[
                Tooltip(
                  message: latestVersion != null
                      ? 'Une nouvelle version stable de Flutter est disponible (${version.name} → $latestVersion). Cliquez pour mettre à jour.'
                      : 'Une nouvelle version stable de Flutter est disponible. Cliquez pour mettre à jour vers la dernière version.',
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0078d4),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Consumer(
                      builder: (context, ref, child) {
                        final updateState = ref.watch(updateFlutterSdkStateProvider);
                        return InkWell(
                          onTap: updateState == InstallationStatus.downloading
                              ? null
                              : () => _handleUpdateFlutter(ref),
                          child: Row(
                            children: [
                              if (updateState == InstallationStatus.downloading)
                                const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                  ),
                                )
                              else
                                Icon(
                                  Icons.update,
                                  color: Colors.white,
                                  size: 16,
                                ),
                              const SizedBox(width: 4),
                              Text(
                                updateState == InstallationStatus.downloading ? 'Updating...' : 'Update',
                                style: GoogleFonts.inter(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ),
                const SizedBox(width: 8),
              ],

              // Manage button
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFF3a3a3a),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.settings,
                      color: Colors.grey[400],
                      size: 16,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Manage',
                      style: GoogleFonts.inter(
                        color: Colors.grey[400],
                        fontSize: 12,
                      ),
                    ),
                    Icon(
                      Icons.arrow_drop_down,
                      color: Colors.grey[400],
                      size: 16,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingView() {
    return Container(
      color: const Color(0xFF252525),
      child: const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF0078d4)),
        ),
      ),
    );
  }

  Widget _buildErrorView(Object error) {
    return Container(
      color: const Color(0xFF252525),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              color: Colors.grey[600],
              size: 48,
            ),
            const SizedBox(height: 16),
            Text(
              'Erreur lors du chargement des versions',
              style: GoogleFonts.inter(
                color: Colors.grey[400],
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              error.toString(),
              style: GoogleFonts.inter(
                color: Colors.grey[600],
                fontSize: 12,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'stable':
        return const Color(0xFF003d00); // Dark green background
      case 'preview':
        return const Color(0xFF2d5016); // Orange-ish background
      case 'development':
        return const Color(0xFF4a148c); // Purple background
      case 'lts':
        return const Color(0xFF0d47a1); // Blue background
      default:
        return const Color(0xFF424242); // Gray background
    }
  }

  Color _getStatusTextColor(String status) {
    switch (status.toLowerCase()) {
      case 'stable':
        return const Color(0xFF00ff00); // Bright green text
      case 'preview':
        return const Color(0xFFffb74d); // Orange text
      case 'development':
        return const Color(0xFFba68c8); // Light purple text
      case 'lts':
        return const Color(0xFF64b5f6); // Light blue text
      default:
        return const Color(0xFFffffff); // White text
    }
  }
}

/// Separate widget for the Install Flutter dialog
class InstallFlutterDialog extends ConsumerWidget {
  const InstallFlutterDialog({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final releasesAsync = ref.watch(allStableFlutterReleasesProvider);
    final installedVersionsAsync = ref.watch(flutterVersionsProvider);

    return Dialog(
      backgroundColor: const Color(0xFF1E1E1E),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        width: 800,
        constraints: const BoxConstraints(maxWidth: 800),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Install Flutter', style: GoogleFonts.inter(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            )),
            const SizedBox(height: 24),

            // Onglets
            DefaultTabController(
              length: 3,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TabBar(
                    indicatorColor: const Color(0xFF0078D4),
                    indicatorWeight: 3,
                    labelColor: Colors.white,
                    unselectedLabelColor: const Color(0xFFBBBBBB),
                    labelStyle: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w500),
                    unselectedLabelStyle: GoogleFonts.inter(fontSize: 14),
                    tabs: const [
                      Tab(text: 'Official releases'),
                      Tab(text: 'Pre-releases'),
                      Tab(text: 'Archive'),
                    ],
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    height: 400,
                    child: TabBarView(
                      children: [
                        // === Official releases ===
                        releasesAsync.when(
                          data: (releases) => installedVersionsAsync.when(
                            data: (installedVersions) => _buildOfficialReleasesTab(context, releases, installedVersions),
                            loading: () => const Center(child: CircularProgressIndicator()),
                            error: (error, stack) => Center(child: Text('Error: $error', style: const TextStyle(color: Colors.white))),
                          ),
                          loading: () => const Center(child: CircularProgressIndicator()),
                          error: (error, stack) => Center(child: Text('Error: $error', style: const TextStyle(color: Colors.white))),
                        ),

                        // === Pre-releases ===
                        releasesAsync.when(
                          data: (releases) => installedVersionsAsync.when(
                            data: (installedVersions) => _buildPreReleasesTabContent(context, releases, installedVersions),
                            loading: () => const Center(child: CircularProgressIndicator()),
                            error: (error, stack) => Center(child: Text('Error: $error', style: const TextStyle(color: Colors.white))),
                          ),
                          loading: () => const Center(child: CircularProgressIndicator()),
                          error: (error, stack) => Center(child: Text('Error: $error', style: const TextStyle(color: Colors.white))),
                        ),

                        // === Archive ===
                        releasesAsync.when(
                          data: (releases) => installedVersionsAsync.when(
                            data: (installedVersions) => _buildArchiveTabContent(context, releases, installedVersions),
                            loading: () => const Center(child: CircularProgressIndicator()),
                            error: (error, stack) => Center(child: Text('Error: $error', style: const TextStyle(color: Colors.white))),
                          ),
                          loading: () => const Center(child: CircularProgressIndicator()),
                          error: (error, stack) => Center(child: Text('Error: $error', style: const TextStyle(color: Colors.white))),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton(
                  onPressed: () => launchUrl(Uri.parse('https://docs.flutter.dev/development/tools/sdk/releases')),
                  child: Text(
                    'Beta program',
                    style: GoogleFonts.inter(
                      color: const Color(0xFFBBBBBB),
                      fontSize: 14,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    'Cancel',
                    style: GoogleFonts.inter(
                      color: const Color(0xFFBBBBBB),
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOfficialReleasesTab(BuildContext context, List<Map<String, dynamic>> releases, List<FlutterVersion> installedVersions) {
    // Filter only stable releases for official releases
    final stableReleases = releases
        .where((release) => (release['channel'] as String?) == 'stable')
        .toList();
        
    if (stableReleases.isEmpty) {
      return const Center(child: Text('No stable releases found', style: TextStyle(color: Colors.white)));
    }

    // Get latest stable (first in sorted list)
    final latestStable = stableReleases.first;
    // Get previous stables (next 3-4)
    final previousStables = stableReleases.skip(1).take(4).toList();

    return ListView(
      shrinkWrap: true,
      children: [
        Text('LATEST STABLE', style: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: const Color(0xFFCCCCCC),
        )),
        const SizedBox(height: 12),
        _buildVersionItem(context,
          version: 'Flutter ${latestStable['version']} (Stable)',
          badges: ['Supported', 'Recommended'],
          isRecommended: true,
          installedVersions: installedVersions,
        ),
        const Divider(height: 32, color: Color(0xFF333333)),
        Text('PREVIOUS STABLE', style: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: const Color(0xFFCCCCCC),
        )),
        const SizedBox(height: 12),
        ...previousStables.map((release) {
          final version = release['version'] as String?;
          if (version == null) return const SizedBox.shrink();
          
          // Check if it's LTS (simple heuristic: even minor versions or specific versions)
          final badges = <String>[];
          if (_isLTSVersion(version)) {
            badges.add('LTS');
          }
          
          return _buildVersionItem(context,
            version: 'Flutter $version',
            badges: badges,
            installedVersions: installedVersions,
          );
        }),
      ],
    );
  }

  Widget _buildPreReleasesTabContent(BuildContext context, List<Map<String, dynamic>> releases, List<FlutterVersion> installedVersions) {
    // Filter beta and dev releases
    final betaReleases = releases
        .where((release) => (release['channel'] as String?) == 'beta')
        .take(5)
        .toList();
    
    final devReleases = releases
        .where((release) => (release['channel'] as String?) == 'dev')
        .take(5)
        .toList();

    if (betaReleases.isEmpty && devReleases.isEmpty) {
      return const Center(child: Text('No pre-releases available', style: TextStyle(color: Colors.white)));
    }

    return ListView(
      shrinkWrap: true,
      children: [
        if (betaReleases.isNotEmpty) ...[
          Text('BETA CHANNEL', style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: const Color(0xFFCCCCCC),
          )),
          const SizedBox(height: 12),
          ...betaReleases.map((release) {
            final version = release['version'] as String?;
            if (version == null) return const SizedBox.shrink();
            return _buildVersionItem(context,
              version: 'Flutter $version (Beta)',
              badges: ['Beta'],
              installedVersions: installedVersions,
            );
          }),
          if (devReleases.isNotEmpty) const Divider(height: 32, color: Color(0xFF333333)),
        ],
        
        if (devReleases.isNotEmpty) ...[
          Text('DEV CHANNEL', style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: const Color(0xFFCCCCCC),
          )),
          const SizedBox(height: 12),
          ...devReleases.map((release) {
            final version = release['version'] as String?;
            if (version == null) return const SizedBox.shrink();
            return _buildVersionItem(context,
              version: 'Flutter $version (Dev)',
              badges: ['Dev'],
              installedVersions: installedVersions,
            );
          }),
        ],
      ],
    );
  }

  Widget _buildArchiveTabContent(BuildContext context, List<Map<String, dynamic>> releases, List<FlutterVersion> installedVersions) {
    // Filter stable releases and skip the first 5 (shown in official releases)
    final archivedReleases = releases
        .where((release) => (release['channel'] as String?) == 'stable')
        .skip(5) // Skip latest 5 shown in official releases
        .take(10) // Show next 10 archived versions
        .toList();

    if (archivedReleases.isEmpty) {
      return const Center(child: Text('No archived versions', style: TextStyle(color: Colors.white)));
    }

    return ListView(
      shrinkWrap: true,
      children: [
        Text('ARCHIVED VERSIONS', style: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: const Color(0xFFCCCCCC),
        )),
        const SizedBox(height: 12),
        ...archivedReleases.map((release) {
          final version = release['version'] as String?;
          if (version == null) return const SizedBox.shrink();
          
          // Check if it's LTS (simple heuristic: even minor versions or specific versions)
          final badges = <String>[];
          if (_isLTSVersion(version)) {
            badges.add('LTS');
          }
          
          return _buildVersionItem(context,
            version: 'Flutter $version',
            badges: badges,
            installedVersions: installedVersions,
          );
        }),
      ],
    );
  }

  Widget _buildVersionItem(BuildContext context, {
    required String version,
    required List<String> badges,
    bool isRecommended = false,
    required List<FlutterVersion> installedVersions,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          const Icon(Icons.flutter_dash, size: 40, color: Color(0xFF02569B)),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(version, style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                )),
                if (badges.isNotEmpty)
                  Wrap(
                    spacing: 8,
                    children: badges.map((b) => Chip(
                      label: Text(b, style: TextStyle(
                        color: _getBadgeTextColor(b),
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      )),
                      backgroundColor: _getBadgeBackgroundColor(b),
                      padding: EdgeInsets.zero,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    )).toList(),
                  ),
              ],
            ),
          ),
          TextButton(
            onPressed: () => launchUrl(Uri.parse('https://docs.flutter.dev/development/tools/sdk/releases')),
            child: Text(
              'Release notes',
              style: GoogleFonts.inter(
                color: const Color(0xFF0078D4),
                fontSize: 12,
              ),
            ),
          ),
          const SizedBox(width: 8),
          // Extract version number for checking if already installed
          Builder(
            builder: (context) {
              final versionNumber = version.contains('(Beta)') 
                ? version.replaceFirst('Flutter ', '').split(' (Beta)')[0].split('-')[0] // Remove pre-release suffix
                : version.contains('(Dev)') 
                ? version.replaceFirst('Flutter ', '').split(' (Dev)')[0].split('-')[0] // Remove pre-release suffix
                : version.replaceFirst('Flutter ', '').split(' (Stable)')[0];
              
              final isInstalled = installedVersions.any((installed) => 
                installed.name == versionNumber || 
                installed.name.startsWith(versionNumber) ||
                versionNumber.startsWith(installed.name));
              
              if (isInstalled) {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2D5016), // Same green as stable badge
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    'Installed',
                    style: GoogleFonts.inter(
                      color: const Color(0xFF00FF00),
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                );
              }
              
              return ElevatedButton(
                onPressed: () => _installFlutterVersion(context, versionNumber),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0078D4),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                ),
                child: const Text('Install'),
              );
            },
          ),
        ],
      ),
    );
  }

  void _installFlutterVersion(BuildContext context, String version) {
    // Close the current dialog
    Navigator.pop(context);

    // Show the Complete Installation dialog (new intelligent version)
    showCompleteInstallDialog(context, version);
  }

  Future<void> _performInstallation(BuildContext context, String version, List<String> selectedComponents) async {
    // TODO: Implement actual installation logic with selected components
    print('Installing Flutter $version with components: $selectedComponents');

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Installing Flutter $version with ${selectedComponents.length} components...'),
        backgroundColor: Colors.blue,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  Color _getBadgeTextColor(String badge) {
    switch (badge.toLowerCase()) {
      case 'recommended':
        return Colors.black;
      case 'supported':
      case 'lts':
        return const Color(0xFF00FF00);
      case 'beta':
        return const Color(0xFFFFA726); // Orange
      case 'dev':
        return const Color(0xFFAB47BC); // Purple
      default:
        return const Color(0xFF00FF00);
    }
  }

  Color _getBadgeBackgroundColor(String badge) {
    switch (badge.toLowerCase()) {
      case 'recommended':
        return Colors.white;
      case 'supported':
      case 'lts':
        return const Color(0xFF003D00);
      case 'beta':
        return const Color(0xFF4A148C).withValues(alpha: 0.3); // Dark purple with opacity
      case 'dev':
        return const Color(0xFF7B1FA2).withValues(alpha: 0.3); // Purple with opacity
      default:
        return const Color(0xFF003D00);
    }
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
