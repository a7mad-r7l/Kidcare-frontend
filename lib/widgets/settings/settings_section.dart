import 'package:flutter/material.dart';
import 'package:get/get.dart'; // ─── تمت إضافته للوصول إلى السمة ───

class SettingsSection extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const SettingsSection({
    super.key,
    required this.title,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 10, right: 10, left: 10),
          child: Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              // ─── لون العنوان متكيف ───
              color: context.textTheme.bodyLarge?.color,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            // ─── خلفية القسم متكيفة ───
            color: context.theme.cardColor,
            borderRadius: BorderRadius.circular(20),
            // ─── إطار القسم متكيف ───
            border: Border.all(color: context.theme.dividerColor),
          ),
          child: Column(children: children),
        ),
      ],
    );
  }
}