import 'dart:convert';
import 'package:get/get.dart';
import 'package:flutter/material.dart';

class BaseController extends GetxController {
  final _isLoading = false.obs;
  bool get isLoading => _isLoading.value;

  void showLoading() => _isLoading.value = true;
  void hideLoading() => _isLoading.value = false;

  void handleError(dynamic e) {
    hideLoading();

    String errorString = e.toString();
    String message = "Something went wrong. Please try again.";

    try {
      // 1. حالة الـ 401 — انتهت الجلسة
      if (errorString.contains("401")) {
        message = "Session expired. Please login again.";
        Get.snackbar(
          "Error",
          message,
          backgroundColor: Colors.red.shade800,
          colorText: Colors.white,
          snackPosition: SnackPosition.BOTTOM,
          margin: const EdgeInsets.all(15),
          icon: const Icon(Icons.error_outline, color: Colors.white),
          duration: const Duration(seconds: 4),
        );
        // ✅ توجيه المستخدم لـ login وحذف كل الـ routes السابقة
        Get.offAllNamed('/login');
        return;
      }
      // 2. إذا كان الخطأ يحتوي على JSON
      else if (errorString.contains('{') && errorString.contains('}')) {
        int startIndex = errorString.indexOf('{');
        int endIndex = errorString.lastIndexOf('}') + 1;
        String jsonPart = errorString.substring(startIndex, endIndex);

        var decoded = jsonDecode(jsonPart);
        if (decoded['message'] != null) {
          message = decoded['message'];
        }
      }
      // 3. Exception مخصص
      else if (errorString.contains("Exception:")) {
        message = errorString.split("Exception:").last.trim();
      }
      // 4. حالات الشبكة
      else if (errorString.contains("SocketException")) {
        message = "No Internet connection. Please check your network.";
      }
    } catch (parseError) {
      message = "Authentication failed. Please check your credentials.";
    }

    Get.snackbar(
      "Error",
      message,
      backgroundColor: Colors.red.shade800,
      colorText: Colors.white,
      snackPosition: SnackPosition.BOTTOM,
      margin: const EdgeInsets.all(15),
      icon: const Icon(Icons.error_outline, color: Colors.white),
      duration: const Duration(seconds: 4),
    );
  }
}