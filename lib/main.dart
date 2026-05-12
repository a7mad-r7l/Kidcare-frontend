import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:kidcare/views/forgot_password_view.dart';

// الواجهات الأساسية
import 'package:kidcare/views/main_advanced.dart';
import 'package:kidcare/views/login_view.dart';
import 'package:kidcare/views/sign_up_view.dart';
import 'package:kidcare/views/homeView.dart'; // ✅ إضافة

// Sign Up
import 'package:kidcare/controllers/sign_up_controller.dart';
import 'package:kidcare/core/repos/sign_up_repo.dart';

// activation
import 'package:kidcare/views/activation/phone_activation_view.dart';
import 'package:kidcare/views/activation/otp_verification_view.dart';
import 'package:kidcare/views/activation/set_new_password_view.dart';
import 'package:kidcare/controllers/activation_controller.dart';

// Verify OTP
import 'package:kidcare/views/verify_otp_view.dart';
import 'package:kidcare/controllers/verify_otp_controller.dart';
import 'package:kidcare/core/repos/verify_otp_repo.dart';

import 'controllers/forgot_password_controller.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Kidcare',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        scaffoldBackgroundColor: Colors.white,
        fontFamily: 'Roboto',
      ),
      initialRoute: '/',
      getPages: [
        GetPage(name: '/', page: () => const PediatricClinicScreen()),

        GetPage(name: '/login', page: () => const LoginView()),

        // ✅ إضافة route الـ home
        GetPage(name: '/home', page: () => const HomeView()),

        GetPage(
          name: '/register',
          page: () => const SignUpView(),
          binding: BindingsBuilder(() {
            Get.lazyPut<SignUpController>(
                  () => SignUpController(signUpRepo: SignUpRepo()),
            );
          }),
        ),

        // activation
        GetPage(
          name: '/activation-phone',
          page: () => const PhoneActivationView(),
          binding: BindingsBuilder(() {
            Get.lazyPut<ActivationController>(
                  () => ActivationController(),
            );
          }),
        ),

        GetPage(name: '/activation-otp', page: () => const OtpVerificationView()),

        GetPage(name: '/set-password', page: () => const SetNewPasswordView()),

        // Verify OTP
        GetPage(
          name: '/verify-otp',
          page: () => const VerifyOtpView(),
          binding: BindingsBuilder(() {
            Get.lazyPut<VerifyOtpController>(
                  () => VerifyOtpController(verifyOtpRepo: VerifyOtpRepo()),
            );
          }),
        ),
        //   Forgot Password
        GetPage(
          name: '/forgot-password',
          page: () => const ForgotPasswordView(),
          binding: BindingsBuilder(() {
            Get.lazyPut<ForgotPasswordController>(
                  () => ForgotPasswordController(),
            );
          }),
        ),
      ],
    );
  }
}