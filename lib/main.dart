import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:kidcare/views/forgot_password_view.dart';

// الواجهات الأساسية
import 'package:kidcare/views/main_advanced.dart';
import 'package:kidcare/views/login_view.dart';
import 'package:kidcare/views/sign_up_view.dart';

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

//  واجهات الدفع

import 'package:kidcare/views/payment/payment_method_view.dart';
import 'package:kidcare/views/payment/checkout_summary_view.dart';
import 'package:kidcare/views/payment/payment_success_view.dart';

void main() async {
  //  لتهيئة فلاتر قبل تشغيل أي ميزة Native مثل Stripe
  WidgetsFlutterBinding.ensureInitialized();

  Stripe.publishableKey = 'pk_test_';
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
      // initialRoute: '/',
      initialRoute: '/payment-method',
      getPages: [
        GetPage(name: '/', page: () => const PediatricClinicScreen()),

        GetPage(name: '/login', page: () => const LoginView()),

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
            Get.lazyPut<ActivationController>(() => ActivationController());
          }),
        ),

        GetPage(
          name: '/activation-otp',
          page: () => const OtpVerificationView(),
        ),

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
          page: () => ForgotPasswordView(),
          binding: BindingsBuilder(() {
            Get.lazyPut<ForgotPasswordController>(
              () => ForgotPasswordController(),
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
        //  Payment Routes
        GetPage(name: '/payment-method', page: () => const PaymentMethodView()),
        GetPage(
          name: '/checkout-summary',
          page: () => const CheckoutSummaryView(),
        ),
        GetPage(
          name: '/payment-success',
          page: () => const PaymentSuccessView(),
        ),
      ],
    );
  }
}