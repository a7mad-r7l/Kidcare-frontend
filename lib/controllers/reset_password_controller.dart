import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'base_controller.dart';
import 'package:kidcare/core/repos/reset_password_repo.dart';

class ResetPasswordController extends BaseController {
  final ResetPasswordRepo _repo = ResetPasswordRepo();
  
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();
  
  var isPasswordVisible = false.obs;
  var isConfirmVisible = false.obs;

  // استلام الرقم من الـ arguments الممررة من واجهة الـ OTP
  final String phoneNumber = Get.arguments['phone'];

  void updatePassword() async { // شلنا الـ phone من البرامتر لأننا جبناه فوق
    String pass = passwordController.text;
    String confirmPass = confirmPasswordController.text;

    if (pass.length < 8) {
      Get.snackbar("تنبيه", "يجب أن تكون كلمة المرور 8 أحرف على الأقل");
      return;
    }
    if (pass != confirmPass) {
      Get.snackbar("تنبيه", "كلمات المرور غير متطابقة");
      return;
    }

    try {
      showLoading();
      
      // الربط الحقيقي مع الـ Repo
      final result = await _repo.reset(phoneNumber, pass);
      
      hideLoading();
      
      if (result.status == 'success') {
        Get.snackbar("نجاح", "تم تغيير كلمة المرور بنجاح");
        Get.toNamed('/success-reset'); 
      } else {
        Get.snackbar("خطأ", result.message ?? "فشلت العملية");
      }
      
    } catch (e) {
      hideLoading();
      handleError(e);
    }
  }
}