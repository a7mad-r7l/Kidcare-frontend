import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../core/helper/secure_storage_service.dart';
import '../core/repos/auth/login_repo.dart';
import 'base_controller.dart';

class SettingsController extends BaseController {
  var currentLanguage = 'system'.obs;
  final RxBool isDarkMode = false.obs;

  @override
  void onInit() {
    super.onInit();
    _loadSavedLanguage();

    isDarkMode.value = Get.isDarkMode;
  }

  void toggleTheme() {
    isDarkMode.value = !isDarkMode.value;

    Get.changeThemeMode(isDarkMode.value ? ThemeMode.dark : ThemeMode.light);
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

  void deleteAccount() {
    Get.dialog(
      AlertDialog(
        backgroundColor: Get.theme.cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Delete Account'.tr,
          style: const TextStyle(
            color: Colors.red,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          'Are you sure you want to permanently delete your account? This action cannot be undone.'
              .tr,
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text(
              'Cancel'.tr,
              style: TextStyle(color: Get.theme.hintColor),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade800,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: () async {
              Get.back();
              await _confirmDeleteAccount();
            },
            child: Text(
              'Delete'.tr,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDeleteAccount() async {
    showLoading();
    try {
      final loginRepo = LoginRepo();

      final msg = await loginRepo.deletePatientAccount();

      showSuccess(msg);

      await SecureStorage.removeAll();
      Get.offAllNamed('/login');
    } catch (e) {
      handleError(e);
    } finally {
      hideLoading();
    }
  }
}
