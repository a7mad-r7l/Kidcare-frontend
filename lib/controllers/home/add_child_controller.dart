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

  // ✅ الصورة المختارة
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
      Get.offAllNamed('/home'); // ✅ العودة للـ home بعد الحذف
    } catch (e) {
      handleError(e);
    } finally {
      hideLoading();
    }
  }

  // ✅ فتح الـ Gallery
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
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime(2020),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      selectedBirthDate.value =
      '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
    }
  }

  Future<void> addChild() async {
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

    showLoading();
    try {
      await addChildRepo.addChild(
        firstName: firstNameController.text.trim(),
        lastName: lastNameController.text.trim(),
        gender: selectedGender.value,
        birthDate: selectedBirthDate.value,
        bloodType: selectedBloodType.value,
        medicalHistory: medicalHistoryController.text.trim(),
        allergies: allergiesController.text.trim(),
        image: selectedImage.value, // ✅
      );

      Get.snackbar(
        'Success'.tr,
        'Child added successfully!'.tr,
        backgroundColor: Colors.green,
        colorText: Colors.white,
        snackPosition: SnackPosition.TOP,
        margin: const EdgeInsets.all(15),
      );
      await Future.delayed(const Duration(seconds: 1));
      Get.back();
      if (Get.isRegistered<HomeController>()) {
        Get.find<HomeController>().fetchChildren();
      }
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