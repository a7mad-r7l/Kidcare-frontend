import 'package:get/get.dart';
import '../../core/repos/appointment/doctor_repo.dart';
import '../../models/appointment/doctor_model.dart';
import '../../models/appointment/doctor_availability_model.dart';
import '../base_controller.dart';

class DoctorController extends BaseController {
  final DoctorRepo repo;

  DoctorController({required this.repo});

  final doctors = <DoctorModel>[].obs;
  final weeklyAvailability = <DoctorAvailabilityModel>[].obs;

  Future<void> loadDoctors(int departmentId) async {
    showLoading();
    try {
      doctors.value = await repo.fetchByDepartment(departmentId);
    } catch (e) {
      handleError(e);
    } finally {
      hideLoading();
    }
  }

  Future<void> loadWeeklyAvailability(int doctorId) async {
    try {
      weeklyAvailability.value = await repo.fetchWeeklyAvailability(doctorId);
    } catch (e) {
      handleError(e);
    }
  }
}
