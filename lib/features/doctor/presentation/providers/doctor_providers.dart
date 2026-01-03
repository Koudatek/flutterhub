import 'package:flutterhub/features/doctor/domain/entities/doctor_entities.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/datasources/doctor_datasource.dart';
import '../../data/repositories/doctor_repository_impl.dart';
import '../../domain/repositories/doctor_repositories.dart';
import '../../domain/usecases/doctor_usecases.dart';


// Data source provider
final doctorDataSourceProvider = Provider<DoctorDataSource>((ref) {
  return DoctorDataSource();
});

// Repository provider
final doctorRepositoryProvider = Provider<DoctorRepository>((ref) {
  final dataSource = ref.watch(doctorDataSourceProvider);
  return DoctorRepositoryImpl(doctorDataSource: dataSource);
});

// Use case providers
final runDoctorUseCaseProvider = Provider<RunDoctorUseCase>((ref) {
  final repository = ref.watch(doctorRepositoryProvider);
  return RunDoctorUseCase(doctorRepository: repository);
});

final canRunDoctorUseCaseProvider = Provider<CanRunDoctorUseCase>((ref) {
  final repository = ref.watch(doctorRepositoryProvider);
  return CanRunDoctorUseCase(doctorRepository: repository);
});

// State notifier for doctor execution
final doctorResultProvider = AsyncNotifierProvider<DoctorNotifier, DoctorResult?>(DoctorNotifier.new);

class DoctorNotifier extends AsyncNotifier<DoctorResult?> {
  @override
  Future<DoctorResult?> build() async {
    // Return null initially - no doctor result yet
    return null;
  }

  Future<void> runDoctor() async {
    state = const AsyncLoading();
    try {
      final result = await ref.watch(runDoctorUseCaseProvider)();
      state = AsyncData(result);
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
    }
  }
}