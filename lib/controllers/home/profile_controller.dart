import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/helper/secure_storage_service.dart';
import '../../core/repos/home/profile_repo.dart';
import '../../models/home/profile_model.dart';
import '../base_controller.dart';

class ProfileController extends BaseController {
  final ProfileRepo profileRepo;

  ProfileController({required this.profileRepo});

  final Rx<ProfileModel?> profile = Rx<ProfileModel?>(null);

  @override
  void onInit() {
    super.onInit();
    fetchProfile();
  }

  Future<void> fetchProfile() async {
    showLoading();
    try {
      final result = await profileRepo.getProfile();
      profile.value = result;
    } catch (e) {
      handleError(e);
    } finally {
      hideLoading();
    }
  }

  // ─── دالة جديدة لتحديث حقل معين ───
  Future<void> updateProfileField(String key, String newValue) async {
    if (newValue.trim().isEmpty) return;

    showLoading();
    try {
      // إرسال البيانات كـ Map (مثال: {'first_name': 'Louay'})
      await profileRepo.updateProfile({key: newValue.trim()});

      // جلب البيانات من جديد لتحديث الواجهة تلقائياً
      await fetchProfile();

      Get.back(); // إغلاق نافذة التعديل (Dialog)
      Get.snackbar(
        'Success'.tr,
        'Profile updated successfully'.tr,
        backgroundColor: Colors.green,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
      handleError(e);
    } finally {
      hideLoading();
    }
  }

  Future<void> logout() async {
    await SecureStorage.removeToken();
    Get.offAllNamed('/login');
  }
}