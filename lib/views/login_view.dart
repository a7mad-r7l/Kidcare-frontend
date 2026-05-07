import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/login_controller.dart';
import '../core/repos/login_repo.dart';
import '../widgets/custom_text_field.dart';

class LoginView extends StatelessWidget {
  const LoginView({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(LoginController(loginRepo: LoginRepo()));
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: Colors.white,
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
                const Text(
                  'Welcome Back',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 40),

                CustomTextField(
                  controller: controller.phoneController,
                  hintText: 'Phone Number',
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 16),

                Obx(
                  () => CustomTextField(
                    controller: controller.passwordController,
                    hintText: 'Password',
                    isPassword: controller.isPasswordHidden.value,
                    suffixIcon: IconButton(
                      icon: Icon(
                        controller.isPasswordHidden.value
                            ? Icons.visibility_off
                            : Icons.visibility,
                      ),
                      onPressed: controller.togglePasswordVisibility,
                    ),
                  ),
                ),

                const SizedBox(height: 30),

                Obx(
                  () => controller.isLoading
                      ? const CircularProgressIndicator()
                      : PrimaryButton(
                          text: 'Login',
                          onPressed: controller.login,
                        ),
                ),

                const SizedBox(height: 20),
                OutlinedPrimaryButton(
                  text: 'Create New Account',
                  onPressed: () => Get.toNamed('/register'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
