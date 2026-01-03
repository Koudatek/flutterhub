import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../installations_manager/domain/entities/installer_entities.dart';
import '../../../installations_manager/presentation/providers/installation_manager_providers.dart';
import '../../../doctor/domain/entities/doctor_entities.dart' as doctor_entities;
import '../../../doctor/presentation/providers/doctor_providers.dart';


/// Combined dashboard state
class DashboardState {
  const DashboardState({
    required this.flutterVersions,
    required this.doctorResult,
    required this.installationStatus,
  });

  final List<FlutterVersion>? flutterVersions;
  final doctor_entities.DoctorResult? doctorResult;
  final InstallationStatus? installationStatus;

  bool get isFlutterInstalled => flutterVersions?.isNotEmpty ?? false;
  bool get hasDoctorIssues => doctorResult?.hasIssues ?? false;
  bool get isInstalling => installationStatus != null &&
                          installationStatus != InstallationStatus.completed &&
                          installationStatus != InstallationStatus.failed;
}

/// Provider for dashboard state combining Flutter and Doctor information
final dashboardStateProvider = Provider<DashboardState>((ref) {
  final flutterVersionsAsync = ref.watch(flutterVersionsProvider);
  final flutterVersions = flutterVersionsAsync.maybeWhen(
    data: (data) => data,
    orElse: () => null,
  );
  final doctorResultAsync = ref.watch(doctorResultProvider);
  final doctorResult = doctorResultAsync.maybeWhen(
    data: (data) => data,
    orElse: () => null,
  );
  final installationStatus = ref.watch(updateFlutterSdkStateProvider);

  return DashboardState(
    flutterVersions: flutterVersions,
    doctorResult: doctorResult,
    installationStatus: installationStatus,
  );
});
