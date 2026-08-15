import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/repos/home/appointments_repo.dart';
import '../../models/home/appointments_model.dart';
import '../base_controller.dart';

class AppointmentsController extends BaseController {
  final AppointmentsRepo appointmentsRepo;

  AppointmentsController({required this.appointmentsRepo});

  // جعلناه Nullable، فإذا كان null، فهذا يعني أننا طلبنا كل المواعيد
  int? childId;

  final RxList<AppointmentsModel> upcoming = <AppointmentsModel>[].obs;
  final RxList<AppointmentsModel> past = <AppointmentsModel>[].obs;
  final RxBool showUpcoming = true.obs;

  @override
  void onInit() {
    super.onInit();
    // التقاط الـ ID إذا أتينا من شاشة الطفل، وإلا سيبقى null
    if (Get.arguments is int) {
      childId = Get.arguments as int;
    }
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
      // توجيه ذكي للطلب
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
  Future<void> cancelAppointment(int appointmentId) async {
    try {
      // إظهار دائرة التحميل
      Get.dialog(
        const Center(child: CircularProgressIndicator()),
        barrierDismissible: false,
      );

      // استدعاء دالة الحذف من الـ Repo
      final response = await appointmentsRepo.cancelAppointment(appointmentId);

      // إغلاق دائرة التحميل
      Get.back();

      // 1. حذف الموعد من قائمة "المواعيد القادمة" في الواجهة فوراً
      upcoming.removeWhere((appointment) => appointment.id == appointmentId);

      // 2. تصفير قائمة المواعيد السابقة لتهيئتها للاستجابة الجديدة
      past.clear();

      // 3. الانتقال التلقائي إلى تبويب المواعيد السابقة (Past) وجلب البيانات المحدثة
      switchTab(false);

      // إظهار رسالة النجاح متوافقة مع لغة التطبيق النشطة
      Get.snackbar(
        'Success'.tr,
        response['message'] ?? 'Appointment canceled successfully'.tr,
        backgroundColor: Get.isDarkMode ? Colors.green.withValues(alpha: 0.8) : Colors.green.shade600,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );

    } catch (e) {
      Get.back(); // إغلاق دائرة التحميل في حالة الخطأ
      handleError(e); // معالجة الخطأ عبر الـ BaseController
    }
  }

  Future<void> fetchPast() async {
    showLoading();
    try {
      // توجيه ذكي للطلب
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
}