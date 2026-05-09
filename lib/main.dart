import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:kidcare/views/main_advanced.dart';
import 'package:kidcare/views/login_view.dart';
import 'package:kidcare/views/sign_up_view.dart';
import 'package:kidcare/views/verify_otp_view.dart';
import 'package:kidcare/controllers/sign_up_controller.dart';
import 'package:kidcare/controllers/verify_otp_controller.dart';
import 'package:kidcare/core/repos/sign_up_repo.dart';
import 'package:kidcare/core/repos/verify_otp_repo.dart';

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
          name: '/verify-otp',
          page: () => const VerifyOtpView(),
          binding: BindingsBuilder(() {
            Get.lazyPut<VerifyOtpController>(
              () => VerifyOtpController(verifyOtpRepo: VerifyOtpRepo()),
            );
          }),
        ),
      ],
    );
  }
}
