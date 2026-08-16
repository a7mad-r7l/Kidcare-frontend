import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../controllers/auth/forgot_password_controller.dart';

class ForgotPasswordView extends GetView<ForgotPasswordController> {
  const ForgotPasswordView({super.key});

  @override
  Widget build(BuildContext context) {
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
              Image.asset('assets/images/logo.png', height: 120),
              const SizedBox(height: 20),
              Text(
                "Forgot Password?".tr,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: context.textTheme.bodyLarge?.color,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                "Don't worry, enter your phone number and we will send you a verification code."
                    .tr,
                textAlign: TextAlign.center,
                style: TextStyle(color: context.theme.hintColor),
              ),
              const SizedBox(height: 40),
              Align(
                alignment:AlignmentDirectional.topStart,
                child: Text(
                  "Phone Number".tr,
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: controller.phoneController,
                keyboardType: TextInputType.phone,
                style: TextStyle(color: context.textTheme.bodyLarge?.color),
                decoration: InputDecoration(
                  hintText: '9639XXXXXXXX',
                  filled: true,
                  fillColor: context.theme.cardColor,
                  hintStyle: const TextStyle(color: Colors.grey),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
              ),
              const SizedBox(height: 30),


              Obx(
                () => SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: ElevatedButton(
                    onPressed: controller.isLoading
                        ? null
                        : () => controller.sendCode(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4A86D1),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                    ),
                    child: controller.isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : Text(
                            "Send Verification Code".tr,
                            style: TextStyle(fontSize: 18, color: Colors.white),
                          ),
                  ),
                ),
              ),

              const SizedBox(height: 40),
              Image.asset('assets/images/child_welcome.png'),
            ],
          ),
        ),
      ),
    );
  }
}
