import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../core/helper/secure_storage_service.dart';

class SettingsController extends GetxController {

  var currentLanguage = 'system'.obs;

  @override
  void onInit() {
    super.onInit();
    _loadSavedLanguage();
  }

  Future<void> _loadSavedLanguage() async {
    String? savedLang = await SecureStorage.getLanguage();

    if (savedLang != null) {
      currentLanguage.value = savedLang;
      _applyLocale(savedLang);
    } else {

      currentLanguage.value = 'system';
      _applyLocale('system');
    }
  }

  Future<void> changeLanguage(String langCode) async {
    if (currentLanguage.value == langCode) return;

    currentLanguage.value = langCode;
    await SecureStorage.storeLanguage(langCode);
    _applyLocale(langCode);
  }

  void _applyLocale(String langCode) {
    Locale targetLocale;

    if (langCode == 'system') {

      Locale? deviceLocale = Get.deviceLocale;
      if (deviceLocale != null && deviceLocale.languageCode == 'ar') {
        targetLocale = const Locale('ar', 'SA');
      } else {
        targetLocale = const Locale('en', 'US');
      }
    } else if (langCode == 'ar') {
      targetLocale = const Locale('ar', 'SA');
    } else {
      targetLocale = const Locale('en', 'US');
    }


    Get.updateLocale(targetLocale);
  }
}