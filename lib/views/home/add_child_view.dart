import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../controllers/home/add_child_controller.dart';
import '../../widgets/custom_text_field.dart';


class AddChildView extends GetView<AddChildController> {
  const AddChildView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEEF4FF),
      appBar: AppBar(
        backgroundColor: const Color(0xFFEEF4FF),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black87, size: 20),
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
                onTap: controller.pickImage, // ✅
                child: Obx(() => Stack(
                  children: [
                    CircleAvatar(
                      radius: 55,
                      backgroundColor: Colors.white,
                      // ✅ يعرض الصورة المختارة أو الـ placeholder
                      backgroundImage: controller.selectedImage.value != null
                          ? FileImage(controller.selectedImage.value!)
                          : null,
                      child: controller.selectedImage.value == null
                          ? Icon(Icons.person,
                          color: Colors.blue.shade200, size: 60)
                          : null,
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: const BoxDecoration(
                          color: Color(0xFF3B9EFF),
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
            const Center(
              child: Text(
                'Add New Child',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A2E5A),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // ─── Form Card ────────────────────────────
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
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
                            const Text('First Name',
                                style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF1A2E5A))),
                            const SizedBox(height: 8),
                            CustomTextField(
                              controller: controller.firstNameController,
                              hintText: 'Enter first name',
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Last Name',
                                style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF1A2E5A))),
                            const SizedBox(height: 8),
                            CustomTextField(
                              controller: controller.lastNameController,
                              hintText: 'Enter last name',
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Gender
                  const Text('Gender',
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1A2E5A))),
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
                              color: controller.selectedGender.value == 'female'
                                  ? const Color(0xFFFCE4EC)
                                  : Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: controller.selectedGender.value == 'female'
                                    ? Colors.pinkAccent
                                    : Colors.grey.shade300,
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
                                Text('Female',
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
                              color: controller.selectedGender.value == 'male'
                                  ? const Color(0xFFE3F2FD)
                                  : Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: controller.selectedGender.value == 'male'
                                    ? Colors.blue
                                    : Colors.grey.shade300,
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
                                Text('Male',
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
                  const Text('Birth Date',
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1A2E5A))),
                  const SizedBox(height: 8),
                  Obx(() => GestureDetector(
                    onTap: () => controller.pickBirthDate(context),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 15),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Icon(Icons.calendar_today_outlined,
                              color: Colors.blue, size: 20),
                          Text(
                            controller.selectedBirthDate.value.isEmpty
                                ? 'Select birth date'
                                : controller.selectedBirthDate.value,
                            style: TextStyle(
                              fontSize: 13,
                              color: controller.selectedBirthDate.value.isEmpty
                                  ? Colors.grey.shade400
                                  : Colors.black87,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )),
                  const SizedBox(height: 20),

                  // Blood Type
                  const Text('Blood Type',
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1A2E5A))),
                  const SizedBox(height: 8),
                  Obx(() => Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        isExpanded: true,
                        hint: Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            const Icon(Icons.water_drop_outlined,
                                color: Colors.blue, size: 18),
                            const SizedBox(width: 8),
                            Text('Select blood type',
                                style: TextStyle(
                                    color: Colors.grey.shade400,
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
                  const Text('Medical History',
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1A2E5A))),
                  const SizedBox(height: 8),
                  TextField(
                    controller: controller.medicalHistoryController,
                    maxLines: 3,
                    textAlign: TextAlign.left,
                    decoration: InputDecoration(
                      hintText: "Enter child's medical history",
                      hintStyle: TextStyle(
                          color: Colors.grey.shade400, fontSize: 13),
                      suffixIcon: const Icon(Icons.calendar_month_outlined,
                          color: Colors.blue),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.all(16),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide:
                        BorderSide(color: Colors.grey.shade300),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide:
                        BorderSide(color: Colors.grey.shade300),
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
                  const Text('Allergies',
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1A2E5A))),
                  const SizedBox(height: 8),
                  TextField(
                    controller: controller.allergiesController,
                    maxLines: 3,
                    textAlign: TextAlign.left,
                    decoration: InputDecoration(
                      hintText: 'Enter any allergies the child has',
                      hintStyle: TextStyle(
                          color: Colors.grey.shade400, fontSize: 13),
                      suffixIcon: const Icon(Icons.shield_outlined,
                          color: Colors.blue),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.all(16),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide:
                        BorderSide(color: Colors.grey.shade300),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide:
                        BorderSide(color: Colors.grey.shade300),
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
                    text: 'Save',
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