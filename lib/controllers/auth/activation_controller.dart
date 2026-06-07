import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/repos/auth/activation_repo.dart';
import '../base_controller.dart';

class ActivationController extends BaseController {
  final ActivationRepo repo = ActivationRepo();

  final phoneController = TextEditingController();
  final otpController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  var isPasswordHidden = true.obs;


  var secondsRemaining = 45.obs;
  Timer? _timer;

  @override
  void onClose() {
    _timer?.cancel();
    super.onClose();
  }

  void togglePasswordVisibility() {
    isPasswordHidden.value = !isPasswordHidden.value;
  }


  void startTimer() {
    secondsRemaining.value = 45;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (secondsRemaining.value > 0) {
        secondsRemaining.value--;
      } else {
        timer.cancel();
      }
    });
  }

  // 1. طلب OTP والانتقال للواجهة الثانية
  Future<void> startActivation() async {
    String phone = phoneController.text.trim();
    if (phone.isEmpty || phone.length != 12) {
      Get.snackbar(
        "Notice".tr,
        phone.isEmpty
            ? "Please enter phone number".tr
            : "Phone number must be 12 numbers (e.g., 9639XXXXXXXX)".tr,
        backgroundColor: Colors.grey.shade700,
        colorText: Colors.white,
        snackPosition: SnackPosition.TOP,
        margin: const EdgeInsets.all(15),
        duration: const Duration(seconds: 2),
      );
      return;
    }
    showLoading();
    try {
      await repo.requestOtp(phoneController.text.trim());
      startTimer();
      Get.toNamed('/activation-otp');
    } catch (e) {
      handleError(e);
    } finally {
      hideLoading();
    }
  }


  Future<void> resendOtp() async {
    showLoading();
    try {
      await repo.requestOtp(phoneController.text.trim());
      startTimer();
      Get.snackbar(
        "Success".tr,
        "Verification code resent successfully".tr,
        backgroundColor: Colors.green,
        colorText: Colors.white,
        snackPosition: SnackPosition.TOP,
      );
    } catch (e) {
      handleError(e);
    } finally {
      hideLoading();
    }
  }

  // 2. التحقق من الرمز عبر السيرفر والانتقال للواجهة الثالثة
  Future<void> verifyOtp() async {
    String otp = otpController.text.trim();
    if (otp.isEmpty || otp.length != 4) {
      Get.snackbar(
        "Check Code".tr,
        otp.isEmpty
            ? "Please enter OTP".tr
            : "Please enter the 4-digit code correctly".tr,
        backgroundColor: Colors.grey.shade700,
        colorText: Colors.white,
        snackPosition: SnackPosition.TOP,
        margin: const EdgeInsets.all(15),
        duration: const Duration(seconds: 2),
      );
      return;
    }
    showLoading();
    try {
      await repo.verifyOtp(
        phoneController.text.trim(),
        otpController.text.trim(),
      );
      _timer?.cancel();
      Get.toNamed('/set-password');
    } catch (e) {
      handleError(e);
    } finally {
      hideLoading();
    }
  }

  // 3. إرسال كلمة المرور للتفعيل والدخول
  Future<void> completeActivation() async {
    String password = passwordController.text;
    String confirmPassword = confirmPasswordController.text;

    // 1. التحقق من الحقول الفارغة
    if (password.isEmpty || confirmPassword.isEmpty) {
      Get.snackbar(
        "Required Fields".tr,
        "Please fill in all fields".tr,
        backgroundColor: Colors.grey.shade700,
        colorText: Colors.white,
        snackPosition: SnackPosition.TOP,
        margin: const EdgeInsets.all(15),
      );
      return;
    }

    // 2. التحقق من تطابق كلمتي المرور
    if (password != confirmPassword) {
      Get.snackbar(
        "Error".tr,
        "Passwords do not match".tr,
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
      );
      return;
    }

    // 3. التحقق من طول كلمة المرور
    if (password.length < 8) {
      Get.snackbar(
        "Weak Password".tr,
        "Password must be at least 8 characters long".tr,
        backgroundColor: Colors.orange,
        colorText: Colors.white,
        icon: const Icon(Icons.lock_outline, color: Colors.white),
      );
      return;
    }
    showLoading();
    try {
      await repo.activateAndLogin(
        phoneController.text.trim(),
        passwordController.text,
      );

      Get.snackbar(
        "Success".tr,
        "Account activated successfully".tr,
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );


      Get.offAllNamed('/home');
    } catch (e) {
      handleError(e);
    } finally {
      hideLoading();
    }
  }
}