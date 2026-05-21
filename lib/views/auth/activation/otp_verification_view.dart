import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pinput/pinput.dart';

import '../../../controllers/auth/activation_controller.dart';
import '../../../widgets/activation_helpers.dart';
import '../../../widgets/custom_text_field.dart';

class OtpVerificationView extends GetView<ActivationController> {
  const OtpVerificationView({super.key});

  @override
  Widget build(BuildContext context) {
    final defaultPinTheme = PinTheme(
      width: 50,
      height: 56,
      textStyle: const TextStyle(
        fontSize: 20,
        color: Colors.black,
        fontWeight: FontWeight.w600,
      ),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
        color: Colors.white,
      ),
    );

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
              const StepProgressIndicator(currentStep: 2),
              ActivationHeader(
                imagePath: 'assets/images/mobile_blue_logo.png',
                title: 'Verify Your Phone',

                subtitle:
                    'We have sent a 4-digit verification code to\n+${controller.phoneController.text}',
              ),

              // حقل Pinput
              Directionality(
                textDirection: TextDirection.ltr,
                child: Pinput(
                  length: 4,
                  controller: controller.otpController,
                  defaultPinTheme: defaultPinTheme,
                  focusedPinTheme: defaultPinTheme.copyDecorationWith(
                    border: Border.all(color: Colors.blue, width: 2),
                  ),
                  onCompleted: (pin) {},
                ),
              ),
              const SizedBox(height: 30),

              //  إعادة إرسال الرمز
              Obx(() => Column(
                children: [
                  const Text(
                    "Didn't receive the code?",
                    style: TextStyle(color: Colors.grey),
                  ),
                  TextButton(
                    onPressed: controller.secondsRemaining.value == 0
                        ? () => controller.resendOtp()
                        : null,
                    child: Text(
                      controller.secondsRemaining.value == 0
                          ? "Resend Code"
                          : "Resend in (00:${controller.secondsRemaining.value.toString().padLeft(2, '0')})",
                      style: TextStyle(
                        color: controller.secondsRemaining.value == 0
                            ? Colors.blue
                            : Colors.grey,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              )),

              const SizedBox(height: 20),
              Obx(
                () => controller.isLoading
                    ? const CircularProgressIndicator()
                    : PrimaryButton(
                        text: 'Verify and Activate Account',
                        onPressed: controller.verifyOtp,
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
