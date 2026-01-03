import 'dart:convert';
import 'dart:io';
import 'package:flutterhub/core/config/logger/logger_config.dart';
import 'package:process_run/process_run.dart';

import '../../domain/entities/doctor_entities.dart';

/// Data source for executing Flutter Doctor commands
class DoctorDataSource {
  const DoctorDataSource();

  /// Execute flutter doctor command
  Future<DoctorResult> runDoctor() async {
    AppLogger.info('Starting Flutter Doctor execution');

    try {
      final result = await runExecutableArguments(
        'flutter',
        ['doctor', '--verbose'],
        stdout: stdout,
        stderr: stderr,
      );

      final output = result.stdout?.toString() ?? '';
      AppLogger.info('Flutter Doctor completed with exit code: ${result.exitCode}');

      final issues = _parseDoctorOutput(output);
      final hasIssues = issues.any((issue) => !issue.isResolved);

      return DoctorResult(
        output: output,
        issues: issues,
        hasIssues: hasIssues,
      );
    } catch (e, stackTrace) {
      AppLogger.error('Failed to run Flutter Doctor', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  /// Check if flutter command is available
  Future<bool> canRunFlutter() async {
    try {
      final result = await runExecutableArguments(
        'flutter',
        ['--version'],
        stdout: null,
        stderr: null,
      );
      return result.exitCode == 0;
    } catch (e) {
      AppLogger.warning('Flutter command not available', error: e);
      return false;
    }
  }

  /// Parse the flutter doctor output to extract issues
  List<DoctorIssue> _parseDoctorOutput(String output) {
    final issues = <DoctorIssue>[];
    final lines = LineSplitter.split(output).toList();

    for (final line in lines) {
      // Look for lines with check marks, crosses, or warnings
      if (line.contains('✓') || line.contains('✗') || line.contains('!') || line.contains('[√]')) {
        final isResolved = line.contains('✓') || line.contains('[√]');
        final severity = _determineSeverity(line);
        final category = _extractCategory(line);
        final description = _extractDescription(line);

        if (category.isNotEmpty && description.isNotEmpty) {
          issues.add(DoctorIssue(
            category: category,
            description: description,
            severity: severity,
            isResolved: isResolved,
          ));
        }
      }
    }

    return issues;
  }

  DoctorSeverity _determineSeverity(String line) {
    if (line.contains('✗')) return DoctorSeverity.error;
    if (line.contains('!')) return DoctorSeverity.warning;
    if (line.contains('✓') || line.contains('[√]')) return DoctorSeverity.info;
    return DoctorSeverity.info;
  }

  String _extractCategory(String line) {
    // Extract the main component name (e.g., "Flutter", "Android toolchain", etc.)
    final trimmed = line.trim();
    if (trimmed.contains('Flutter')) return 'Flutter';
    if (trimmed.contains('Android')) return 'Android';
    if (trimmed.contains('iOS') || trimmed.contains('Xcode')) return 'iOS';
    if (trimmed.contains('Chrome')) return 'Chrome';
    if (trimmed.contains('Edge')) return 'Edge';
    if (trimmed.contains('Visual Studio')) return 'Visual Studio';
    if (trimmed.contains('Connected device')) return 'Device';
    return 'Other';
  }

  String _extractDescription(String line) {
    // Remove the check mark/cross and extract the description
    return line.replaceAll(RegExp(r'(\[√\]|[✓✗!])\s*'), '').trim();
  }
}
