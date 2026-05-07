import 'package:get/get.dart';
import 'package:flutter/material.dart';

class BaseController extends GetxController {
  // استخدام .obs لجعل حالة التحميل Reactive
  final _isLoading = false.obs;
  bool get isLoading => _isLoading.value;

  void showLoading() => _isLoading.value = true;
  void hideLoading() => _isLoading.value = false;

  // دالة موحدة لعرض رسائل الأخطاء
  void handleError(dynamic e) {
    hideLoading();
    String message = "";

    // يمكنك تخصيص الرسائل بناءً على محتوى الخطأ القادم من السيرفر
    if (e.toString().contains("401")) {
      message = "Unauthorized: Please check your credentials.";
    } else if (e.toString().contains("SocketException")) {
      message = "No Internet connection.";
    } else {
      message = e.toString().replaceAll("Exception:", "").trim();
    }

    Get.snackbar(
      "Error",
      message,
      backgroundColor: Colors.redAccent,
      colorText: Colors.white,
      snackPosition: SnackPosition.BOTTOM,
    );
  }
}