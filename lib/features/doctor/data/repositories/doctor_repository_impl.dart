import '../../domain/entities/doctor_entities.dart';
import '../../domain/repositories/doctor_repositories.dart';
import '../datasources/doctor_datasource.dart';

/// Implementation of DoctorRepository
class DoctorRepositoryImpl implements DoctorRepository {
  const DoctorRepositoryImpl({
    required this.doctorDataSource,
  });

  final DoctorDataSource doctorDataSource;

  @override
  Future<DoctorResult> runDoctor() async {
    return doctorDataSource.runDoctor();
  }

  @override
  Future<bool> canRunDoctor() async {
    return doctorDataSource.canRunFlutter();
  }
}
