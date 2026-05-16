import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pinput/pinput.dart';
import '../controllers/otp_controller.dart';

class OtpView extends StatelessWidget {
  final controller = Get.put(OtpController());
  
  // استقبال الرقم الديناميكي من الواجهة السابقة
  final String phoneNumber = Get.arguments ?? "No Number Provided"; 

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent, 
        elevation: 0, 
        leading: BackButton(color: Colors.black)
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            children: [
              // اللوغو
              Image.asset('assets/images/logo.jpg', height: 100),
              SizedBox(height: 20),
              
              Text("Verify Your Number", 
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              SizedBox(height: 10),
              
              Text("We sent a 4-digit code to", 
                style: TextStyle(color: Colors.grey)),
              
              // عرض الرقم الديناميكي هنا
              Text(phoneNumber, 
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              
              SizedBox(height: 40),
              
              // مربعات الـ OTP
              Pinput(
                length: 4,
                controller: controller.otpController,
                defaultPinTheme: PinTheme(
                  width: 65, height: 65,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.blue.shade100),
                  ),
                  textStyle: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
              ),
              
              SizedBox(height: 30),
              
              // المؤقت التنازلي
              Obx(() => Column(
                children: [
                  Text("Didn't receive the code?", 
                    style: TextStyle(color: Colors.grey)),
                  TextButton(
                    onPressed: controller.secondsRemaining.value == 0 
                        ? () => controller.startTimer() 
                        : null,
                    child: Text(
                      controller.secondsRemaining.value == 0 
                        ? "Resend Code" 
                        : "Resend in (00:${controller.secondsRemaining.value.toString().padLeft(2, '0')})",
                    ),
                  ),
                ],
              )),
              
              SizedBox(height: 40),
              
              // زر التأكيد
              SizedBox(
                width: double.infinity, height: 55,
                child: ElevatedButton(
                  onPressed: () => controller.verifyCode(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF4A86D1),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  ),
                  child: Text("Verify", 
                    style: TextStyle(color: Colors.white, fontSize: 18)),
                ),
              ),
              
              SizedBox(height: 50),
              
              // صورة الدرع بالأسفل
              Image.asset('assets/images/shield_logo.jpg', height: 120),
            ],
          ),
        ),
      ),
    );
  }
}