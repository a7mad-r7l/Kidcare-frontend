import 'package:flutter/material.dart';
import 'package:get/get.dart'; // ─── تمت إضافته للوصول إلى السمة ───

class SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool isLogout;
  final bool showDivider;

  const SettingsTile({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.isLogout = false,
    this.showDivider = true,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ListTile(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 4,
          ),
          leading: Icon(
            icon,
            // ─── تكييف لون الأيقونة (أحمر مريح ليلاً لتسجيل الخروج، ولون أساسي للبقية) ───
            color: isLogout
                ? (context.isDarkMode ? Colors.redAccent : Colors.red)
                : context.theme.primaryColor,
            size: 28,
          ),
          title: Text(
            title,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 15,
              // ─── تكييف لون العنوان ───
              color: isLogout
                  ? (context.isDarkMode ? Colors.redAccent : Colors.red)
                  : context.textTheme.bodyLarge?.color,
            ),
          ),
          subtitle: Text(
            subtitle,
            // ─── تكييف لون النص الثانوي ───
            style: TextStyle(fontSize: 12, color: context.textTheme.bodyMedium?.color),
          ),
          trailing: Icon(
            Icons.arrow_forward_ios,
            size: 16,
            // ─── تكييف لون السهم ───
            color: context.theme.dividerColor,
          ),
          onTap: onTap,
        ),
        if (showDivider)
          Divider(
            height: 1,
            thickness: 1,
            // ─── تكييف لون الفاصل ───
            color: context.theme.dividerColor,
            indent: 60,
            endIndent: 20,
          ),
      ],
    );
  }
}