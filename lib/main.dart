import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:kidcare/views/login_view.dart';

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
      initialRoute: '/login',
      getPages: [
        GetPage(name: '/login', page: () => const LoginView()),

      ],
    );
  }
}
