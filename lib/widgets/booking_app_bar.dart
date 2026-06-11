import 'package:flutter/material.dart';
import 'package:get/get.dart';

PreferredSizeWidget bookingAppBar({required String subtitle}) {
  return AppBar(
    // 1. استخدام context هنا يتطلب تعديل طفيف لنجعله دالة تأخذ context
    // ولكن بما أن الـ AppBar دالة خارجية، سنستخدم Get.context
    backgroundColor: Get.theme.scaffoldBackgroundColor,
    elevation: 0,
    scrolledUnderElevation: 0,
    toolbarHeight: 72,
    leading: Padding(
      padding: const EdgeInsets.all(8),
      child: InkWell(
        onTap: () => Get.back(),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          decoration: BoxDecoration(
            // 2. استخدام لون البطاقة المتكيف بدلاً من الأبيض الثابت
            color: Get.theme.cardColor,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              if (!Get.isDarkMode) // إخفاء الظل في الوضع الليلي
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
            ],
          ),
          child: Icon(
            Icons.chevron_left_rounded,
            // 3. لون أيقونة الرجوع متكيف
            color: Get.textTheme.bodyLarge?.color,
            size: 26,
          ),
        ),
      ),
    ),
    title: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Book New Appointment'.tr,
          style: TextStyle(
            // 4. ألوان النصوص متكيفة
            color: Get.textTheme.bodyLarge?.color,
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          subtitle,
          style: TextStyle(
            color: Get.textTheme.bodyMedium?.color,
            fontSize: 12.5,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    ),
    centerTitle: true,
  );
}