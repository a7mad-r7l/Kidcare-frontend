import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/vaccines/vaccines_controller.dart';

class VaccineTabs extends GetView<VaccinesController> {
  const VaccineTabs({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: context.theme.cardColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: context.theme.dividerColor.withValues(alpha: 0.5),
          ),
        ),
        child: Obx(
          () => Row(
            children: [
              _buildTabItem(
                context,
                0,
                'Available Schedules'.tr,
                '(Upcoming)'.tr,
              ),
              _buildTabItem(context, 1, 'Vaccination History'.tr, '(Past)'.tr),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTabItem(
    BuildContext context,
    int index,
    String title,
    String subtitle,
  ) {
    final isSelected = controller.selectedTab.value == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => controller.switchTab(index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? context.theme.primaryColor : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(
            children: [
              Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 12.5,
                  color: isSelected
                      ? Colors.white
                      : context.textTheme.bodyLarge?.color,
                ),
              ),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 10.5,
                  color: isSelected ? Colors.white70 : context.theme.hintColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
