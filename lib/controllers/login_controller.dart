import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../core/repos/login_repo.dart';

class LoginController extends GetxController {
  final phoneController = TextEditingController();
  final passwordController = TextEditingController();

  // استدعاء طبقة الـ Repo التي بنيناها
  final LoginRepo loginRepo = LoginRepo();

  bool isLoading = false;
  bool isPasswordHidden = true;

  void togglePasswordVisibility() {
    isPasswordHidden = !isPasswordHidden;
    update(); // تحديث الواجهة
  }

  Future<void> login() async {
    // 1. التحقق من الحقول
    if (phoneController.text.isEmpty || passwordController.text.isEmpty) {
      Get.snackbar(
        'Warning',
        'Please fill in all fields',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return;
    }

    // 2. تشغيل دائرة التحميل
    isLoading = true;
    update();

    try {
      // 3. إرسال الطلب للسيرفر الحقيقي عبر الـ Repo
      final user = await loginRepo.loginUser(
        phoneController.text.trim(),
        passwordController.text.trim(),
      );

      // 4. إذا نجح (وتم حفظ التوكن في Repo)، نظهر رسالة نجاح
      Get.snackbar(
        'Success',
        'Welcome Back, ${user.firstName}!',
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );

      // 5. الانتقال للشاشة الرئيسية
      // Get.offAllNamed('/home');

    } catch (e) {
      // 6. في حال خطأ بكلمة المرور أو السيرفر
      Get.snackbar(
        'Error',
        'Invalid credentials, please try again',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      print("Login Error: $e"); // لطباعة الخطأ في الكونسول للمطور
    } finally {
      // 7. إيقاف دائرة التحميل في كل الأحوال (نجاح أو فشل)
      isLoading = false;
      update();
    }
  }

  @override
  void onClose() {
    phoneController.dispose();
    passwordController.dispose();
    super.onClose();
  }
}