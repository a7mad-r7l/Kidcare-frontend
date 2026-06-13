import 'package:flutter/material.dart';
import 'package:get/get.dart';

class AboutAppView extends StatelessWidget {
  const AboutAppView({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('About App'.tr),
        centerTitle: true,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, size: 20),
          onPressed: () => Get.back(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            // شعار التطبيق
            Center(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Image.asset(
                  'assets/images/logo.jpg',
                  height: 120,
                ),
              ),
            ),
            const SizedBox(height: 30),

            // عنوان ترحيبي
            Text(
              'Pediatric Clinic Management'.tr,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: theme.primaryColor,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),

            // الوصف الرئيسي
            _buildSection(
              context,
              title: 'Our Vision'.tr,
              content: 'app_vision_desc'.tr,
              icon: Icons.lightbulb_outline,
            ),

            const SizedBox(height: 20),

            _buildSection(
              context,
              title: 'Our Mission'.tr,
              content: 'app_mission_desc'.tr,
              icon: Icons.track_changes,
            ),

            const SizedBox(height: 20),

            _buildSection(
              context,
              title: 'Key Features'.tr,
              content: 'app_features_desc'.tr,
              icon: Icons.star_border,
            ),

            const SizedBox(height: 40),

            // رقم الإصدار أو الحقوق
            Text(
              'Version 1.0.0'.tr,
              style: TextStyle(color: theme.hintColor, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(BuildContext context, {required String title, required String content, required IconData icon}) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.dividerColor.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: theme.primaryColor, size: 20),
              const SizedBox(width: 10),
              Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            content,
            style: TextStyle(
              color: theme.textTheme.bodyMedium?.color,
              height: 1.6,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}