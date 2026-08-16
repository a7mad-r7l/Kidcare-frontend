import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../controllers/auth/forgot_password_controller.dart';

class ResetPasswordView extends StatelessWidget {
  const ResetPasswordView({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<ForgotPasswordController>();
    return Scaffold(
      backgroundColor: context.theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: BackButton(color: context.theme.iconTheme.color),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            Image.asset('assets/images/logo.png', height: 100),
            const SizedBox(height: 20),
            Text(
              "Create New Password".tr,
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: context.textTheme.bodyLarge?.color),
            ),
            const SizedBox(height: 10),
            Text(
              "Your new password must be different".tr,
              style: TextStyle(color: context.theme.hintColor),
            ),
            const SizedBox(height: 30),

            Obx(
                  () => TextField(
                controller: controller.passwordController,
                obscureText: !controller.isPasswordVisible.value,
                style: TextStyle(color: context.textTheme.bodyLarge?.color),
                decoration: InputDecoration(
                  hintText: "Password".tr,
                  hintStyle: TextStyle(color: context.theme.hintColor),
                  filled: true,
                  fillColor: context.theme.cardColor,
                  prefixIcon: Icon(Icons.lock_outline, color: context.theme.hintColor),
                  suffixIcon: IconButton(
                    icon: Icon(
                      controller.isPasswordVisible.value
                          ? Icons.visibility
                          : Icons.visibility_off,
                      color: context.theme.hintColor,
                    ),
                    onPressed: () => controller.isPasswordVisible.toggle(),
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                    borderSide: BorderSide(color: context.theme.dividerColor.withOpacity(0.2)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                    borderSide: BorderSide(color: context.theme.primaryColor, width: 1.5),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 20),

            Obx(
                  () => TextField(
                controller: controller.confirmPasswordController,
                obscureText: !controller.isConfirmVisible.value,
                style: TextStyle(color: context.textTheme.bodyLarge?.color),
                decoration: InputDecoration(
                  hintText: "Confirm Password".tr,
                  hintStyle: TextStyle(color: context.theme.hintColor),
                  filled: true,
                  fillColor: context.theme.cardColor,
                  prefixIcon: Icon(Icons.lock_outline, color: context.theme.hintColor),
                  suffixIcon: IconButton(
                    icon: Icon(
                      controller.isConfirmVisible.value
                          ? Icons.visibility
                          : Icons.visibility_off,
                      color: context.theme.hintColor,
                    ),
                    onPressed: () => controller.isConfirmVisible.toggle(),
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                    borderSide: BorderSide(color: context.theme.dividerColor.withOpacity(0.2)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                    borderSide: BorderSide(color: context.theme.primaryColor, width: 1.5),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 40),

            Obx(
                  () => SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: controller.isLoading
                      ? null
                      : () => controller.updatePassword(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: context.theme.primaryColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                  child: controller.isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text(
                    "Update Password".tr,
                    style: const TextStyle(color: Colors.white, fontSize: 18),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 50),
            // Image.asset('assets/images/lock_logo.jpg', height: 150),
          ],
        ),
      ),
    );
  }
}