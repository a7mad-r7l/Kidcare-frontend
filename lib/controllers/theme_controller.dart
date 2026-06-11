import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ThemeController extends GetxController {
  // حالة المتغير لمراقبة الوضع الحالي
  final RxBool isDarkMode = false.obs;

  @override
  void onInit() {
    super.onInit();
    // قراءة حالة النظام الحالية عند بدء التطبيق
    isDarkMode.value = Get.isDarkMode;
  }

  void toggleTheme() {
    // تبديل القيمة
    isDarkMode.value = !isDarkMode.value;

    // أمر GetX بتغيير السمة في كامل التطبيق فوراً
    Get.changeThemeMode(isDarkMode.value ? ThemeMode.dark : ThemeMode.light);
  }
}