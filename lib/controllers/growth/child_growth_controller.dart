import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/repos/growth/child_growth_repo.dart';
import '../../models/growth/child_growth_response_model.dart';
import '../base_controller.dart';

class ChildGrowthController extends BaseController {
  final ChildGrowthRepo repo;

  ChildGrowthController({required this.repo});

  late int childId;
  final Rxn<ChildGrowthResponseModel> growthData =
      Rxn<ChildGrowthResponseModel>();

  final weightController = TextEditingController();
  final heightController = TextEditingController();
  final RxString selectedDate = ''.obs;

  @override
  void onInit() {
    super.onInit();

    if (Get.arguments is int) {
      childId = Get.arguments as int;
    } else {
      childId = 0; // Fallback
    }

    if (childId != 0) {
      getGrowthDashboard();
    }
  }

  /// 1. جلب بيانات النمو والمخطط من السيرفر (GET)
  Future<void> getGrowthDashboard() async {
    showLoading();
    try {
      final result = await repo.fetchChildGrowthData(childId);
      growthData.value = result;
    } catch (e) {
      handleError(e);
    } finally {
      hideLoading();
    }
  }

  /// 2. إضافة سجل قياس وزني وطولي جديد (POST)
  Future<void> addMeasurement() async {
    final String weightText = weightController.text.trim();
    final String heightText = heightController.text.trim();
    final String recordDate = selectedDate.value;

    final double? weight = double.tryParse(weightText);
    final double? height = double.tryParse(heightText);

    if (weight == null ||
        height == null ||
        weight <= 0 ||
        height <= 0 ||
        recordDate.isEmpty) {
      showInfo('Please enter valid weight and height'.tr);
      return;
    }

    showLoading();
    try {
      final statusResult = await repo.addNewGrowthRecord(
        childId: childId,
        height: height,
        weight: weight,
        recordDate: recordDate,
      );

      Get.back();
      _clearForm();

      showSuccess(
        '${'Measurement saved successfully'.tr} (${statusResult.tr})',
      );

      await getGrowthDashboard();
    } catch (e) {
      handleError(e);
    } finally {
      hideLoading();
    }
  }

  /// 3. حذف سجل قياس سابق  (DELETE)
  Future<void> deleteMeasurement(int growthId) async {
    showLoading();
    try {
      await repo.removeGrowthRecord(growthId);

      await getGrowthDashboard();
    } catch (e) {
      handleError(e);
    } finally {
      hideLoading();
    }
  }

  Future<void> pickRecordDate(BuildContext context) async {
    final now = DateTime.now();
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: DateTime(now.year - 6),
      lastDate: now,
    );
    if (picked != null) {
      selectedDate.value =
          '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
    }
  }

  void _clearForm() {
    weightController.clear();
    heightController.clear();
    selectedDate.value = '';
  }

  @override
  void onClose() {
    weightController.dispose();
    heightController.dispose();
    super.onClose();
  }
}
