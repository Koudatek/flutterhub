/// Result of a Flutter Doctor check
class DoctorResult {
  const DoctorResult({
    required this.output,
    required this.issues,
    required this.hasIssues,
  });

  final String output;
  final List<DoctorIssue> issues;
  final bool hasIssues;

  @override
  String toString() {
    return 'DoctorResult(hasIssues: $hasIssues, issues: ${issues.length})';
  }
}

/// A specific issue found by Flutter Doctor
class DoctorIssue {
  const DoctorIssue({
    required this.category,
    required this.description,
    required this.severity,
    required this.isResolved,
  });

  final String category;
  final String description;
  final DoctorSeverity severity;
  final bool isResolved;

  @override
  String toString() {
    return '$category: $description (${severity.name})';
  }
}

/// Severity levels for doctor issues
enum DoctorSeverity {
  info,
  warning,
  error,
  fatal,
}

/// Status of doctor execution
enum DoctorStatus {
  notStarted,
  running,
  completed,
  failed,
}
