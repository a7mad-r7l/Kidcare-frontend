import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/repos/home/child_profile_repo.dart';
import '../../models/appointment/child_model.dart';
import '../../models/home/home_child_model.dart';
import '../base_controller.dart';
import 'home_controller.dart';
import 'dart:io';
class ChildProfileController extends BaseController {
  final ChildProfileRepo repo;

  ChildProfileController({required this.repo});

  final Rx<ChildModel?> child = Rx<ChildModel?>(null);
  late int childId;

  @override
  void onInit() {
    super.onInit();
    final arg = Get.arguments;

    // استخراج الـ ID سواء تم تمرير HomeChildModel أو ID مباشر
    if (arg is HomeChildModel) {
      childId = arg.id;
    } else if (arg is int) {
      childId = arg;
    } else {
      childId = 0;
    }

    if (childId != 0) {
      fetchChildDetails();
    }
  }

  Future<void> fetchChildDetails() async {
    showLoading();
    try {
      final result = await repo.getChildDetails(childId);
      child.value = result;
    } catch (e) {
      handleError(e);
    } finally {
      hideLoading();
    }
  }
  Future<void> updateChildData({
    Map<String, String>? fields,
    File? image,
  }) async {
    if ((fields == null || fields.isEmpty) && image == null) return;

    showLoading();
    try {
      await repo.updateChild(
        childId: childId,
        fields: fields,
        image: image,
      );

      // جلب البيانات من جديد لتحديث شاشة البروفايل تلقائياً
      await fetchChildDetails();

      // تحديث قائمة الأطفال في الرئيسية لتنعكس التعديلات (مثل الاسم أو الصورة)
      if (Get.isRegistered<HomeController>()) {
        Get.find<HomeController>().fetchChildren();
      }

      Get.back(); // إغلاق نافذة التعديل إن كنت تستخدم Dialog أو BottomSheet
      showSuccess('Child profile updated successfully'.tr);
    } catch (e) {
      handleError(e);
    } finally {
      hideLoading();
    }
  }


  // الآن الدالة تستخدم الـ repo الخاص بـ هذا الـ Controller مباشرة
  Future<void> deleteCurrentChild() async {
    showLoading();
    try {
      // استدعاء دالة الحذف التي أضفناها للـ Repo
      await repo.deleteChild(childId);
      if (Get.isRegistered<HomeController>()) {
        Get.find<HomeController>().fetchChildren(); // أو دالة التحديث الموجودة عندك
      }

      // بعد نجاح الحذف، نغلق شاشة البروفايل ونعود للرئيسية
      Get.back();
      Get.snackbar(
        'Success'.tr,
        'Child deleted successfully'.tr,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
    } catch (e) {
      handleError(e);
    } finally {
      hideLoading();
    }
  }
}