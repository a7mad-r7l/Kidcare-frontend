import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../core/base/base_controller.dart';
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
    if (firstNameController.text.isEmpty ||
        lastNameController.text.isEmpty ||
        emailController.text.isEmpty ||
        phoneController.text.isEmpty ||
        addressController.text.isEmpty ||
        passwordController.text.isEmpty ||
        confirmPasswordController.text.isEmpty) {
      handleError('Please fill in all fields');
      return;
    }

    if (passwordController.text != confirmPasswordController.text) {
      handleError('Passwords do not match');
      return;
    }

    isLoading.value = true;
    try {
      await signUpRepo.registerUser(
        firstName: firstNameController.text.trim(),
        lastName: lastNameController.text.trim(),
        email: emailController.text.trim(),
        phone: phoneController.text.trim(),
        address: addressController.text.trim(),
        password: passwordController.text.trim(),
      );

      Get.snackbar(
        'Success',
        'Account created successfully!',
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
      Get.offAllNamed('/login');
    } catch (e) {
      handleError(e);
    } finally {
      isLoading.value = false;
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
