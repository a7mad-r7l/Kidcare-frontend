import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../controllers/home/add_child_controller.dart';
import '../../widgets/custom_text_field.dart';

class AddChildView extends GetView<AddChildController> {
  const AddChildView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // ❌ تم إزالة backgroundColor للـ Scaffold والـ AppBar
      appBar: AppBar(
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: context.iconColor, size: 20), // أيقونة متكيفة
          onPressed: () => Get.back(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ─── Avatar ───────────────────────────────
            Center(
              child: GestureDetector(
                onTap: controller.pickImage,
                child: Obx(() => Stack(
                  children: [
                    CircleAvatar(
                      radius: 55,
                      backgroundColor: context.theme.scaffoldBackgroundColor, // لون خلفية متكيف
                      backgroundImage: controller.selectedImage.value != null
                          ? FileImage(controller.selectedImage.value!)
                          : null,
                      child: controller.selectedImage.value == null
                          ? Icon(Icons.person,
                          color: context.theme.dividerColor, size: 60)
                          : null,
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: context.theme.primaryColor, // اللون الأساسي من السمة
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.camera_alt,
                            color: Colors.white, size: 18),
                      ),
                    ),
                  ],
                )),
              ),
            ),

            // ─── Title ────────────────────────────────
            Center(
              child: Text(
                'Add New Child'.tr,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: context.textTheme.bodyLarge?.color, // نص متكيف
                ),
              ),
            ),
            const SizedBox(height: 24),

            // ─── Form Card ────────────────────────────
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: context.theme.cardColor, // كرت متكيف
                borderRadius: BorderRadius.circular(24),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // First & Last Name
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('First Name'.tr,
                                style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: context.textTheme.bodyLarge?.color)),
                            const SizedBox(height: 8),
                            CustomTextField(
                              controller: controller.firstNameController,
                              hintText: 'Enter first name'.tr,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Last Name'.tr,
                                style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: context.textTheme.bodyLarge?.color)),
                            const SizedBox(height: 8),
                            CustomTextField(
                              controller: controller.lastNameController,
                              hintText: 'Enter last name'.tr,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Gender
                  Text('Gender'.tr,
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: context.textTheme.bodyLarge?.color)),
                  const SizedBox(height: 10),
                  Obx(() => Row(
                    children: [
                      // Female
                      Expanded(
                        child: GestureDetector(
                          onTap: () => controller.selectGender('female'),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            decoration: BoxDecoration(
                              // لون متكيف بذكاء للوضع الليلي
                              color: controller.selectedGender.value == 'female'
                                  ? (context.isDarkMode ? Colors.pinkAccent.withOpacity(0.15) : const Color(0xFFFCE4EC))
                                  : context.theme.scaffoldBackgroundColor,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: controller.selectedGender.value == 'female'
                                    ? Colors.pinkAccent
                                    : context.theme.dividerColor,
                                width: controller.selectedGender.value == 'female' ? 2 : 1,
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.face_3,
                                    color: controller.selectedGender.value == 'female'
                                        ? Colors.pinkAccent
                                        : Colors.grey,
                                    size: 22),
                                const SizedBox(width: 8),
                                Text('Female'.tr,
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: controller.selectedGender.value == 'female'
                                          ? Colors.pinkAccent
                                          : Colors.grey,
                                    )),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Male
                      Expanded(
                        child: GestureDetector(
                          onTap: () => controller.selectGender('male'),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            decoration: BoxDecoration(
                              // لون متكيف بذكاء للوضع الليلي
                              color: controller.selectedGender.value == 'male'
                                  ? (context.isDarkMode ? Colors.blue.withOpacity(0.15) : const Color(0xFFE3F2FD))
                                  : context.theme.scaffoldBackgroundColor,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: controller.selectedGender.value == 'male'
                                    ? Colors.blue
                                    : context.theme.dividerColor,
                                width: controller.selectedGender.value == 'male' ? 2 : 1,
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.face,
                                    color: controller.selectedGender.value == 'male'
                                        ? Colors.blue
                                        : Colors.grey,
                                    size: 22),
                                const SizedBox(width: 8),
                                Text('Male'.tr,
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: controller.selectedGender.value == 'male'
                                          ? Colors.blue
                                          : Colors.grey,
                                    )),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  )),
                  const SizedBox(height: 20),

                  // Birth Date
                  Text('Birth Date'.tr,
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: context.textTheme.bodyLarge?.color)),
                  const SizedBox(height: 8),
                  Obx(() => GestureDetector(
                    onTap: () => controller.pickBirthDate(context),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 15),
                      decoration: BoxDecoration(
                        color: context.theme.scaffoldBackgroundColor, // لون متكيف
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: context.theme.dividerColor), // إطار متكيف
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Icon(Icons.calendar_today_outlined,
                              color: Colors.blue, size: 20),
                          Text(
                            controller.selectedBirthDate.value.isEmpty
                                ? 'Select birth date'.tr
                                : controller.selectedBirthDate.value,
                            style: TextStyle(
                              fontSize: 13,
                              color: controller.selectedBirthDate.value.isEmpty
                                  ? context.textTheme.bodyMedium?.color
                                  : context.textTheme.bodyLarge?.color,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )),
                  const SizedBox(height: 20),

                  // Blood Type
                  Text('Blood Type'.tr,
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: context.textTheme.bodyLarge?.color)),
                  const SizedBox(height: 8),
                  Obx(() => Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: context.theme.scaffoldBackgroundColor, // خلفية متكيفة
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: context.theme.dividerColor),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        isExpanded: true,
                        dropdownColor: context.theme.cardColor, // لون القائمة المنسدلة في الوضع الليلي
                        hint: Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            const Icon(Icons.water_drop_outlined,
                                color: Colors.blue, size: 18),
                            const SizedBox(width: 8),
                            Text('Select blood type'.tr,
                                style: TextStyle(
                                    color: context.textTheme.bodyMedium?.color,
                                    fontSize: 13)),
                          ],
                        ),
                        value: controller.selectedBloodType.value.isEmpty
                            ? null
                            : controller.selectedBloodType.value,
                        items: controller.bloodTypes
                            .map((type) => DropdownMenuItem(
                          value: type,
                          child: Text(type,
                              style: TextStyle(color: context.textTheme.bodyLarge?.color), // نص القائمة
                              textAlign: TextAlign.right),
                        ))
                            .toList(),
                        onChanged: (val) {
                          if (val != null) {
                            controller.selectedBloodType.value = val;
                          }
                        },
                      ),
                    ),
                  )),
                  const SizedBox(height: 20),

                  // Medical History
                  Text('Medical History'.tr,
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: context.textTheme.bodyLarge?.color)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: controller.medicalHistoryController,
                    maxLines: 3,
                    textAlign: TextAlign.left,
                    style: TextStyle(color: context.textTheme.bodyLarge?.color), // لون النص
                    decoration: InputDecoration(
                      hintText: "Enter child's medical history".tr,
                      hintStyle: TextStyle(
                          color: context.textTheme.bodyMedium?.color, fontSize: 13),
                      suffixIcon: const Icon(Icons.calendar_month_outlined,
                          color: Colors.blue),
                      filled: true,
                      fillColor: context.theme.scaffoldBackgroundColor, // لون الخلفية
                      contentPadding: const EdgeInsets.all(16),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide:
                        BorderSide(color: context.theme.dividerColor),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide:
                        BorderSide(color: context.theme.dividerColor),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                            color: Colors.blue, width: 2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Allergies
                  Text('Allergies'.tr,
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: context.textTheme.bodyLarge?.color)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: controller.allergiesController,
                    maxLines: 3,
                    textAlign: TextAlign.left,
                    style: TextStyle(color: context.textTheme.bodyLarge?.color), // لون النص
                    decoration: InputDecoration(
                      hintText: 'Enter any allergies the child has'.tr,
                      hintStyle: TextStyle(
                          color: context.textTheme.bodyMedium?.color, fontSize: 13),
                      suffixIcon: const Icon(Icons.shield_outlined,
                          color: Colors.blue),
                      filled: true,
                      fillColor: context.theme.scaffoldBackgroundColor, // لون الخلفية
                      contentPadding: const EdgeInsets.all(16),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide:
                        BorderSide(color: context.theme.dividerColor),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide:
                        BorderSide(color: context.theme.dividerColor),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                            color: Colors.blue, width: 2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),

                  // Save Button
                  Obx(() => controller.isLoading
                      ? const Center(
                      child: CircularProgressIndicator(
                          color: Colors.blue))
                      : PrimaryButton(
                    text: 'Save'.tr,
                    onPressed: controller.addChild,
                  )),
                  const SizedBox(height: 20),
                ],
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}