import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/home/profile_controller.dart';


class ProfileView extends GetView<ProfileController> {
  const ProfileView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF4F6FA),
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Personal Profile',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1A2E5A),
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios,
              color: Color(0xFF1A2E5A), size: 20),
          onPressed: () => Get.back(),
        ),
      ),
      body: Obx(() {
        if (controller.isLoading) {
          return const Center(
            child: CircularProgressIndicator(color: Colors.blue),
          );
        }

        if (controller.profile.value == null) {
          return const Center(child: Text('Failed to load profile'));
        }

        final profile = controller.profile.value!;

        return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            // ✅ تغيير إلى start
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 10),

              // ─── Avatar ─── مركز دائماً
              Center(
                child: CircleAvatar(
                  radius: 55,
                  backgroundColor: const Color(0xFFE8F5E9),
                  child: Icon(Icons.person,
                      color: const Color(0xFF4CAF50).withOpacity(0.6),
                      size: 60),
                ),
              ),
              const SizedBox(height: 16),

              // ─── Full Name ✅ من اليسار
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  profile.fullName,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1A2E5A),
                  ),
                ),
              ),
              const SizedBox(height: 28),

              // ─── Info Items ───────────────────────────
              _ProfileItem(
                icon: Icons.email_outlined,
                label: 'Email',
                value: profile.email,
                onEdit: () {
                  // TODO: تعديل البريد الإلكتروني
                },
              ),
              const SizedBox(height: 12),

              _ProfileItem(
                icon: Icons.phone_outlined,
                label: 'Phone Number',
                value: profile.phoneNumber,
                onEdit: () {
                  // TODO: تعديل رقم الهاتف
                },
              ),
              const SizedBox(height: 12),

              _ProfileItem(
                icon: Icons.location_on_outlined,
                label: 'Address',
                value: profile.address,
                onEdit: () {
                  // TODO: تعديل العنوان
                },
              ),
              const SizedBox(height: 12),

              _ProfileItem(
                icon: Icons.group_outlined,
                label: 'Number of Children',
                value: profile.childrenCount.toString(),
                onEdit: () {
                  // TODO: الانتقال لإدارة الأطفال
                },
              ),
              const SizedBox(height: 28),

              // ─── Logout Button ────────────────────────
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton.icon(
                  onPressed: controller.logout,
                  icon: const Icon(Icons.logout, color: Color(0xFF1A2E5A)),
                  label: const Text(
                    'Logout',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1A2E5A),
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFE8EAF6),
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

// ─── Profile Item ─────────────────────────────────────────────────────────────

class _ProfileItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final VoidCallback onEdit;

  const _ProfileItem({
    required this.icon,
    required this.label,
    required this.value,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      // ✅ عكس ترتيب الـ Row
      child: Row(
        children: [
          // ─── Icon ✅ على اليسار
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFE8F5E9),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: const Color(0xFF4CAF50), size: 22),
          ),
          const SizedBox(width: 12),

          // ─── Label & Value ✅ من اليسار
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A2E5A),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),

          const Spacer(),

          // ─── Edit icon ✅ على اليمين
          GestureDetector(
            onTap: onEdit,
            child: const Icon(Icons.edit_outlined,
                color: Colors.blue, size: 20),
          ),
        ],
      ),
    );
  }
}