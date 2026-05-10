import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'base_controller.dart';
import '../core/repos/activation_repo.dart';

class ActivationController extends BaseController {
  final ActivationRepo repo = ActivationRepo();

  final phoneController = TextEditingController();
  final otpController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  var isPasswordHidden = true.obs;

  void togglePasswordVisibility() {
    isPasswordHidden.value = !isPasswordHidden.value;
  }

  // 1. طلب OTP والانتقال لواجهة الرمز
  Future<void> startActivation() async {
    if (phoneController.text.isEmpty) return;
    showLoading();
    try {
      await repo.requestOtp(phoneController.text.trim());
      Get.toNamed('/activation-otp');
    } catch (e) {
      handleError(e);
    } finally {
      hideLoading();
    }
  }

  // 2. الانتقال لواجهة تعيين كلمة المرور (بدون API Call)
  void verifyOtp() {
    if (otpController.text.isEmpty) {
      Get.snackbar("Warning", "Please enter the OTP");
      return;
    }
    // ننتقل مباشرة للواجهة الأخيرة لأن التحقق سيتم مع إرسال كلمة المرور
    Get.toNamed('/set-password');
  }

  // 3. إرسال كل البيانات (رقم، OTP، كلمة المرور) للتفعيل والدخول
  Future<void> completeActivation() async {
    if (passwordController.text != confirmPasswordController.text) {
      Get.snackbar("Error", "Passwords do not match");
      return;
    }
    showLoading();
    try {
      await repo.activateAndLogin(
        phoneController.text.trim(),
        otpController.text.trim(),
        passwordController.text,
      );

      Get.snackbar("Success", "Account activated successfully", backgroundColor: Colors.green, colorText: Colors.white);

      // التوجه للصفحة الرئيسية بعد التفعيل
      // Get.offAllNamed('/home');
    } catch (e) {
      handleError(e);
    } finally {
      hideLoading();
    }
  }
}