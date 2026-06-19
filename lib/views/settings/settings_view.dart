import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/settings_controller.dart';

import '../../widgets/settings/settings_section.dart';
import '../../widgets/settings/settings_tile.dart';

class SettingsView extends StatelessWidget {
  const SettingsView({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(SettingsController());

    return Scaffold(
      // ❌ تم إزالة backgroundColor ليقرأ خلفية النظام التلقائية (بيضاء/داكنة)
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: Text(
          'settings'.tr,
          style: TextStyle(
            color: context.textTheme.bodyLarge?.color, // ─── لون النص متكيف ───
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: context.iconColor), // ─── أيقونة متكيفة ───
          onPressed: () => Get.back(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 3. قسم التفضيلات
            SettingsSection(
              title: 'preferences'.tr,
              children: [
                Obx(
                      () => SettingsTile(
                    icon: Icons.language,
                    title: 'language'.tr,
                    subtitle: controller.currentLanguage.value == 'ar'
                        ? 'العربية'
                        : 'English',
                    onTap: () => _showLanguageBottomSheet(context, controller),
                  ),
                ),
                Obx(() => SettingsTile(
                  icon: Icons.dark_mode_outlined,
                  title: 'theme'.tr,
                  subtitle: controller.isDarkMode.value ? 'Dark Mode' : 'Light Mode',
                  onTap: () {
                    controller.toggleTheme();
                  },
                )),
                SettingsTile(
                  icon: Icons.favorite_border_rounded,
                  title: 'favorite_doctors'.tr,
                  subtitle: 'view_favorite_doctors'.tr,
                  onTap: () {
                    Get.toNamed('/favorites');
                  },
                ),
              ],
            ),
            const SizedBox(height: 25),

            // 4. قسم الدعم والمزيد
            SettingsSection(
              title: 'support_and_more'.tr,
              children: [
                SettingsTile(
                  icon: Icons.help_outline,
                  title: 'help_center'.tr,
                  subtitle: 'faq_and_support'.tr,
                  onTap: () {},
                ),
                SettingsTile(
                  icon: Icons.description_outlined,
                  title: 'app_rating'.tr,
                  subtitle: 'share_your_opinion'.tr,
                  onTap: () {},
                ),
                SettingsTile(
                  icon: Icons.info_outline,
                  title: 'about_app'.tr,
                  subtitle: '${'version'.tr} 1.0.0',
                  onTap: () {},
                ),
                SettingsTile(
                  icon: Icons.delete_forever_rounded,
                  title: 'Delete account'.tr,
                  subtitle: ''.tr,
                  isLogout: true,
                  showDivider: false,
                  onTap: () {},
                ),
              ],
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  void _showLanguageBottomSheet(
      BuildContext context,
      SettingsController controller,
      ) {
    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          // ─── لون خلفية النافذة المنبثقة متكيف ───
          color: context.theme.cardColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(25)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'change_language'.tr,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                // ─── لون العنوان متكيف ───
                color: context.textTheme.bodyLarge?.color,
              ),
            ),
            const SizedBox(height: 20),

            Obx(
                  () => RadioGroup<String>(
                groupValue: controller.currentLanguage.value,
                onChanged: (value) {
                  if (value != null) {
                    controller.changeLanguage(value);
                    Get.back();
                  }
                },
                child: Column(
                  children: [
                    RadioListTile<String>(
                      title: Text(
                        'English',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          // ─── لون الخيار متكيف ───
                          color: context.textTheme.bodyLarge?.color,
                        ),
                      ),
                      value: 'en',
                      activeColor: context.theme.primaryColor, // ─── لون التحديد متكيف ───
                    ),
                    RadioListTile<String>(
                      title: Text(
                        'العربية',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: context.textTheme.bodyLarge?.color,
                        ),
                      ),
                      value: 'ar',
                      activeColor: context.theme.primaryColor,
                    ),
                    RadioListTile<String>(
                      title: Text(
                        'System Default (لغة النظام)',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: context.textTheme.bodyLarge?.color,
                        ),
                      ),
                      value: 'system',
                      activeColor: context.theme.primaryColor,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}