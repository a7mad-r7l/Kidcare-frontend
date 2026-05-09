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

  // 1. طلب OTP والانتقال للواجهة الثانية
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

  // 2. التحقق من الرمز الفعلي عبر السيرفر والانتقال للواجهة الثالثة
  Future<void> verifyOtp() async {
    if (otpController.text.isEmpty) {
      Get.snackbar("Warning", "Please enter the OTP");
      return;
    }
    showLoading();
    try {
      await repo.verifyOtp(phoneController.text.trim(), otpController.text.trim());
      Get.toNamed('/set-password');
    } catch (e) {
      handleError(e);
    } finally {
      hideLoading();
    }
  }

  // 3. إرسال كلمة المرور للتفعيل والدخول
  Future<void> completeActivation() async {
    if (passwordController.text != confirmPasswordController.text) {
      Get.snackbar("Error", "Passwords do not match");
      return;
    }
    showLoading();
    try {
      await repo.activateAndLogin(
        phoneController.text.trim(),
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