import 'package:get/get.dart';
import '../../core/repos/home/appointments_repo.dart';

import '../../models/home/appointments_model.dart';
import '../base_controller.dart';


class AppointmentsController extends BaseController {
  final AppointmentsRepo appointmentsRepo;

  AppointmentsController({required this.appointmentsRepo});

  late final int childId;

  final RxList<AppointmentsModel> upcoming = <AppointmentsModel>[].obs;
  final RxList<AppointmentsModel> past = <AppointmentsModel>[].obs;
  final RxBool showUpcoming = true.obs;

  @override
  void onInit() {
    super.onInit();
    childId = Get.arguments as int;
    fetchUpcoming();
  }

  void switchTab(bool isUpcoming) {
    showUpcoming.value = isUpcoming;
    if (isUpcoming && upcoming.isEmpty) {
      fetchUpcoming();
    } else if (!isUpcoming && past.isEmpty) {
      fetchPast();
    }
  }

  Future<void> fetchUpcoming() async {
    showLoading();
    try {
      final result = await appointmentsRepo.getUpcoming(childId);
      upcoming.assignAll(result);
    } catch (e) {
      handleError(e);
    } finally {
      hideLoading();
    }
  }

  Future<void> fetchPast() async {
    showLoading();
    try {
      final result = await appointmentsRepo.getPast(childId);
      past.assignAll(result);
    } catch (e) {
      handleError(e);
    } finally {
      hideLoading();
    }
  }
}