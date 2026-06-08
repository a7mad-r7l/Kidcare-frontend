import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../controllers/growth/child_growth_controller.dart';

class AddGrowthSheet extends StatelessWidget {
  const AddGrowthSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<ChildGrowthController>();

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        top: 20,
        left: 20,
        right: 20,
        //  Keyboard Avoidance
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
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 20),

            Text(
              'Add Measurement'.tr,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1A2E5A),
              ),
            ),
            const SizedBox(height: 20),

            // 1. إدخال الوزن
            Text(
              'Weight (kg)'.tr,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: controller.weightController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: InputDecoration(
                hintText: '0.0',
                prefixIcon: const Icon(Icons.scale_outlined, size: 20),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: Colors.grey.shade200),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: Colors.grey.shade200),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: Colors.blue),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // 2. إدخال الطول
            Text(
              'Height (cm)'.tr,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: controller.heightController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: InputDecoration(
                hintText: '0.0',
                prefixIcon: const Icon(Icons.straighten_outlined, size: 20),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: Colors.grey.shade200),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: Colors.grey.shade200),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: Colors.blue),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // 3. اختيار تاريخ القياس (Date Picker Trigger)
            Text(
              'Record Date'.tr,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 8),
            Obx(
              () => GestureDetector(
                onTap: () => controller.pickRecordDate(context),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.grey.shade200),
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
                              ? Colors.grey.shade400
                              : Colors.black,
                          fontSize: 14,
                        ),
                      ),
                      Icon(
                        Icons.calendar_month_outlined,
                        color: Colors.grey.shade500,
                        size: 20,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 28),

            // 4. زر حفظ القياس
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: () => controller.addMeasurement(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1A2E5A),

                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  'Save Measurement'.tr,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
