import '../entities/doctor_entities.dart';
import '../repositories/doctor_repositories.dart';

/// Use case for running Flutter Doctor
class RunDoctorUseCase {
  const RunDoctorUseCase({
    required this.doctorRepository,
  });

  final DoctorRepository doctorRepository;

  Future<DoctorResult> call() async {
    return doctorRepository.runDoctor();
  }
}

/// Use case for checking if Flutter Doctor can be run
class CanRunDoctorUseCase {
  const CanRunDoctorUseCase({
    required this.doctorRepository,
  });

  final DoctorRepository doctorRepository;

  Future<bool> call() async {
    return doctorRepository.canRunDoctor();
  }
}
