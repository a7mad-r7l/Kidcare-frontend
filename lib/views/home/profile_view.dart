import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/home/profile_controller.dart';

class ProfileView extends GetView<ProfileController> {
  const ProfileView({super.key});

  //  دالة مساعدة لظهور نافذة التعديل المنبثقة
  void _showEditDialog(BuildContext context, String title, String key, String currentValue) {
    final TextEditingController textController = TextEditingController(text: currentValue);

    Get.dialog(
      AlertDialog(
        backgroundColor: context.theme.cardColor,
        title: Text(
          'Edit $title'.tr,
          style: TextStyle(color: context.textTheme.bodyLarge?.color, fontSize: 18, fontWeight: FontWeight.bold),
        ),
        content: TextField(
          controller: textController,
          style: TextStyle(color: context.textTheme.bodyLarge?.color),
          decoration: InputDecoration(
            hintText: 'Enter new $title'.tr,
            hintStyle: TextStyle(color: context.theme.hintColor),
            enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: context.theme.dividerColor),
            ),
            focusedBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: context.theme.primaryColor),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text('Cancel'.tr, style: TextStyle(color: context.textTheme.bodyMedium?.color)),
          ),
          ElevatedButton(
            onPressed: () {
              Get.back();
              // استدعاء دالة التحديث في الـ Controller وإرسال المفتاح والقيمة الجديدة
              controller.updateProfileField(key, textController.text);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: context.theme.primaryColor,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: Text('Save'.tr, style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        centerTitle: true,
        title: Text(
          'Personal Profile'.tr,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: context.textTheme.bodyLarge?.color,
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: context.iconColor, size: 20),
          onPressed: () => Get.back(),
        ),
      ),
      body: Obx(() {
        if (controller.isLoading) {
          return Center(
            child: CircularProgressIndicator(color: context.theme.primaryColor),
          );
        }

        if (controller.profile.value == null) {
          return Center(
            child: Text(
              'Failed to load profile'.tr,
              style: TextStyle(color: context.textTheme.bodyMedium?.color),
            ),
          );
        }

        final profile = controller.profile.value!;

        return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 10),

              // ─── Avatar ───
              Center(
                child: CircleAvatar(
                  radius: 55,
                  backgroundColor: context.isDarkMode ? Colors.green.withValues(alpha: 0.15) : const Color(0xFFE8F5E9),
                  child: Icon(Icons.person,
                      color: context.isDarkMode ? Colors.greenAccent : const Color(0xFF4CAF50).withValues(alpha: 0.6),
                      size: 60),
                ),
              ),
              const SizedBox(height: 16),

              // ─── Full Name
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  profile.fullName,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: context.textTheme.bodyLarge?.color,
                  ),
                ),
              ),
              const SizedBox(height: 28),

              //  Info Items
              _ProfileItem(
                icon: Icons.email_outlined,
                label: 'Email'.tr,
                value: profile.email,
                onEdit: () => _showEditDialog(context, 'Email', 'email', profile.email),
              ),
              const SizedBox(height: 12),

              _ProfileItem(
                icon: Icons.phone_outlined,
                label: 'Phone Number'.tr,
                value: profile.phoneNumber,
                // تمرير المفتاح phone_number كما هو مطلوب في الـ API
                onEdit: () => _showEditDialog(context, 'Phone Number', 'phone_number', profile.phoneNumber),
              ),
              const SizedBox(height: 12),

              _ProfileItem(
                icon: Icons.location_on_outlined,
                label: 'Address'.tr,
                value: profile.address,
                onEdit: () => _showEditDialog(context, 'Address', 'address', profile.address),
              ),
              const SizedBox(height: 12),

              // إزالة زر التعديل بتمرير null إلى onEdit
              _ProfileItem(
                icon: Icons.group_outlined,
                label: 'Number of Children'.tr,
                value: profile.childrenCount.toString(),
                onEdit: null,
              ),
              const SizedBox(height: 28),

              //  Logout Button
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton.icon(
                  onPressed: controller.logout,
                  icon: Icon(
                    Icons.logout,
                    color: context.isDarkMode ? Colors.redAccent : const Color(0xFF1A2E5A),
                  ),
                  label: Text(
                    'Logout'.tr,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: context.isDarkMode ? Colors.redAccent : const Color(0xFF1A2E5A),
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: context.isDarkMode ? Colors.red.withValues(alpha: 0.1) : const Color(0xFFE8EAF6),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 30),
            ],
          ),
        );
      }),
    );
  }
}

// ─── Profile Item

class _ProfileItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final VoidCallback? onEdit; // أصبح اختيارياً بقبول القيمة null

  const _ProfileItem({
    required this.icon,
    required this.label,
    required this.value,
    this.onEdit, // إزالة required
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: context.theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: context.isDarkMode ? Colors.transparent : Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // ─── Icon
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: context.isDarkMode ? Colors.green.withValues(alpha: 0.15) : const Color(0xFFE8F5E9),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: context.isDarkMode ? Colors.greenAccent : const Color(0xFF4CAF50), size: 22),
          ),
          const SizedBox(width: 12),

          // ─── Label & Value
          Expanded( // استخدام Expanded لمنع مشاكل المساحات في الشاشات الصغيرة
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: context.textTheme.bodyLarge?.color,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 13,
                    color: context.textTheme.bodyMedium?.color,
                  ),
                ),
              ],
            ),
          ),

          // ─── Edit icon
          // لن يظهر الأيقونة إلا إذا كان onEdit يحتوي على دالة
          if (onEdit != null)
            GestureDetector(
              onTap: onEdit,
              child: Padding(
                padding: const EdgeInsets.only(left: 8.0), // إعطاء مساحة نقر أفضل
                child: Icon(
                    Icons.edit_outlined,
                    color: context.isDarkMode ? Colors.blue.shade300 : Colors.blue,
                    size: 20
                ),
              ),
            ),
        ],
      ),
    );
  }
}