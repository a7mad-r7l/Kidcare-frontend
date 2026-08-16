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
      textStyle: TextStyle(
        fontSize: 20,
        color: context.textTheme.bodyLarge?.color,
        fontWeight: FontWeight.w600,
      ),
      decoration: BoxDecoration(
        color: context.theme.cardColor,
        border: Border.all(color: context.theme.dividerColor.withOpacity(0.5)),

        borderRadius: BorderRadius.circular(8),
      ),
    );

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
              const StepProgressIndicator(currentStep: 2),
              ActivationHeader(
                imagePath: 'assets/images/mobile_blue_logo.png',
                title: 'Verify Your Phone'.tr,

                subtitle:
                    '${'We have sent a 4-digit verification code to'.tr}\n+${controller.phoneController.text}',
              ),

              // حقل Pinput
              Directionality(
                textDirection: TextDirection.ltr,
                child: Pinput(
                  length: 4,
                  controller: controller.otpController,
                  defaultPinTheme: defaultPinTheme,
                  focusedPinTheme: defaultPinTheme.copyDecorationWith(
                    border: Border.all(
                      color: context.theme.primaryColor,
                      width: 2,
                    ),
                  ),
                  onCompleted: (pin) {},
                ),
              ),
              const SizedBox(height: 30),

              //  إعادة إرسال الرمز
              Obx(
                () => Column(
                  children: [
                    Text(
                      "Didn't receive the code?".tr,
                      style: TextStyle(color: context.theme.hintColor),
                    ),
                    TextButton(
                      onPressed: controller.secondsRemaining.value == 0
                          ? () => controller.resendOtp()
                          : null,
                      child: Text(
                        controller.secondsRemaining.value == 0
                            ? "Resend Code".tr
                            : "${"Resend in".tr} (00:${controller.secondsRemaining.value.toString().padLeft(2, '0')})",
                        style: TextStyle(
                          color: controller.secondsRemaining.value == 0
                              ? context.theme.primaryColor
                              : context.theme.hintColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),
              Obx(
                () => controller.isLoading
                    ? CircularProgressIndicator(
                        color: context.theme.primaryColor,
                      )
                    : PrimaryButton(
                        text: 'Verify and Activate Account'.tr,
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
