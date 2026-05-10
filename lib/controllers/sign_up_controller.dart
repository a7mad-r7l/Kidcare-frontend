import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/base_controller.dart';
import '../core/repos/sign_up_repo.dart';

class SignUpController extends BaseController {
  final SignUpRepo signUpRepo;

  SignUpController({required this.signUpRepo});

  final firstNameController = TextEditingController();
  final lastNameController = TextEditingController();
  final emailController = TextEditingController();
  final phoneController = TextEditingController();
  final addressController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  final RxBool isPasswordHidden = true.obs;
  final RxBool isConfirmPasswordHidden = true.obs;

  void togglePassword() => isPasswordHidden.value = !isPasswordHidden.value;
  void toggleConfirmPassword() =>
      isConfirmPasswordHidden.value = !isConfirmPasswordHidden.value;

  Future<void> signUp() async {
    // Client-Side Validation
    if (firstNameController.text.isEmpty ||
        lastNameController.text.isEmpty ||
        emailController.text.isEmpty ||
        phoneController.text.isEmpty ||
        addressController.text.isEmpty ||
        passwordController.text.isEmpty ||
        confirmPasswordController.text.isEmpty) {
      Get.snackbar(
        'Notice',
        'Please fill in all fields',
        backgroundColor: Colors.grey.shade700,
        colorText: Colors.white,
        snackPosition: SnackPosition.TOP,
      );
      return;
    }

    if (passwordController.text != confirmPasswordController.text) {
      Get.snackbar(
        'Notice',
        'Passwords do not match',
        backgroundColor: Colors.grey.shade700,
        colorText: Colors.white,
        snackPosition: SnackPosition.TOP,
      );
      return;
    }

    showLoading(); // ✅ من الـ BaseController
    try {
      final result = await signUpRepo.registerUser(
        firstName: firstNameController.text.trim(),
        lastName: lastNameController.text.trim(),
        email: emailController.text.trim(),
        phone: phoneController.text.trim(),
        address: addressController.text.trim(),
        password: passwordController.text.trim(),
      );

      Get.snackbar(
        'Success',
        result.message,
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );

      Get.toNamed('/verify-otp', arguments: result.phoneNumber);
    } catch (e) {
      handleError(e); // ✅ من الـ BaseController
    } finally {
      hideLoading(); // ✅ من الـ BaseController
    }
  }

  @override
  void onClose() {
    firstNameController.dispose();
    lastNameController.dispose();
    emailController.dispose();
    phoneController.dispose();
    addressController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.onClose();
  }
}