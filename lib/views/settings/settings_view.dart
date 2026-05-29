import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/settings_controller.dart';

import '../../widgets/settings/profile_card.dart';
import '../../widgets/settings/settings_section.dart';
import '../../widgets/settings/settings_tile.dart';

class SettingsView extends StatelessWidget {
  const SettingsView({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(SettingsController());

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FD),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: Text(
          'settings'.tr,
          style: const TextStyle(
            color: Color(0xFF1D2755),
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.blue),
          onPressed: () => Get.back(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1.  البروفايل
            ProfileCard(
              name: 'أحمد الرحال',
              email: 'ahmed.mohamed@email.com',
              imageUrl: 'https://i.pravatar.cc/150?img=11',
              onViewProfile: () {
                // Get.toNamed('/profile');
              },
            ),
            const SizedBox(height: 25),

            // 2. قسم الحساب
            SettingsSection(
              title: 'account'.tr,
              children: [
                SettingsTile(
                  icon: Icons.person_outline,
                  title: 'profile'.tr,
                  subtitle: 'edit_personal_info'.tr,
                  onTap: () {},
                ),
                SettingsTile(
                  icon: Icons.face,
                  title: 'your_children'.tr,
                  subtitle: 'manage_children_info'.tr,
                  onTap: () {},
                ),
                SettingsTile(
                  icon: Icons.account_balance_wallet_outlined,
                  title: 'payment_data'.tr,
                  subtitle: 'manage_payment_methods'.tr,
                  showDivider: false,
                  onTap: () {},
                ),
              ],
            ),
            const SizedBox(height: 25),

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
                SettingsTile(
                  icon: Icons.dark_mode_outlined,
                  title: 'theme'.tr,
                  subtitle: 'light_mode'.tr,
                  onTap: () {},
                ),
                SettingsTile(
                  icon: Icons.text_fields,
                  title: 'font_size'.tr,
                  subtitle: 'medium'.tr,
                  onTap: () {},
                ),
                SettingsTile(
                  icon: Icons.notifications_none,
                  title: 'notifications'.tr,
                  subtitle: 'manage_notifications'.tr,
                  showDivider: false,
                  onTap: () {},
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
                  icon: Icons.logout,
                  title: 'logout'.tr,
                  subtitle: 'logout_from_account'.tr,
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
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'change_language'.tr,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),


            Obx(
              () => RadioGroup<String>(
                groupValue: controller.currentLanguage.value,
                onChanged: (value) {
                  if (value != null) {
                    controller.changeLanguage(value);
                    Get.back(); // إغلاق النافذة
                  }
                },
                child: const Column(
                  children: [

                    RadioListTile<String>(
                      title: Text(
                        'English',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      value: 'en',
                      activeColor: Colors.blue,
                    ),
                    RadioListTile<String>(
                      title: Text(
                        'العربية',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      value: 'ar',
                      activeColor: Colors.blue,
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
