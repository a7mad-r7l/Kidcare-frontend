import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/repos/auth/activation_repo.dart';
import '../base_controller.dart';

class ForgotPasswordController extends BaseController {
  final ActivationRepo repo = ActivationRepo();

  final phoneController = TextEditingController();
  final otpController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  var isPasswordVisible = false.obs;
  var isConfirmVisible = false.obs;

  var secondsRemaining = 45.obs;
  Timer? _timer;

  @override
  void onClose() {
    _timer?.cancel();
    super.onClose();
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

  // 1. إرسال رمز التحقق
  Future<void> sendCode() async {
    String phone = phoneController.text.trim();
    if (phone.isEmpty || phone.length < 9) {
      Get.snackbar(
        "Notice".tr,
        "Please enter a valid phone number".tr,
        backgroundColor: Colors.orange,
        colorText: Colors.white,
      );
      return;
    }
    showLoading();
    try {
      await repo.requestOtp(phone);
      startTimer();
      Get.toNamed('/forgot-otp');
    } catch (e) {
      handleError(e);
    } finally {
      hideLoading();
    }
  }

  // 2. التحقق من رمز OTP
  Future<void> verifyCode() async {
    String otp = otpController.text.trim();
    if (otp.length != 4) {
      Get.snackbar(
        "Notice".tr,
        "Please enter the 4-digit code".tr,
        backgroundColor: Colors.orange,
        colorText: Colors.white,
      );
      return;
    }
    showLoading();
    try {
      await repo.verifyOtp(phoneController.text.trim(), otp);
      _timer?.cancel();
      Get.toNamed('/reset-password');
    } catch (e) {
      handleError(e);
    } finally {
      hideLoading();
    }
  }

  // 3. تحديث كلمة المرور
  Future<void> updatePassword() async {
    String password = passwordController.text;
    String confirmPassword = confirmPasswordController.text;

    if (password.length < 8) {
      Get.snackbar(
        "Weak Password".tr,
        "Password must be at least 8 characters long".tr,
        backgroundColor: Colors.orange,
        colorText: Colors.white,
      );
      return;
    }
    if (password != confirmPassword) {
      Get.snackbar(
        "Error".tr,
        "Passwords do not match".tr,
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
      );
      return;
    }

    showLoading();
    try {
      await repo.activateAndLogin(phoneController.text.trim(), password);

      Get.offAllNamed('/success-reset');
    } catch (e) {
      handleError(e);
    } finally {
      hideLoading();
    }
  }
}
