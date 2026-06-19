import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/repos/home/add_child_repo.dart';
import '../base_controller.dart';
import 'home_controller.dart';

class AddChildController extends BaseController {
  final AddChildRepo addChildRepo;

  AddChildController({required this.addChildRepo});

  final firstNameController = TextEditingController();
  final lastNameController = TextEditingController();
  final medicalHistoryController = TextEditingController();
  final allergiesController = TextEditingController();

  final RxString selectedGender = 'male'.obs;
  final RxString selectedBloodType = ''.obs;
  final RxString selectedBirthDate = ''.obs;

  final Rx<File?> selectedImage = Rx<File?>(null);

  final List<String> bloodTypes = [
    'A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-'
  ];

  void selectGender(String gender) => selectedGender.value = gender;

  Future<void> deleteChild(int childId) async {
    showLoading();
    try {
      await addChildRepo.deleteChild(childId);

      Get.snackbar(
        'Success'.tr,
        'Child deleted successfully!'.tr,
        backgroundColor: Colors.green,
        colorText: Colors.white,
        snackPosition: SnackPosition.TOP,
        margin: const EdgeInsets.all(15),
      );

      await Future.delayed(const Duration(seconds: 1));
      Get.offAllNamed('/home');
    } catch (e) {
      handleError(e);
    } finally {
      hideLoading();
    }
  }

  Future<void> pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );
    if (image != null) {
      selectedImage.value = File(image.path);
    }
  }

  Future<void> pickBirthDate(BuildContext context) async {
    final now = DateTime.now();
    final earliestAllowedDate = DateTime(now.year - 6, now.month, now.day);

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: earliestAllowedDate,
      lastDate: now,
    );
    if (picked != null) {
      selectedBirthDate.value =
      '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
    }
  }

  Future<void> addChild() async {
    // 1. التحقق من الحقول الإلزامية (Client-Side Validation)
    if (firstNameController.text.isEmpty || lastNameController.text.isEmpty) {
      Get.snackbar(
        'Required Fields'.tr,
        'Please enter first and last name'.tr,
        backgroundColor: Colors.grey.shade700,
        colorText: Colors.white,
        snackPosition: SnackPosition.TOP,
        margin: const EdgeInsets.all(15),
        duration: const Duration(seconds: 2),
      );
      return;
    }

    if (selectedBirthDate.value.isEmpty) {
      Get.snackbar(
        'Required Fields'.tr,
        'Please select birth date'.tr,
        backgroundColor: Colors.grey.shade700,
        colorText: Colors.white,
        snackPosition: SnackPosition.TOP,
        margin: const EdgeInsets.all(15),
        duration: const Duration(seconds: 2),
      );
      return;
    }

    // التحقق من العمر (ألا يتجاوز 6 سنوات)
    final birthDate = DateTime.tryParse(selectedBirthDate.value);
    if (birthDate != null) {
      final now = DateTime.now();
      final ageLimitDate = DateTime(now.year - 6, now.month, now.day);
      if (birthDate.isBefore(ageLimitDate)) {
        Get.snackbar(
          'Invalid Age'.tr,
          'Child age cannot exceed 6 years.'.tr,
          backgroundColor: Colors.grey.shade700,
          colorText: Colors.white,
          snackPosition: SnackPosition.TOP,
          margin: const EdgeInsets.all(15),
          duration: const Duration(seconds: 2),
        );
        return;
      }
    }

    if (selectedBloodType.value.isEmpty) {
      Get.snackbar(
        'Required Fields'.tr,
        'Please select blood type'.tr,
        backgroundColor: Colors.grey.shade700,
        colorText: Colors.white,
        snackPosition: SnackPosition.TOP,
        margin: const EdgeInsets.all(15),
        duration: const Duration(seconds: 2),
      );
      return;
    }

    // 2. معالجة الحقول الاختيارية (Data Sanitization)
    final String medicalHistory = medicalHistoryController.text.trim().isEmpty
        ? 'No medical history'.tr
        : medicalHistoryController.text.trim();

    final String allergies = allergiesController.text.trim().isEmpty
        ? 'No allergies'.tr
        : allergiesController.text.trim();

    showLoading();
    try {
      // 3. إرسال الطلب للـ API عبر الـ Repository
      await addChildRepo.addChild(
        firstName: firstNameController.text.trim(),
        lastName: lastNameController.text.trim(),
        gender: selectedGender.value,
        birthDate: selectedBirthDate.value,
        bloodType: selectedBloodType.value,
        medicalHistory: medicalHistory,
        allergies: allergies,
        image: selectedImage.value,
      );

      // 4. عرض رسالة النجاح
      Get.snackbar(
        'Success'.tr,
        'Child added successfully!'.tr,
        backgroundColor: Colors.green,
        colorText: Colors.white,
        snackPosition: SnackPosition.TOP,
        margin: const EdgeInsets.all(15),
      );

      // تأخير بسيط ليتمكن المستخدم من قراءة رسالة النجاح
      await Future.delayed(const Duration(seconds: 1));

      // 5. التوجيه الشامل للرئيسية لضمان تحديث البيانات ومسح الـ Stack
      Get.offAllNamed('/home');

    } catch (e) {
      handleError(e);
    } finally {
      hideLoading();
    }
  }

  @override
  void onClose() {
    firstNameController.dispose();
    lastNameController.dispose();
    medicalHistoryController.dispose();
    allergiesController.dispose();
    super.onClose();
  }
}