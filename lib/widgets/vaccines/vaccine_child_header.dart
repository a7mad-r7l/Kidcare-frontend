import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/vaccines/vaccines_controller.dart';

class VaccineChildHeader extends GetView<VaccinesController> {
  const VaccineChildHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final child = controller.childInfo.value;
      if (child == null) return const SizedBox.shrink();

      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: context.theme.cardColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: context.theme.dividerColor.withValues(alpha: 0.4),
            ),
            boxShadow: [
              if (!context.isDarkMode)
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.02),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
            ],
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: context.theme.primaryColor.withValues(
                  alpha: 0.1,
                ),
                backgroundImage:
                    (child.image != null && child.image!.isNotEmpty)
                    ? NetworkImage(child.image!)
                    : null,
                child: (child.image == null || child.image!.isEmpty)
                    ? Icon(Icons.person, color: context.theme.primaryColor)
                    : null,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      child.fullName,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: context.textTheme.bodyLarge?.color,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${child.ageYears} ${'years'.tr}',
                      style: TextStyle(
                        fontSize: 13,
                        color: context.theme.hintColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    });
  }
}
