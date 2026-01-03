import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutterhub/core/config/routes/app_router.dart';
import 'package:flutterhub/features/dashboard/presentation/providers/dashboard_providers.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../installations_manager/presentation/screens/installations_manager_screen.dart';

/// Custom sidebar widget for FlutterHub navigation
class FlutterHubSidebar extends HookWidget {
  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;

  const FlutterHubSidebar({
    super.key,
    required this.selectedIndex,
    required this.onDestinationSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 240,
      decoration: const BoxDecoration(
        color: Color(0xFF121212),
        borderRadius: BorderRadius.only(
          //topRight: Radius.circular(12),
          //bottomRight: Radius.circular(12),
        ),
      ),
      child: Column(
        children: [
          // Logo section
          const SizedBox(height: 24),
          Row(
            children: [
              SizedBox(width: 40,),
              const FlutterLogo(size: 20),
              SizedBox(width: 10,),
              Text(
                'Flutter Hub',
                style: GoogleFonts.inter(  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(width: 8),

          const SizedBox(height: 32),

          // Menu items
          _buildMenuItem(
            index: 0,
            icon: Icons.storage,
            label: 'Installs',
            isSelected: selectedIndex == 0,
            onTap: () => onDestinationSelected(0),
          ),
          _buildMenuItem(
            index: 1,
            icon: Icons.folder_open,
            label: 'Projects',
            isSelected: selectedIndex == 1,
            onTap: () => onDestinationSelected(1),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem({
    required int index,
    required IconData icon,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final isHovered = useState(false);

    return MouseRegion(
      onEnter: (_) => isHovered.value = true,
      onExit: (_) => isHovered.value = false,
      child: InkWell(
        onTap: onTap,
        hoverColor: Colors.transparent,
        child: Container(
          height: 48,
          padding: const EdgeInsets.only(left: 24),
          color: isSelected
              ? Colors.transparent
              : (isHovered.value ? const Color(0xFF252525) : Colors.transparent),
          child: Row(
            children: [
              // Blue indicator bar for selected item
              Container(
                width: 4,
                height: 32,
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFF0078D4) : Colors.transparent,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 20),

              // Icon and text
              Icon(
                icon,
                color: isSelected ? Colors.white : const Color(0xFFAAAAAA),
                size: 20,
              ),
              const SizedBox(width: 12),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? Colors.white : const Color(0xFFAAAAAA),
                  fontSize: 14,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class DashboardScreen extends HookConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedIndex = useState(0);

    return Scaffold(
      body: Row(
        children: [
          // Custom FlutterHub sidebar
          FlutterHubSidebar(
            selectedIndex: selectedIndex.value,
            onDestinationSelected: (index) {
              selectedIndex.value = index;
            },
          ),

          // Content
          Expanded(
            child: _getScreen(selectedIndex.value),
          ),
        ],
      ),
    );
  }

  Widget _getScreen(int index) {
    switch (index) {
      case 0:
        return const InstallationsManagerScreen(); // TODO: Créer cet écran plus tard
      case 1:
        return const ProjectsScreen();
      default:
        return const DashboardContent();
    }
  }
}

/// Écran temporaire pour les projets (à développer plus tard)
class ProjectsScreen extends StatelessWidget {
  const ProjectsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text('Gestion des projets - À venir'),
    );
  }
}

class DashboardContent extends HookConsumerWidget {
  const DashboardContent({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final dashboardState = ref.watch(dashboardStateProvider);

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Bienvenue sur FlutterHub',
              style: theme.textTheme.headlineLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Votre assistant pour installer et gérer Flutter',
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(height: 32),

            // État de l'environnement Flutter
            _buildEnvironmentStatusCard(dashboardState, theme, context),
            const SizedBox(height: 24),

            // Actions rapides
            _buildQuickActions(context, dashboardState, theme),
          ],
        ),
      ),
    );
  }

  Widget _buildEnvironmentStatusCard(DashboardState state, ThemeData theme, BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.info_outline,
                  color: theme.colorScheme.primary,
                  size: 28,
                ),
                const SizedBox(width: 12),
                Text(
                  'État de l\'environnement',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Statut Flutter
            _buildStatusRow(
              icon: state.isFlutterInstalled ? Icons.check_circle : Icons.cancel,
              iconColor: state.isFlutterInstalled ? Colors.green : Colors.red,
              title: 'Flutter SDK',
              subtitle: state.isFlutterInstalled
                  ? 'Installé et prêt à l\'emploi'
                  : 'Non installé - Installation requise',
              actionText: state.isFlutterInstalled ? 'Voir les détails' : 'Installer',
              onAction: () => AppRoute.installFlutter.goNamed(context),
            ),

            const SizedBox(height: 16),

            // Statut Doctor
            _buildStatusRow(
              icon: state.doctorResult != null
                  ? (state.hasDoctorIssues ? Icons.warning : Icons.check_circle)
                  : Icons.help_outline,
              iconColor: state.doctorResult != null
                  ? (state.hasDoctorIssues ? Colors.orange : Colors.green)
                  : Colors.grey,
              title: 'Environnement de développement',
              subtitle: state.doctorResult != null
                  ? (state.hasDoctorIssues
                      ? '${state.doctorResult!.issues.length} problèmes détectés'
                      : 'Tout est configuré correctement')
                  : 'Aucune vérification effectuée',
              actionText: state.doctorResult != null ? 'Voir le rapport' : 'Vérifier',
              onAction: () => AppRoute.doctor.goNamed(context),
            ),

            if (state.isInstalling) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.withValues(alpha: 0.1),
                  border: Border.all(color: Colors.blue),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Installation de Flutter en cours...',
                      style: theme.textTheme.bodyMedium?.copyWith(color: Colors.blue[800]),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatusRow({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required String actionText,
    required VoidCallback onAction,
  }) {
    return Row(
      children: [
        Icon(icon, color: iconColor, size: 24),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
              Text(
                subtitle,
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
        TextButton(
          onPressed: onAction,
          child: Text(actionText),
        ),
      ],
    );
  }

  Widget _buildQuickActions(BuildContext context, DashboardState state, ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Actions rapides',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            if (!state.isFlutterInstalled || state.isInstalling)
              _buildQuickActionCard(
                context: context,
                icon: Icons.download,
                title: 'Installer Flutter',
                description: 'Télécharger et configurer le SDK',
                onTap: () => AppRoute.installFlutter.goNamed(context),
                color: Colors.blue,
              ),

            _buildQuickActionCard(
              context: context,
              icon: Icons.build,
              title: 'Installation complète',
              description: 'Installer tous les composants Flutter',
              onTap: () {
                // Simuler la navigation vers l'onglet Installs
                // Dans un vrai système, on pourrait utiliser un état global
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Utilisez l\'onglet "Installs" dans la barre latérale')),
                );
              },
              color: Colors.blue,
            ),

            _buildQuickActionCard(
              context: context,
              icon: Icons.settings,
              title: 'Paramètres',
              description: 'Configurer les préférences',
              onTap: () => AppRoute.settings.goNamed(context),
              color: Colors.grey,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildQuickActionCard({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String description,
    required VoidCallback onTap,
    required Color color,
  }) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 200,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          border: Border.all(color: color.withValues(alpha: 0.3)),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 12),
            Text(
              title,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              description,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
