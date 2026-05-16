import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/reset_password_controller.dart';

class ResetPasswordView extends StatelessWidget {
  // يفضل استخدام Get.put هنا لضمان وجود الكنترولر
  final controller = Get.put(ResetPasswordController());
  
  // استلام الرقم من الواجهة السابقة
  final String phoneNumber = Get.arguments['phone'] ?? ""; 

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
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            Image.asset('assets/images/logo.jpg', height: 100),
            SizedBox(height: 20),
            Text("Create New Password", 
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            SizedBox(height: 10),
            Text("Your new password must be different", 
              style: TextStyle(color: Colors.grey)),
            SizedBox(height: 30),

            // حقل كلمة المرور
            Obx(() => TextField(
              controller: controller.passwordController,
              obscureText: !controller.isPasswordVisible.value,
              decoration: InputDecoration(
                hintText: "Password",
                prefixIcon: Icon(Icons.lock_outline),
                suffixIcon: IconButton(
                  icon: Icon(controller.isPasswordVisible.value 
                      ? Icons.visibility 
                      : Icons.visibility_off),
                  onPressed: () => controller.isPasswordVisible.toggle(),
                ),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
              ),
            )),
            
            SizedBox(height: 20),

            // حقل تأكيد كلمة المرور
            Obx(() => TextField(
              controller: controller.confirmPasswordController,
              obscureText: !controller.isConfirmVisible.value,
              decoration: InputDecoration(
                hintText: "Confirm Password",
                prefixIcon: Icon(Icons.lock_outline),
                suffixIcon: IconButton(
                  icon: Icon(controller.isConfirmVisible.value 
                      ? Icons.visibility 
                      : Icons.visibility_off),
                  onPressed: () => controller.isConfirmVisible.toggle(),
                ),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
              ),
            )),

            SizedBox(height: 40),

            // زر التحديث مع مراقبة حالة التحميل
            Obx(() => SizedBox(
              width: double.infinity, 
              height: 55,
              child: ElevatedButton(
                // تعطيل الزر أثناء التحميل
                onPressed: controller.isLoading 
                    ? null 
                    : () => controller.updatePassword(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFF4A86D1),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                ),
                child: controller.isLoading 
                    ? CircularProgressIndicator(color: Colors.white)
                    : Text("Update Password", 
                        style: TextStyle(color: Colors.white, fontSize: 18)),
              ),
            )),

            SizedBox(height: 50),
            Image.asset('assets/images/lock_logo.jpg', height: 150)
          ],
        ),
      ),
    );
  }
}