import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_stripe/flutter_stripe.dart';

import 'package:kidcare/core/helper/secure_storage_service.dart';
import 'package:kidcare/core/localization/app_translations.dart';
import 'package:kidcare/core/repos/home/add_child_repo.dart';
import 'package:kidcare/views/home/add_child_view.dart';
import 'package:kidcare/views/home/appointments_view.dart';
import 'package:kidcare/views/home/child_profile_view.dart';
import 'package:kidcare/views/home/home_view.dart';
import 'package:kidcare/views/home/profile_view.dart';

// الواجهات الأساسية
import 'package:kidcare/views/main_advanced.dart';
import 'package:kidcare/views/auth/login_view.dart';

// Sign Up
import 'package:kidcare/views/auth/sign_up_view.dart';
import 'package:kidcare/core/repos/auth/sign_up_repo.dart';
import 'controllers/appointment/appointment_controller.dart';
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

import 'package:kidcare/controllers/home/child_profile_controller.dart';
import 'package:kidcare/core/repos/home/child_profile_repo.dart';

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

import 'controllers/home/add_child_controller.dart';
import 'controllers/home/appointments_controller.dart';
import 'controllers/home/home_controller.dart';
import 'controllers/home/profile_controller.dart';
import 'controllers/payment_controller.dart';
import 'core/repos/home/appointments_repo.dart';
import 'core/repos/home/home_children_repo.dart';
import 'core/repos/home/parent_name_repo.dart';
import 'core/repos/home/profile_repo.dart';

void main() async {
  // لتهيئة فلاتر قبل تشغيل أي ميزة Native مثل Stripe
  WidgetsFlutterBinding.ensureInitialized();
  Stripe.publishableKey =
      'pk_test_51TVx1BA9J421R1e0fArsBqsC3bNgwlcmhH407ymZp4Ncu9aVgwtEMgXg6lWcswqESufx6ZL7arNccQCdJCHA3QUG00GUsDRB6Q';

  String? savedLang = await SecureStorage.getLanguage();
  Locale initialLocale;
  if (savedLang == null || savedLang == 'system') {
    Locale? deviceLocale = WidgetsBinding.instance.platformDispatcher.locales.isNotEmpty
        ? WidgetsBinding.instance.platformDispatcher.locales.first
        : null;

    if (deviceLocale != null && deviceLocale.languageCode == 'ar') {
      initialLocale = const Locale('ar', 'SA');
    } else {
      initialLocale = const Locale('en', 'US');
    }
  } else if (savedLang == 'ar') {
    initialLocale = const Locale('ar', 'SA');
  } else {
    initialLocale = const Locale('en', 'US');
  }


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

      initialBinding: BindingsBuilder(() {
        Get.lazyPut<AppointmentController>(
          () => AppointmentController(
            repo: AppointmentRepo(),
            doctorRepo: DoctorRepo(),
          ),
          fenix: true,
        );
      }),

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
        GetPage(
          name: '/profile',
          page: () => const ProfileView(),
          binding: BindingsBuilder(() {
            Get.lazyPut(() => ProfileController(profileRepo: ProfileRepo()));
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
          binding: BindingsBuilder(() {
            Get.lazyPut(() => PaymentController());
          }),
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
            Get.lazyPut<HomeController>(
              () => HomeController(
                homeChildrenRepo: HomeChildrenRepo(),
                parentNameRepo: ParentNameRepo(),
              ),
            );

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
            Get.lazyPut(() => DoctorController(repo: DoctorRepo()));

            Get.lazyPut<AppointmentController>(
              () => AppointmentController(
                repo: AppointmentRepo(),
                doctorRepo: DoctorRepo(),
              ),
            );
          }),
        ),

        GetPage(
          name: '/choose-child',
          page: () => const ChooseChildView(),

          binding: BindingsBuilder(() {
            Get.lazyPut<ChildController>(
              () => ChildController(repo: ChildRepo()),
            );
          }),
        ),
        GetPage(
          name: '/choose-date-time',
          page: () => const ChooseDateTimeView(),
        ),

        // Settings
        GetPage(name: '/settings', page: () => const SettingsView()),

        GetPage(
          name: '/appointments',
          page: () => const AppointmentsView(),
          binding: BindingsBuilder(() {
            Get.lazyPut<AppointmentsController>(
              () =>
                  AppointmentsController(appointmentsRepo: AppointmentsRepo()),
            );
          }),
        ),

        GetPage(
          name: '/child-profile',
          page: () => const ChildProfileView(),
          binding: BindingsBuilder(() {
            Get.lazyPut(() => ChildProfileController(repo: ChildProfileRepo()));
          }),
        ),
        GetPage(
          name: '/add-child',
          page: () => const AddChildView(),
          binding: BindingsBuilder(() {
            Get.lazyPut(() => AddChildController(addChildRepo: AddChildRepo()));
          }),
        ),
      ],
    );
  }
}
