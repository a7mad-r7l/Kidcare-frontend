import 'package:flutter/material.dart';
import 'package:get/get.dart';

abstract class BaseController extends GetxController {
  final RxBool isLoading = false.obs;

  void handleError(dynamic e) {
    final message = e is Exception
        ? e.toString().replaceAll('Exception: ', '')
        : e.toString();
    Get.snackbar(
      'Error',
      message,
      backgroundColor: Colors.red,
      colorText: Colors.white,
    );
  }
}
