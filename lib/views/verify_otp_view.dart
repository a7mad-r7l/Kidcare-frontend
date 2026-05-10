import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/verify_otp_controller.dart';
import '../widgets/custom_text_field.dart';
import '../controllers/base_controller.dart';

class VerifyOtpView extends GetView<VerifyOtpController> {
  const VerifyOtpView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios,
            color: Colors.black87,
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

            const Text(
              'Verify Your Phone Number',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),

            Text(
              'We sent a 4-digit verification code to',
              style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              controller.maskedPhone,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: Colors.blue.shade700,
              ),
            ),
            const SizedBox(height: 36),

            // OTP Boxes
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
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                  children: [
                    const TextSpan(text: 'The code is valid for '),
                    TextSpan(
                      text: controller.validityFormatted,
                      style: TextStyle(
                        color: Colors.blue.shade600,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const TextSpan(text: ' minutes'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 28),

            // Resend section
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Didn't receive the code?",
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'You can resend the code after the countdown ends',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade500,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Obx(
                              () => controller.canResend.value
                              ? GestureDetector(
                            onTap: controller.resendOtp,
                            child: Text(
                              'Resend Code',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.blue.shade600,
                              ),
                            ),
                          )
                              : Text(
                            controller.resendFormatted,
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue.shade600,
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
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.chat_bubble_outline,
                      color: Colors.blue.shade600,
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
                  ? const Center(
                child: CircularProgressIndicator(color: Colors.blue),
              )
                  : PrimaryButton(
                text: 'Verify',
                onPressed: controller.verifyOtp,
              ),
            ),
            const SizedBox(height: 14),

            // Change phone number
            OutlinedPrimaryButton(
              text: 'Change Phone Number',
              onPressed: () => Get.back(),
            ),
            const SizedBox(height: 36),
          ],
        ),
      ),
    );
  }
}