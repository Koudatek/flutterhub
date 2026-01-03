import '../entities/doctor_entities.dart';

/// Repository for Flutter Doctor operations
abstract class DoctorRepository {
  /// Run flutter doctor and return the result
  Future<DoctorResult> runDoctor();

  /// Check if flutter doctor can be executed
  Future<bool> canRunDoctor();
}
