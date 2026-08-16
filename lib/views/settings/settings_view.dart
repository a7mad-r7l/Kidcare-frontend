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

      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: Text(
          'settings'.tr,
          style: TextStyle(
            color: context.textTheme.bodyLarge?.color,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: context.iconColor),

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
                Obx(
                  () => SettingsTile(
                    icon: Icons.dark_mode_outlined,
                    title: 'theme'.tr,
                    subtitle: controller.isDarkMode.value
                        ? 'Dark Mode'
                        : 'Light Mode',
                    onTap: () {
                      controller.toggleTheme();
                    },
                  ),
                ),
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

            // 4. المزيد
            SettingsSection(
              title: 'More'.tr,
              children: [
                SettingsTile(
                  icon: Icons.info_outline,
                  title: 'about_app'.tr,
                  subtitle: '${'version'.tr} 1.0.0',
                  onTap: () {},
                ),
                SettingsTile(
                  icon: Icons.delete_forever_rounded,
                  title: 'Delete account'.tr,
                  subtitle: 'Permanently delete your account from the app'.tr,
                  isLogout: true,
                  showDivider: false,
                  onTap: () => controller.deleteAccount(),
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

                          color: context.textTheme.bodyLarge?.color,
                        ),
                      ),
                      value: 'en',
                      activeColor: context
                          .theme
                          .primaryColor,
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
