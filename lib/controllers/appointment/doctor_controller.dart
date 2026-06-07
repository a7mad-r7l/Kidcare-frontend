import 'package:get/get.dart';
import '../../core/repos/appointment/doctor_repo.dart';
import '../../core/repos/appointment/favorite_repo.dart';
import '../../models/appointment/doctor_model.dart';
import '../../models/appointment/doctor_availability_model.dart';
import '../base_controller.dart';

class DoctorController extends BaseController {
  final DoctorRepo repo;
  final FavoriteRepo favoriteRepo = FavoriteRepo();

  DoctorController({required this.repo});

  final doctors = <DoctorModel>[].obs;
  final favoriteDoctors = <DoctorModel>[].obs;
  final favDoctorIds = <int>{}.obs;
  final weeklyAvailability = <DoctorAvailabilityModel>[].obs;

  @override
  void onInit() {
    super.onInit();
    loadFavoriteDoctorIds();
  }


  Future<void> loadFavoriteDoctorIds() async {
    try {
      final favs = await favoriteRepo.fetchFavoriteDoctors();
      favoriteDoctors.assignAll(favs);
      favDoctorIds.assignAll(favs.map((d) => d.id));
    } catch (_) {}
  }


  Future<void> toggleFavorite(int doctorId) async {
    if (favDoctorIds.contains(doctorId)) {
      favDoctorIds.remove(doctorId);
      favoriteDoctors.removeWhere((d) => d.id == doctorId);
    } else {
      favDoctorIds.add(doctorId);

      final doc = doctors.firstWhereOrNull((d) => d.id == doctorId);
      if (doc != null) favoriteDoctors.add(doc);
    }
    favDoctorIds.refresh();

    try {

      await favoriteRepo.toggleDoctorFavorite(doctorId);
    } catch (e) {

      loadFavoriteDoctorIds();
      handleError(e);
    }
  }

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
