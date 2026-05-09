import 'dart:convert';

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

    // تحويل الخطأ إلى نص
    String errorString = e.toString();
    String message = "Something went wrong. Please try again.";

    try {
      // 1.حالة الـ 401 نضع رسالتنا  ونتجاهل رسالة السيرفر
      if (errorString.contains("401")) {
        message = "Incorrect phone number or password.";
      }
      // 2. إذا كان الخطأ يحتوي على JSON (لأي خظأ عدا خظأ 401)
      else if (errorString.contains('{') && errorString.contains('}')) {
        // نستخرج الجزء الذي يشبه الـ JSON فقط من النص
        int startIndex = errorString.indexOf('{');
        int endIndex = errorString.lastIndexOf('}') + 1;
        String jsonPart = errorString.substring(startIndex, endIndex);

        var decoded = jsonDecode(jsonPart);
        if (decoded['message'] != null) {
          message = decoded['message']; // استخراج الرسالة من الباك إند
        }
      }
      // 3. إذا كان الخطأ من نوع Exception مخصص قمنا برميه يدوياً
      else if (errorString.contains("Exception:")) {
        message = errorString.split("Exception:").last.trim();
      }
      // 4. معالجة حالات الشبكة
      else if (errorString.contains("SocketException")) {
        message = "No Internet connection. Please check your network.";
      }
    } catch (parseError) {
      // في حال فشل الـ Parsing لأي سبب، نضع رسالة بسيطة
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