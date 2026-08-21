import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/repos/home/appointments_repo.dart';
import '../../models/home/appointments_model.dart';
import '../base_controller.dart';

class AppointmentsController extends BaseController {
  final AppointmentsRepo appointmentsRepo;

  AppointmentsController({required this.appointmentsRepo});

  int? childId;

  final RxList<AppointmentsModel> upcoming = <AppointmentsModel>[].obs;
  final RxList<AppointmentsModel> past = <AppointmentsModel>[].obs;
  final RxList<AppointmentsModel> cancelled = <AppointmentsModel>[].obs; // 👈 القائمة الجديدة

  final RxInt selectedTab = 0.obs; // 0 = Upcoming, 1 = Past, 2 = Cancelled

  @override
  void onInit() {
    super.onInit();
    if (Get.arguments is int) {
      childId = Get.arguments as int;
    }
    fetchUpcoming();
  }

  void switchTab(int index) {
    selectedTab.value = index;
    if (index == 0 && upcoming.isEmpty) {
      fetchUpcoming();
    } else if (index == 1 && past.isEmpty) {
      fetchPast();
    } else if (index == 2 && cancelled.isEmpty) {
      fetchCancelled();
    }
  }

  Future<void> fetchUpcoming() async {
    showLoading();
    try {
      final result = childId != null
          ? await appointmentsRepo.getUpcomingForChild(childId!)
          : await appointmentsRepo.getAllUpcoming();
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
      final result = childId != null
          ? await appointmentsRepo.getPastForChild(childId!)
          : await appointmentsRepo.getAllPast();
      past.assignAll(result);
    } catch (e) {
      handleError(e);
    } finally {
      hideLoading();
    }
  }

  Future<void> fetchCancelled() async {
    showLoading();
    try {
      // جلب جميع المواعيد الملغية (لعدم وجود راوت مخصص للطفل)
      List<AppointmentsModel> result = await appointmentsRepo.getAllCancelled();

      // 👈 فلترة محلية (Local Filtering) إذا كنا داخل ملف طفل محدد
      if (childId != null && childId != 0) {
        result = result.where((app) => app.childId == childId).toList();
      }

      cancelled.assignAll(result);
    } catch (e) {
      handleError(e);
    } finally {
      hideLoading();
    }
  }

  Future<void> cancelAppointment(int appointmentId) async {
    try {
      Get.dialog(
        const Center(child: CircularProgressIndicator()),
        barrierDismissible: false,
      );

      final response = await appointmentsRepo.cancelAppointment(appointmentId);

      Get.back();

      // حذف الموعد من قائمة القادمة
      upcoming.removeWhere((appointment) => appointment.id == appointmentId);

      // تصفير القوائم الأخرى لتحديثها عند زيارتها
      past.clear();
      cancelled.clear();

      // الانتقال تلقائياً لتبويب المواعيد الملغية
      switchTab(2);

      Get.snackbar(
        'Success'.tr,
        response['message'] ?? 'Appointment canceled successfully'.tr,
        backgroundColor: Get.isDarkMode ? Colors.green.withValues(alpha: 0.8) : Colors.green.shade600,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );

    } catch (e) {
      Get.back();
      handleError(e);
    }
  }
}