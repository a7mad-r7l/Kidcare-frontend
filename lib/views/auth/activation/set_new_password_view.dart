import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../controllers/auth/activation_controller.dart';
import '../../../widgets/activation_helpers.dart';
import '../../../widgets/custom_text_field.dart';

class SetNewPasswordView extends GetView<ActivationController> {
  const SetNewPasswordView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios,
            color: context.theme.iconTheme.color,
          ),

          onPressed: () => Get.back(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            children: [
              const StepProgressIndicator(currentStep: 3),
              ActivationHeader(
                imagePath: 'assets/images/lock_blue_logo.png',
                title: 'Create New Password'.tr,
                subtitle: 'Create a strong password to protect your account'.tr,
              ),

              Obx(
                () => CustomTextField(
                  controller: controller.passwordController,
                  hintText: 'New Password'.tr,
                  isPassword: controller.isPasswordHidden.value,
                  suffixIcon: IconButton(
                    icon: Icon(
                      controller.isPasswordHidden.value
                          ? Icons.visibility_off
                          : Icons.visibility,
                      color: context.theme.hintColor,
                    ),
                    onPressed: controller.togglePasswordVisibility,
                  ),
                ),
              ),

              const SizedBox(height: 16),

              Obx(
                () => CustomTextField(
                  controller: controller.confirmPasswordController,
                  hintText: 'Confirm Password'.tr,
                  isPassword: controller.isPasswordHidden.value,
                ),
              ),

              const SizedBox(height: 24),

              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: context.theme.cardColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: context.theme.dividerColor.withOpacity(0.2),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Password must contain:'.tr,
                      style: TextStyle(
                        color: context.theme.hintColor,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 12),
                    PasswordRequirementRow(text: 'At least 8 characters'.tr),
                  ],
                ),
              ),

              const SizedBox(height: 40),
              Obx(
                () => controller.isLoading
                    ? CircularProgressIndicator(
                        color: context.theme.primaryColor,
                      )
                    : PrimaryButton(
                        text: 'Set Password and Login'.tr,
                        onPressed: controller.completeActivation,
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
