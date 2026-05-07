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
    if (phoneController.text.isEmpty || passwordController.text.isEmpty) {
      Get.snackbar("Warning", "Please fill in all fields",
          backgroundColor: Colors.orange, colorText: Colors.white);
      return;
    }

    showLoading();
    try {
      final user = await loginRepo.loginUser(
        phoneController.text.trim(),
        passwordController.text.trim(),
      );

      Get.snackbar("Success", "Welcome Back, ${user.firstName}!",
          backgroundColor: Colors.green, colorText: Colors.white);

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