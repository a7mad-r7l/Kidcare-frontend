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
      backgroundColor: context.theme.scaffoldBackgroundColor,
      // 👈 إزالة الثيم الصلب
      appBar: AppBar(
        backgroundColor: context.theme.scaffoldBackgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios,
            color: context.theme.iconTheme.color,
            size: 20,
          ),
          onPressed: () => Get.back(),
        ),
        title: Image.asset(
          'assets/images/pediatric_clinic_logo.png',
          height: 38,
          fit: BoxFit.contain,
          // قد تحتاج لاستخدام color ليطابق الوضع الليلي إذا كان الشعار داكناً:
          color: context.isDarkMode ? Colors.white : null,
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 12),
            Text(
              'Create New Account'.tr,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: context.textTheme.bodyLarge?.color, // 👈 لون متكيف
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Create your account to benefit from our services'.tr,
              style: TextStyle(fontSize: 13, color: context.theme.hintColor),
              // 👈 لون متكيف
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
              hintText: 'Enter your name'.tr,
              label: 'Name'.tr,
              labelIcon: Icons.person_outline,
            ),
            const SizedBox(height: 14),

            CustomTextField(
              controller: controller.lastNameController,
              hintText: 'Enter your last name'.tr,
              label: 'Last Name'.tr,
              labelIcon: Icons.person_outline,
            ),
            const SizedBox(height: 14),

            CustomTextField(
              controller: controller.emailController,
              hintText: 'Enter your email'.tr,
              label: 'Email'.tr,
              labelIcon: Icons.mail_outline,
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 14),

            CustomTextField(
              controller: controller.phoneController,
              hintText: 'Enter your phone number'.tr,
              keyboardType: TextInputType.phone,
              label: 'Phone'.tr,
              labelIcon: Icons.phone_outlined,
            ),
            const SizedBox(height: 14),

            CustomTextField(
              controller: controller.addressController,
              hintText: 'Enter your address in detail'.tr,
              label: 'Address'.tr,
              labelIcon: Icons.location_on_outlined,
            ),
            const SizedBox(height: 14),

            Obx(
              () => CustomTextField(
                controller: controller.passwordController,
                hintText: 'Enter your password'.tr,
                isPassword: controller.isPasswordHidden.value,
                label: 'Password'.tr,
                labelIcon: Icons.lock_outline,
                suffixIcon: IconButton(
                  icon: Icon(
                    controller.isPasswordHidden.value
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    color: context.theme.hintColor,
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
                'At least 8 characters with uppercase, lowercase and a number'
                    .tr,
                style: TextStyle(fontSize: 11, color: context.theme.hintColor),
              ),
            ),
            const SizedBox(height: 14),

            Obx(
              () => CustomTextField(
                controller: controller.confirmPasswordController,
                hintText: 'Enter your password again'.tr,
                isPassword: controller.isConfirmPasswordHidden.value,
                label: 'Confirm Password'.tr,
                labelIcon: Icons.lock_outline,
                suffixIcon: IconButton(
                  icon: Icon(
                    controller.isConfirmPasswordHidden.value
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    color: context.theme.hintColor,
                    size: 20,
                  ),
                  onPressed: controller.toggleConfirmPassword,
                ),
              ),
            ),
            const SizedBox(height: 20),

            Obx(
              () => controller.isLoading
                  ? Center(
                      child: CircularProgressIndicator(
                        color: context.theme.primaryColor,
                      ),
                    )
                  : PrimaryButton(
                      text: 'Create Account'.tr,
                      onPressed: controller.signUp,
                    ),
            ),
            const SizedBox(height: 20),

            Row(
              children: [
                Expanded(child: Divider(color: context.theme.dividerColor)),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Text(
                    'Already have an account?'.tr,
                    style: TextStyle(
                      color: context.theme.hintColor,
                      fontSize: 13,
                    ),
                  ),
                ),
                Expanded(child: Divider(color: context.theme.dividerColor)),
              ],
            ),
            const SizedBox(height: 16),

            OutlinedPrimaryButton(
              text: 'Login'.tr,
              onPressed: () => Get.back(),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}
