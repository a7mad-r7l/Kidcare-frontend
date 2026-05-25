import 'package:flutter/material.dart';
import 'package:get/get.dart';

class SuccessResetView extends StatelessWidget {
  const SuccessResetView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(25.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset('assets/images/green_checkmark.jpg', height: 200),

              const SizedBox(height: 40),

              // العنوان الرئيسي
              const Text(
                "Password Updated!",
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1D2755),
                ),
              ),

              const SizedBox(height: 15),

              // الوصف
              const Text(
                "Your password has been updated successfully. You can now log in with your new password.",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.grey, height: 1.5),
              ),

              const SizedBox(height: 50),

              // زر الذهاب لتسجيل الدخول
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: () {
                    // العودة لصفحة تسجيل الدخول ومسح كل الصفحات السابقة من الذاكرة
                    Get.offAllNamed('/login');
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4A86D1),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                  child: const Text(
                    "Back to Login",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 40),

              // صورة الطفل (الولد) في الأسفل
              Image.asset('assets/images/child_welcome.jpg', height: 200),
            ],
          ),
        ),
      ),
    );
  }
}
