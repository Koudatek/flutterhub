import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../providers/doctor_providers.dart';
import '../../domain/entities/doctor_entities.dart';

class DoctorScreen extends HookConsumerWidget {
  const DoctorScreen({super.key});

  Color getSeverityColor(DoctorSeverity severity) {
    switch (severity) {
      case DoctorSeverity.info:
        return Colors.blue;
      case DoctorSeverity.warning:
        return Colors.orange;
      case DoctorSeverity.error:
        return Colors.red;
      case DoctorSeverity.fatal:
        return Colors.red[900]!;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final doctorResult = ref.watch(doctorResultProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Flutter Doctor'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Vérification de l\'environnement Flutter',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Cette fonctionnalité exécute "flutter doctor" pour diagnostiquer votre environnement de développement.',
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 32),

            // Action button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: doctorResult.isLoading
                    ? null
                    : () => ref.read(doctorResultProvider.notifier).runDoctor(),
                icon: doctorResult.isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.medical_services),
                label: Text(
                  doctorResult.isLoading
                      ? 'Analyse en cours...'
                      : 'Lancer le diagnostic',
                ),
              ),
            ),
            const SizedBox(height: 32),

            // Results display
            Expanded(
              child: doctorResult.when(
                data: (result) => result != null ? _buildResultsView(result, theme) : _buildInitialView(),
                loading: () => _buildLoadingView(),
                error: (error, stack) => _buildErrorView(error, theme),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInitialView() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.medical_services_outlined,
            size: 64,
            color: Colors.grey,
          ),
          SizedBox(height: 16),
          Text(
            'Aucun diagnostic effectué',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Cliquez sur "Lancer le diagnostic" pour analyser votre environnement Flutter.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingView() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text('Exécution de flutter doctor...'),
        ],
      ),
    );
  }

  Widget _buildErrorView(Object error, ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.error_outline,
            size: 64,
            color: Colors.red,
          ),
          const SizedBox(height: 16),
          Text(
            'Erreur lors de l\'exécution',
            style: theme.textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            error.toString(),
            style: theme.textTheme.bodyMedium?.copyWith(color: Colors.red),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildResultsView(DoctorResult result, ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              result.hasIssues ? Icons.warning : Icons.check_circle,
              color: result.hasIssues ? Colors.orange : Colors.green,
            ),
            const SizedBox(width: 8),
            Text(
              result.hasIssues
                  ? '${result.issues
                  .where((issue) => !issue.isResolved)
                  .length} problèmes détectés'
                  : 'Environnement vérifié avec succès',
              style: theme.textTheme.titleMedium?.copyWith(
                color: result.hasIssues ? Colors.orange : Colors.green,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        Expanded(
          child: Column(
            children: [
              Expanded(
                child: ListView.builder(
                  itemCount: result.issues.length,
                  itemBuilder: (context, index) {
                    final issue = result.issues[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: Icon(
                          issue.isResolved ? Icons.check_circle : Icons.error,
                          color: issue.isResolved ? Colors.green : getSeverityColor(
                              issue.severity),
                        ),
                        title: Text(
                          issue.category,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(issue.description),
                        trailing: Chip(
                          label: Text(
                            issue.severity.name.toUpperCase(),
                            style: const TextStyle(fontSize: 10),
                          ),
                          backgroundColor: getSeverityColor(issue.severity)
                              .withValues(alpha: 0.1),
                          side: BorderSide(color: getSeverityColor(issue.severity)),
                        ),
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(height: 16),
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      theme.colorScheme.surface,
                      theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: theme.colorScheme.shadow.withValues(alpha: 0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                  border: Border.all(
                    color: theme.colorScheme.outline.withValues(alpha: 0.2),
                  ),
                ),
                child: Theme(
                  data: theme.copyWith(
                    dividerColor: Colors.transparent,
                  ),
                  child: ExpansionTile(
                    title: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primaryContainer,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.terminal_rounded,
                            color: theme.colorScheme.primary,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Sortie brute du diagnostic',
                                style: GoogleFonts.inter(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: theme.colorScheme.onSurface,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Détails complets de flutter doctor',
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  color: theme.colorScheme.onSurfaceVariant,
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          Icons.expand_more,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ],
                    ),
                    tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    childrenPadding: EdgeInsets.zero,
                    children: [
                      Divider(
                        height: 1,
                        color: theme.colorScheme.outline.withValues(alpha: 0.2),
                      ),
                      Container(
                        constraints: const BoxConstraints(maxHeight: 400),
                        padding: const EdgeInsets.all(16),
                        child: SingleChildScrollView(
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.surfaceContainerLowest.withValues(alpha: 0.8),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: theme.colorScheme.outline.withValues(alpha: 0.3),
                              ),
                            ),
                            child: SelectableText(
                              result.output,
                              style: GoogleFonts.jetBrainsMono(
                                fontSize: 12,
                                height: 1.5,
                                color: theme.colorScheme.onSurface,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
