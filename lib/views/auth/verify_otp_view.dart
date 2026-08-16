import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/auth/verify_otp_controller.dart';
import '../../widgets/custom_text_field.dart';

class VerifyOtpView extends GetView<VerifyOtpController> {
  const VerifyOtpView({super.key});

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
            size: 20,
          ),
          onPressed: () => Get.back(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 16),

            Image.asset(
              'assets/images/shield_lock_check_logo.png',
              height: 130,
              fit: BoxFit.contain,
            ),
            const SizedBox(height: 28),

            Text(
              'Verify Your Phone Number'.tr,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: context.textTheme.bodyLarge?.color,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),

            Text(
              'We sent a 4-digit verification code to'.tr,
              style: TextStyle(fontSize: 13, color: context.theme.hintColor),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              controller.maskedPhone,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: context.theme.primaryColor,
              ),
            ),
            const SizedBox(height: 36),

            // OTP Boxes (تأكد أن الـ OtpBox داخله يستخدم ألوان متكيفة أيضاً)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                OtpBox(
                  controller: controller.otp1,
                  focusNode: controller.f1,
                  onChanged: (v) =>
                      controller.onOtpChanged(v, controller.f2, null),
                ),
                const SizedBox(width: 14),
                OtpBox(
                  controller: controller.otp2,
                  focusNode: controller.f2,
                  onChanged: (v) =>
                      controller.onOtpChanged(v, controller.f3, controller.f1),
                ),
                const SizedBox(width: 14),
                OtpBox(
                  controller: controller.otp3,
                  focusNode: controller.f3,
                  onChanged: (v) =>
                      controller.onOtpChanged(v, controller.f4, controller.f2),
                ),
                const SizedBox(width: 14),
                OtpBox(
                  controller: controller.otp4,
                  focusNode: controller.f4,
                  onChanged: (v) =>
                      controller.onOtpChanged(v, null, controller.f3),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Validity timer
            Obx(
                  () => RichText(
                text: TextSpan(
                  style: TextStyle(fontSize: 13, color: context.theme.hintColor),
                  children: [
                    TextSpan(text: 'The code is valid for '.tr),
                    TextSpan(
                      text: controller.validityFormatted,
                      style: TextStyle(
                        color: context.theme.primaryColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    TextSpan(text: ' minutes'.tr),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 28),

            // Resend section
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
              decoration: BoxDecoration(
                color: context.theme.cardColor,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: context.theme.dividerColor.withOpacity(0.2)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Didn't receive the code?".tr,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: context.textTheme.bodyLarge?.color,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'You can resend the code after the countdown ends'.tr,
                          style: TextStyle(
                            fontSize: 12,
                            color: context.theme.hintColor,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Obx(
                              () => controller.canResend.value
                              ? GestureDetector(
                            onTap: controller.resendOtp,
                            child: Text(
                              'Resend Code'.tr,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: context.theme.primaryColor,
                              ),
                            ),
                          )
                              : Text(
                            controller.resendFormatted,
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: context.theme.primaryColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: context.theme.primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.chat_bubble_outline,
                      color: context.theme.primaryColor,
                      size: 26,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),

            // Verify button
            Obx(
                  () => controller.isLoading
                  ? Center(
                child: CircularProgressIndicator(color: context.theme.primaryColor),
              )
                  : PrimaryButton(
                text: 'Verify'.tr,
                onPressed: controller.verifyOtp,
              ),
            ),
            const SizedBox(height: 14),

            // Change phone number
            OutlinedPrimaryButton(
              text: 'Change Phone Number'.tr,
              onPressed: () => Get.back(),
            ),
            const SizedBox(height: 36),
          ],
        ),
      ),
    );
  }
}