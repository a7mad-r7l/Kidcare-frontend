import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../controllers/growth/child_growth_controller.dart';

class AddGrowthSheet extends StatelessWidget {
  const AddGrowthSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<ChildGrowthController>();

    return Container(
      decoration: BoxDecoration(
        // ─── خلفية متكيفة للوضع الليلي والنهاري ───
        color: context.theme.cardColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        top: 20,
        left: 20,
        right: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 45,
                height: 4,
                decoration: BoxDecoration(
                  color: context.theme.dividerColor,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 20),

            Text(
              'Add Measurement'.tr,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                // ─── لون العنوان متكيف ───
                color: context.textTheme.bodyLarge?.color,
              ),
            ),
            const SizedBox(height: 20),

            // حقول الإدخال
            _buildInputField(
              label: 'Weight (kg)'.tr,
              controller: controller.weightController,
              icon: Icons.scale_outlined,
              context: context,
            ),
            const SizedBox(height: 16),

            _buildInputField(
              label: 'Height (cm)'.tr,
              controller: controller.heightController,
              icon: Icons.straighten_outlined,
              context: context,
            ),
            const SizedBox(height: 16),

            // اختيار التاريخ
            Text(
              'Record Date'.tr,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: context.textTheme.bodyMedium?.color,
              ),
            ),
            const SizedBox(height: 8),
            Obx(
                  () => GestureDetector(
                onTap: () => controller.pickRecordDate(context),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: context.theme.dividerColor),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        controller.selectedDate.value.isEmpty
                            ? 'YYYY-MM-DD'
                            : controller.selectedDate.value,
                        style: TextStyle(
                          color: controller.selectedDate.value.isEmpty
                              ? context.theme.hintColor
                              : context.textTheme.bodyLarge?.color,
                          fontSize: 14,
                        ),
                      ),
                      Icon(Icons.calendar_month_outlined, color: context.theme.hintColor, size: 20),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 28),

            // زر الحفظ
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: () => controller.addMeasurement(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: context.theme.primaryColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  elevation: 0,
                ),
                child: Text(
                  'Save Measurement'.tr,
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// مساعد لبناء حقول الإدخال بشكل متناسق ومتكيف
  Widget _buildInputField({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    required BuildContext context,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: context.textTheme.bodyMedium?.color)),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          style: TextStyle(color: context.textTheme.bodyLarge?.color),
          decoration: InputDecoration(
            hintText: '0.0',
            hintStyle: TextStyle(color: context.theme.hintColor),
            prefixIcon: Icon(icon, size: 20, color: context.theme.primaryColor),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: context.theme.dividerColor),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: context.theme.dividerColor),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: context.theme.primaryColor),
            ),
          ),
        ),
      ],
    );
  }
}