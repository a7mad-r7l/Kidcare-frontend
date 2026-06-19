import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/auth/login_controller.dart';
import '../../controllers/settings_controller.dart';
import '../../core/repos/auth/login_repo.dart';
import '../../widgets/custom_text_field.dart';
// تأكد من استيراد الأزرار المخصصة هنا (PrimaryButton و OutlinedPrimaryButton)

class LoginView extends StatelessWidget {
  const LoginView({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(LoginController(loginRepo: LoginRepo()));
    final size = MediaQuery.of(context).size;
    final settingsController = Get.put(SettingsController());

    // ─── إجبار الواجهة بالكامل على الوضع الفاتح ───
    return Theme(
      data: ThemeData.light().copyWith(
        scaffoldBackgroundColor: Colors.white,
        primaryColor: const Color(0xFF1A2E5A),
        colorScheme: const ColorScheme.light(
          primary: Color(0xFF1A2E5A),
          onSurface: Colors.black, // لضمان أن النصوص الافتراضية باللون الأسود
        ),
        textTheme: ThemeData.light().textTheme.apply(
          bodyColor: Colors.black,
          displayColor: Colors.black,
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          actions: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12.0),
              child: Obx(() {
                final isArabic = settingsController.currentLanguage.value == 'ar';
                return TextButton.icon(
                  icon: const Icon(Icons.language, size: 20, color: Color(0xFF4A86D1)),
                  label: Text(
                    isArabic ? 'English' : 'العربية',
                    style: const TextStyle(
                      color: Color(0xFF4A86D1),
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  onPressed: () {
                    settingsController.changeLanguage(isArabic ? 'en' : 'ar');
                  },
                );
              }),
            ),
          ],
        ),
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset(
                    'assets/images/logo.jpg',
                    height: size.height * 0.25,
                  ),
                  const SizedBox(height: 20),
                  // إجبار النص على اللون الأسود لضمان التباين
                  Text(
                    'Welcome Back'.tr,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 40),

                  CustomTextField(
                    controller: controller.phoneController,
                    hintText: 'Phone Number'.tr,
                    keyboardType: TextInputType.phone,
                  ),
                  const SizedBox(height: 16),

                  Obx(
                        () => CustomTextField(
                      controller: controller.passwordController,
                      hintText: 'Password'.tr,
                      isPassword: controller.isPasswordHidden.value,
                      suffixIcon: IconButton(
                        icon: Icon(
                          controller.isPasswordHidden.value
                              ? Icons.visibility_off
                              : Icons.visibility,
                          color: Colors.grey, // تثبيت لون الأيقونة
                        ),
                        onPressed: controller.togglePasswordVisibility,
                      ),
                    ),
                  ),

                  Align(
                    alignment: AlignmentDirectional.topStart,
                    child: TextButton(
                      onPressed: () {
                        Get.toNamed('/forgot-password');
                      },
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.only(top: 8, bottom: 8),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: Text(
                        'Forgot Password?'.tr,
                        style: const TextStyle(
                          color: Colors.blue,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  Obx(
                        () => controller.isLoading
                        ? const CircularProgressIndicator()
                        : PrimaryButton(
                      text: 'Login'.tr,
                      onPressed: controller.login,
                    ),
                  ),
                  const SizedBox(height: 30),
                  Row(
                    children: [
                      const Expanded(
                        child: Divider(thickness: 1, color: Colors.grey),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        child: Text(
                          'Or'.tr,
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 14,
                          ),
                        ),
                      ),
                      const Expanded(
                        child: Divider(thickness: 1, color: Colors.grey),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),
                  OutlinedPrimaryButton(
                    text: 'Create New Account'.tr,
                    onPressed: () => Get.toNamed('/register'),
                  ),

                  const SizedBox(height: 12),

                  TextButton(
                    onPressed: () => Get.toNamed('/activation-phone'),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                    child: RichText(
                      text: TextSpan(
                        text: "Have a clinic file? ".tr,
                        style: const TextStyle(color: Colors.grey, fontSize: 14),
                        children: [
                          TextSpan(
                            text: "Activate account".tr,
                            style: const TextStyle(
                              color: Colors.blue,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}