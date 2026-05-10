import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../core/repos/login_repo.dart';
import 'base_controller.dart';

class LoginController extends BaseController {
  final LoginRepo loginRepo;

  // تمرير الـ Repo عبر الـ Constructor
  LoginController({required this.loginRepo});

  final phoneController = TextEditingController();
  final passwordController = TextEditingController();

  final isPasswordHidden = true.obs;

  void togglePasswordVisibility() {
    isPasswordHidden.value = !isPasswordHidden.value;
  }

  Future<void> login() async {
    String phone = phoneController.text.trim();
    if (phoneController.text.isEmpty || passwordController.text.isEmpty) {
      Get.snackbar(
        "Required Fields",
        "Please fill in all fields",
        backgroundColor: Colors.grey.shade700,
        colorText: Colors.white,
        snackPosition: SnackPosition.TOP,
      );
      return;
    }
    // 2. التحقق من طول رقم الهاتف
    if (phone.length != 12) {
      Get.snackbar(
        "Invalid Phone Number",
        "Phone number must be exactly 12 numbers (e.g., 9639XXXXXXXX)",
        backgroundColor: Colors.grey.shade700,
        colorText: Colors.white,
        snackPosition: SnackPosition.TOP,
      );
      return;
    }

    showLoading();
    try {
      final user = await loginRepo.loginUser(
        phoneController.text.trim(),
        passwordController.text.trim(),
      );

      Get.snackbar(
        "Success",
        "Welcome Back, ${user.firstName}!",
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );

      // Get.offAllNamed('/home');
    } catch (e) {
      handleError(e);
    } finally {
      hideLoading();
    }
  }

  @override
  void onClose() {
    phoneController.dispose();
    passwordController.dispose();
    super.onClose();
  }
}
