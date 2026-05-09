import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/activation_controller.dart';
import '../../widgets/activation_helpers.dart';
import '../../widgets/custom_text_field.dart';

class SetNewPasswordView extends GetView<ActivationController> {
  const SetNewPasswordView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
          onPressed: () => Get.back(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            children: [
              const StepProgressIndicator(currentStep: 3),
              const ActivationHeader(
                imagePath: 'assets/images/lock_blue_logo.png',
                title: 'Create New Password',
                subtitle: 'Create a strong password to protect your account',
              ),

              Obx(() => CustomTextField(
                controller: controller.passwordController,
                hintText: 'New Password',
                isPassword: controller.isPasswordHidden.value,
                suffixIcon: IconButton(
                  icon: Icon(controller.isPasswordHidden.value ? Icons.visibility_off : Icons.visibility, color: Colors.grey),
                  onPressed: controller.togglePasswordVisibility, // يجب إضافتها للكونترولر
                ),
              )),

              const SizedBox(height: 16),

              Obx(() => CustomTextField(
                controller: controller.confirmPasswordController,
                hintText: 'Confirm Password',
                isPassword: controller.isPasswordHidden.value, // ربطناها بنفس المتغير لتبسيط الكود
              )),

              const SizedBox(height: 24),

              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text('Password must contain:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                        Spacer(),
                        Icon(Icons.check_circle, color: Colors.green, size: 18),
                      ],
                    ),
                    SizedBox(height: 12),
                    PasswordRequirementRow(text: 'At least 8 characters'),
                    PasswordRequirementRow(text: 'Uppercase & lowercase letters'),
                    PasswordRequirementRow(text: 'At least 1 number'),
                  ],
                ),
              ),

              const SizedBox(height: 40),
              Obx(() => controller.isLoading
                  ? const CircularProgressIndicator()
                  : PrimaryButton(
                text: 'Set Password and Login',
                onPressed: controller.completeActivation,
              )),
            ],
          ),
        ),
      ),
    );
  }
}