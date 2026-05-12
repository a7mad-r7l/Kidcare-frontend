import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'base_controller.dart';
// نستخدم الـ Repo الخاص بك لأنه يحتوي على نفس طلب إرسال الرمز
import '../core/repos/activation_repo.dart';

class ForgotPasswordController extends BaseController {
  final phoneController = TextEditingController();
  final ActivationRepo _repo = ActivationRepo(); // حقن الـ Repo الخاص بك

  void sendCode() async {
    String phone = phoneController.text.trim();

    // 1. التحقق من المدخلات (Client-Side Validation) وتنبيه رمادي من الأعلى
    if (phone.isEmpty || phone.length != 12) {
      Get.snackbar(
        "تنبيه",
        phone.isEmpty ? "يرجى إدخال رقم الهاتف" : "يجب أن يتكون رقم الهاتف من 12 رقماً",
        backgroundColor: Colors.grey.shade700,
        colorText: Colors.white,
        snackPosition: SnackPosition.TOP,
      );
      return;
    }

    try {
      showLoading(); // من الـ BaseController

      // 2. استدعاء الـ API عبر الـ Repo الخاص بك
      // إذا نجح سيكمل السطر التالي، وإذا فشل سيرمي Exception يذهب للـ catch فوراً
      await _repo.requestOtp(phone);

      // 3. في حال النجاح (لم يتم رمي أي خطأ)
      Get.snackbar(
        "نجاح",
        "تم إرسال رمز التحقق بنجاح",
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );

      // الانتقال لواجهة الـ OTP وتمرير رقم الهاتف فقط
      Get.toNamed('/otp-view', arguments: {
        'phone': phone,
      });

    } catch (e) {
      // 4. استخدام معالج الأخطاء الذكي الخاص بك (الذي يظهر باللون الأحمر من الأسفل)
      handleError(e);
    }
  }

  @override
  void onClose() {
    phoneController.dispose();
    super.onClose();
  }
}