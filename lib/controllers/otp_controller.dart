import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'base_controller.dart';
import '../core/repos/otp_repo.dart';

class OtpController extends BaseController {
  final OtpRepo _repo = OtpRepo();
  final otpController = TextEditingController();
  
  var secondsRemaining = 50.obs;
  Timer? _timer;

  // استلام رقم الهاتف من الواجهة السابقة (ForgotPasswordView)
  final String phoneNumber = Get.arguments['phone'];

  @override
  void onInit() {
    startTimer();
    super.onInit();
  }

  void startTimer() {
    secondsRemaining.value = 50;
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (secondsRemaining.value > 0) {
        secondsRemaining.value--;
      } else {
        _timer?.cancel();
      }
    });
  }

  void verifyCode() async {
    if (otpController.text.length < 4) {
      Get.snackbar("تنبيه", "يرجى إدخال الرمز المكون من 4 أرقام");
      return;
    }

    try {
      showLoading();
      
      // الربط الفعلي مع الـ Repo
      final result = await _repo.verify(phoneNumber, otpController.text);
      
      hideLoading();
      
      if (result.status == 'success') {
        Get.snackbar("نجاح", result.message ?? "تم التحقق بنجاح");
        // الانتقال لواجهة تعيين كلمة السر وتمرير الرقم معنا
        Get.toNamed('/reset-password', arguments: {'phone': phoneNumber});
      } else {
        Get.snackbar("خطأ", result.message ?? "الرمز غير صحيح");
      }
      
    } catch (e) {
      hideLoading();
      handleError(e);
    }
  }

  @override
  void onClose() {
    _timer?.cancel();
    otpController.dispose();
    super.onClose();
  }
}