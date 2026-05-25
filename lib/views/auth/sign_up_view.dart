import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/auth/sign_up_controller.dart';
import '../../widgets/custom_text_field.dart';

class SignUpView extends StatelessWidget {
  const SignUpView({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<SignUpController>();
    final size = MediaQuery.of(context).size;

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
        title: Image.asset(
          'assets/images/pediatric_clinic_logo.png',
          height: 38,
          fit: BoxFit.contain,
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 12),
            const Text(
              'Create New Account',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Create your account to benefit from our services',
              style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Image.asset(
              'assets/images/doctor_and_children.png',
              height: size.height * 0.18,
              fit: BoxFit.contain,
            ),
            const SizedBox(height: 24),

            CustomTextField(
              controller: controller.firstNameController,
              hintText: 'Enter your name',
              label: 'Name',
              labelIcon: Icons.person_outline,
            ),
            const SizedBox(height: 14),

            CustomTextField(
              controller: controller.lastNameController,
              hintText: 'Enter your last name',
              label: 'Last Name',
              labelIcon: Icons.person_outline,
            ),
            const SizedBox(height: 14),

            CustomTextField(
              controller: controller.emailController,
              hintText: 'Enter your email',
              label: 'Email',
              labelIcon: Icons.mail_outline,
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 14),

            CustomTextField(
              controller: controller.phoneController,
              hintText: 'Enter your phone number',
              keyboardType: TextInputType.phone,
              label: 'Phone',
              labelIcon: Icons.phone_outlined,
            ),
            const SizedBox(height: 14),

            CustomTextField(
              controller: controller.addressController,
              hintText: 'Enter your address in detail',
              label: 'Address',
              labelIcon: Icons.location_on_outlined,
            ),
            const SizedBox(height: 14),

            Obx(
              () => CustomTextField(
                controller: controller.passwordController,
                hintText: 'Enter your password',
                isPassword: controller.isPasswordHidden.value,
                label: 'Password',
                labelIcon: Icons.lock_outline,
                suffixIcon: IconButton(
                  icon: Icon(
                    controller.isPasswordHidden.value
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    color: Colors.grey.shade500,
                    size: 20,
                  ),
                  onPressed: controller.togglePassword,
                ),
              ),
            ),
            const SizedBox(height: 6),
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                'At least 8 characters with uppercase, lowercase and a number',
                style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
              ),
            ),
            const SizedBox(height: 14),

            Obx(
              () => CustomTextField(
                controller: controller.confirmPasswordController,
                hintText: 'Enter your password again',
                isPassword: controller.isConfirmPasswordHidden.value,
                label: 'Confirm Password',
                labelIcon: Icons.lock_outline,
                suffixIcon: IconButton(
                  icon: Icon(
                    controller.isConfirmPasswordHidden.value
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    color: Colors.grey.shade500,
                    size: 20,
                  ),
                  onPressed: controller.toggleConfirmPassword,
                ),
              ),
            ),
            const SizedBox(height: 20),

            Obx(
              () => controller.isLoading
                  ? const Center(
                      child: CircularProgressIndicator(color: Colors.blue),
                    )
                  : PrimaryButton(
                      text: 'Create Account',
                      onPressed: controller.signUp,
                    ),
            ),
            const SizedBox(height: 20),

            Row(
              children: [
                Expanded(child: Divider(color: Colors.grey.shade300)),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Text(
                    'Already have an account?',
                    style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
                  ),
                ),
                Expanded(child: Divider(color: Colors.grey.shade300)),
              ],
            ),
            const SizedBox(height: 16),

            OutlinedPrimaryButton(text: 'LogIn', onPressed: () => Get.back()),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}
