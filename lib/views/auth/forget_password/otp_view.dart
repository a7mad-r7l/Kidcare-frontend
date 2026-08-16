import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pinput/pinput.dart';
import '../../../controllers/auth/forgot_password_controller.dart';

class OtpView extends StatelessWidget {
  const OtpView({super.key});

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
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            children: [
              Image.asset('assets/images/logo.png', height: 100),
              const SizedBox(height: 20),
              Text(
                "Verify Your Number".tr,
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: context.textTheme.bodyLarge?.color), // 👈 متكيف
              ),
              const SizedBox(height: 10),
              Text(
                "We sent a 4-digit code to".tr,
                style: TextStyle(color: context.theme.hintColor),
              ),

              Text(
                controller.phoneController.text,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: context.textTheme.bodyLarge?.color,
                ),
              ),

              const SizedBox(height: 40),

              Pinput(
                length: 4,
                controller: controller.otpController,
                defaultPinTheme: PinTheme(
                  width: 65,
                  height: 65,
                  decoration: BoxDecoration(
                    color: context.theme.cardColor,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: context.theme.dividerColor.withOpacity(0.5)),
                  ),
                  textStyle: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: context.textTheme.bodyLarge?.color,
                  ),
                ),
              ),

              const SizedBox(height: 30),

              Obx(
                    () => Column(
                  children: [
                    Text(
                      "Didn't receive the code?".tr,
                      style: TextStyle(color: context.theme.hintColor),
                    ),
                    TextButton(
                      onPressed: controller.secondsRemaining.value == 0
                          ? () => controller.sendCode()
                          : null,
                      child: Text(
                        controller.secondsRemaining.value == 0
                            ? "Resend Code".tr
                            : "${"Resend in".tr} (00:${controller.secondsRemaining.value.toString().padLeft(2, '0')})",
                      ),
                    ),
                  ],
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
                        : () => controller.verifyCode(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: context.theme.primaryColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                    ),
                    child: controller.isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : Text(
                      "Verify".tr,
                      style: const TextStyle(color: Colors.white, fontSize: 18),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 50),
              // Image.asset('assets/images/shield_logo.jpg', height: 120), // يفضل تحويلها لـ png شفافة إن وُجدت
            ],
          ),
        ),
      ),
    );
  }
}