import 'package:flutter/material.dart';
import 'package:get/get.dart';

class SuccessResetView extends StatelessWidget {
  const SuccessResetView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(25.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset('assets/images/green_checkmark.png', height: 200),

              // يفضل استخدام .png شفافة
              const SizedBox(height: 40),

              // العنوان الرئيسي
              Text(
                "Password Updated!",
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: context.textTheme.bodyLarge?.color,
                ),
              ),

              const SizedBox(height: 15),

              // الوصف
              Text(
                "Your password has been updated successfully. You can now log in with your new password."
                    .tr,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: context.theme.hintColor,
                  height: 1.5,
                ),
              ),

              const SizedBox(height: 50),

              // زر الذهاب لتسجيل الدخول
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: () {
                    Get.offAllNamed('/login');
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: context.theme.primaryColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                  child: Text(
                    "Back to Login".tr,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 40),

              Image.asset('assets/images/child_welcome.png', height: 200),
            ],
          ),
        ),
      ),
    );
  }
}
