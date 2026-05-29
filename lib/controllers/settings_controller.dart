import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../core/helper/secure_storage_service.dart';

class SettingsController extends GetxController {
  var currentLanguage = 'en'.obs;

  @override
  void onInit() {
    super.onInit();
    _loadSavedLanguage();
  }

  Future<void> _loadSavedLanguage() async {
    String? savedLang = await SecureStorage.getLanguage();
    if (savedLang != null) {
      currentLanguage.value = savedLang;
    }
  }

  Future<void> changeLanguage(String langCode) async {
    if (currentLanguage.value == langCode) return;

    currentLanguage.value = langCode;
    await SecureStorage.storeLanguage(langCode);

    Locale newLocale = langCode == 'ar'
        ? const Locale('ar', 'SA')
        : const Locale('en', 'US');
    Get.updateLocale(newLocale);
  }
}
