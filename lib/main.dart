import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:kidcare/views/forgot_password_view.dart';
import 'package:kidcare/core/helper/secure_storage_service.dart';

// الواجهات الأساسية
import 'package:kidcare/views/main_advanced.dart';
import 'package:kidcare/views/login_view.dart';
import 'package:kidcare/views/sign_up_view.dart';
import 'package:kidcare/views/HomeView.dart';
import 'package:kidcare/views/child_profile_view.dart';

// user profile
import 'package:kidcare/views/ProfileView.dart';
import 'package:kidcare/controllers/profile_controller.dart';
import 'package:kidcare/core/repos/profile_repo.dart';

// add new child
import 'package:kidcare/views/AddChildView.dart';
import 'package:kidcare/controllers/AddChildController.dart';
import 'package:kidcare/core/repos/AddChildRepo.dart';

// age and name child
import '../controllers/HomeController.dart';
import 'core/repos/HomeChildrenRepo.dart';
import 'package:kidcare/core/repos/ParentNameRepo.dart';

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

// واجهات الدفع
import 'package:kidcare/views/payment/payment_method_view.dart';
import 'package:kidcare/views/payment/checkout_summary_view.dart';
import 'package:kidcare/views/payment/payment_success_view.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  Stripe.publishableKey = 'pk_test_';

  final token = await SecureStorage.getToken();
  final hasToken = token.isNotEmpty; // ✅

  runApp(MyApp(hasToken: hasToken));
}

class MyApp extends StatelessWidget {
  final bool hasToken; // ✅

  const MyApp({super.key, required this.hasToken});

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
      initialRoute: '/', // ✅ دائماً يبدأ بالـ Animation
      getPages: [
        // ✅ نمرر hasToken للـ Animation
        GetPage(
          name: '/',
          page: () => PediatricClinicScreen(hasToken: hasToken),
        ),

        GetPage(name: '/login', page: () => const LoginView()),

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
          }),
        ),

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
          name: '/activation-phone',
          page: () => const PhoneActivationView(),
          binding: BindingsBuilder(() {
            Get.lazyPut<ActivationController>(() => ActivationController());
          }),
        ),

        GetPage(name: '/activation-otp', page: () => const OtpVerificationView()),

        GetPage(name: '/set-password', page: () => const SetNewPasswordView()),

        GetPage(
          name: '/verify-otp',
          page: () => const VerifyOtpView(),
          binding: BindingsBuilder(() {
            Get.lazyPut<VerifyOtpController>(
                  () => VerifyOtpController(verifyOtpRepo: VerifyOtpRepo()),
            );
          }),
        ),

        GetPage(
          name: '/forgot-password',
          page: () => const ForgotPasswordView(),
          binding: BindingsBuilder(() {
            Get.lazyPut<ForgotPasswordController>(
                  () => ForgotPasswordController(),
            );
          }),
        ),

        GetPage(
          name: '/profile',
          page: () => const ProfileView(),
          binding: BindingsBuilder(() {
            Get.lazyPut<ProfileController>(
                  () => ProfileController(profileRepo: ProfileRepo()),
            );
          }),
        ),

        GetPage(
          name: '/child-profile',
          page: () => const ChildProfileView(),
        ),

        GetPage(
          name: '/add-child',
          page: () => const AddChildView(),
          binding: BindingsBuilder(() {
            Get.lazyPut<AddChildController>(
                  () => AddChildController(addChildRepo: AddChildRepo()),
            );
          }),
        ),

        GetPage(name: '/payment-method', page: () => const PaymentMethodView()),
        GetPage(name: '/checkout-summary', page: () => const CheckoutSummaryView()),
        GetPage(name: '/payment-success', page: () => const PaymentSuccessView()),
      ],
    );
  }
}