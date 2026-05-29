import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_stripe/flutter_stripe.dart';

// 🌟 استيرادات اللغات والتخزين (تمت إضافتها)
import 'package:kidcare/core/helper/secure_storage_service.dart';
import 'package:kidcare/core/localization/app_translations.dart';
import 'package:kidcare/views/home/home_view.dart';

// الواجهات الأساسية
import 'package:kidcare/views/main_advanced.dart';
import 'package:kidcare/views/auth/login_view.dart';

// Sign Up
import 'package:kidcare/views/auth/sign_up_view.dart';
import 'package:kidcare/core/repos/auth/sign_up_repo.dart';
import 'controllers/auth/sign_up_controller.dart';

// Activation
import 'package:kidcare/views/auth/activation/otp_verification_view.dart';
import 'package:kidcare/views/auth/activation/phone_activation_view.dart';
import 'package:kidcare/views/auth/activation/set_new_password_view.dart';
import 'controllers/auth/activation_controller.dart';

// Verify OTP
import 'package:kidcare/views/auth/verify_otp_view.dart';
import 'package:kidcare/core/repos/auth/verify_otp_repo.dart';
import 'controllers/auth/verify_otp_controller.dart';

// Forgot Password
import 'package:kidcare/views/auth/forget_password/forgot_password_view.dart';
import 'package:kidcare/views/auth/forget_password/otp_view.dart';
import 'package:kidcare/views/auth/forget_password/reset_password_view.dart';
import 'package:kidcare/views/auth/forget_password/success_reset_view.dart';
import 'controllers/auth/forgot_password_controller.dart';

// Payment Routes
import 'package:kidcare/views/payment/payment_method_view.dart';
import 'package:kidcare/views/payment/checkout_summary_view.dart';
import 'package:kidcare/views/payment/payment_success_view.dart';


// Appointment Booking

import 'package:kidcare/views/appointment/choose_doctor_view.dart';
import 'package:kidcare/views/appointment/choose_child_view.dart';
import 'package:kidcare/views/appointment/choose_date_time_view.dart';
import 'package:kidcare/controllers/appointment/department_controller.dart';
import 'package:kidcare/controllers/appointment/doctor_controller.dart';
import 'package:kidcare/controllers/appointment/child_controller.dart';
import 'package:kidcare/controllers/appointment/my_appointments_controller.dart';
import 'package:kidcare/core/repos/appointment/department_repo.dart';
import 'package:kidcare/core/repos/appointment/doctor_repo.dart';
import 'package:kidcare/core/repos/appointment/child_repo.dart';
import 'package:kidcare/core/repos/appointment/appointment_repo.dart';


import 'package:kidcare/views/settings/settings_view.dart';



void main() async {
  // لتهيئة فلاتر قبل تشغيل أي ميزة Native مثل Stripe
  WidgetsFlutterBinding.ensureInitialized();
  Stripe.publishableKey = 'pk_test_';


  String? savedLang = await SecureStorage.getLanguage();
  Locale initialLocale = savedLang == 'ar'
      ? const Locale('ar', 'SA')
      : const Locale('en', 'US');


  runApp(MyApp(initialLocale: initialLocale));
}

class MyApp extends StatelessWidget {
  final Locale initialLocale;

  const MyApp({super.key, required this.initialLocale});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Kidcare',
      debugShowCheckedModeBanner: false,

      //  Localization
      translations: AppTranslations(),
      locale: initialLocale,
      fallbackLocale: const Locale('en', 'US'),

      theme: ThemeData(
        primarySwatch: Colors.blue,
        scaffoldBackgroundColor: Colors.white,
        fontFamily: 'Roboto',
      ),

      initialRoute: '/',
      getPages: [
        GetPage(name: '/', page: () => const PediatricClinicScreen()),

        // login
        GetPage(name: '/login', page: () => const LoginView()),

        // Sign Up
        GetPage(
          name: '/register',
          page: () => const SignUpView(),
          binding: BindingsBuilder(() {
            Get.lazyPut<SignUpController>(
                  () => SignUpController(signUpRepo: SignUpRepo()),
            );
          }),
        ),

        // Activation
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

        //  OTP
        GetPage(
          name: '/verify-otp',
          page: () => const VerifyOtpView(),
          binding: BindingsBuilder(() {
            Get.lazyPut<VerifyOtpController>(
                  () => VerifyOtpController(verifyOtpRepo: VerifyOtpRepo()),
            );
          }),
        ),

        // Forgot Password
        GetPage(
          name: '/forgot-password',
          page: () => const ForgotPasswordView(),
          binding: BindingsBuilder(() {
            Get.lazyPut<ForgotPasswordController>(
                  () => ForgotPasswordController(),
            );
          }),
        ),
        GetPage(name: '/forgot-otp', page: () => const OtpView()),
        GetPage(name: '/reset-password', page: () => const ResetPasswordView()),
        GetPage(name: '/success-reset', page: () => SuccessResetView()),

        //  Payment
        GetPage(name: '/payment-method', page: () => const PaymentMethodView()),
        GetPage(
          name: '/checkout-summary',
          page: () => const CheckoutSummaryView(),
        ),
        GetPage(
          name: '/payment-success',
          page: () => const PaymentSuccessView(),
        ),


        // Home
        GetPage(
          name: '/home',
          page: () => const HomeView(),
          binding: BindingsBuilder(() {
            Get.lazyPut<ChildController>(
              () => ChildController(repo: ChildRepo()),
            );
            Get.lazyPut<MyAppointmentsController>(
              () => MyAppointmentsController(
                repo: AppointmentRepo(),
                doctorRepo: DoctorRepo(),
                childRepo: ChildRepo(),
              ),
            );
          }),
        ),

        // Appointment Booking
        GetPage(
          name: '/choose-doctor',
          page: () => const ChooseDoctorView(),
          binding: BindingsBuilder(() {
            Get.lazyPut<DepartmentController>(
              () => DepartmentController(repo: DepartmentRepo()),
            );
            Get.lazyPut<DoctorController>(
              () => DoctorController(repo: DoctorRepo()),
            );
          }),
        ),
        // ChildController is already alive from /home — no new binding needed.
        // Re-registering would create a second instance that never sees the
        // home-scope data and breaks cache coherence.
        GetPage(
          name: '/choose-child',
          page: () => const ChooseChildView(),
        ),
        GetPage(
          name: '/choose-date-time',
          page: () => const ChooseDateTimeView(),
        ),

        // Settings
        GetPage(name: '/settings', page: () => const SettingsView()),

      ],
    );
  }
}