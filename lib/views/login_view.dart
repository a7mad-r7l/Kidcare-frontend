import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/login_controller.dart';
import '../widgets/custom_text_field.dart';

class LoginView extends StatelessWidget {
  const LoginView({super.key});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Directionality(
      textDirection: TextDirection.ltr,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),


              child: GetBuilder<LoginController>(
                init: LoginController(),
                builder: (controller) {
                  return Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Image.asset(
                        'assets/images/logo.jpg',
                        height: size.height * 0.25,
                        fit: BoxFit.contain,
                      ),
                      SizedBox(height: size.height * 0.02),

                      const Text('Welcome Back', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black87)),
                      const SizedBox(height: 8),
                      const Text('Sign in to continue', style: TextStyle(fontSize: 14, color: Colors.grey)),
                      SizedBox(height: size.height * 0.04),

                      CustomTextField(
                        controller: controller.phoneController,
                        hintText: 'Phone Number',
                        keyboardType: TextInputType.phone,
                      ),
                      const SizedBox(height: 16),

                      CustomTextField(
                        controller: controller.passwordController,
                        hintText: 'Password',
                        isPassword: controller.isPasswordHidden,
                        suffixIcon: IconButton(
                          icon: Icon(
                            controller.isPasswordHidden ? Icons.visibility_off : Icons.visibility,
                            color: Colors.grey,
                          ),
                          onPressed: controller.togglePasswordVisibility,
                        ),
                      ),
                      const SizedBox(height: 8),

                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () {
                            // Get.toNamed('/forget_password');
                          },
                          child: const Text('Forgot Password?', style: TextStyle(color: Colors.blue, fontSize: 13)),
                        ),
                      ),
                      SizedBox(height: size.height * 0.03),

                      controller.isLoading
                          ? const CircularProgressIndicator(color: Colors.blue)
                          : PrimaryButton(
                        text: 'Login',
                        onPressed: controller.login,
                      ),

                      SizedBox(height: size.height * 0.03),

                      const Text('Or', style: TextStyle(color: Colors.grey, fontSize: 14)),
                      SizedBox(height: size.height * 0.03),

                      OutlinedPrimaryButton(
                        text: 'Create New Account',
                        onPressed: () {
                          // Get.toNamed('/register');
                        },
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}