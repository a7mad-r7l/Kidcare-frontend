import 'package:get/get.dart';
import '../../core/repos/home/home_children_repo.dart';
import '../../core/repos/home/parent_name_repo.dart';
import '../../models/home/home_child_model.dart';
import '../base_controller.dart';
import 'package:flutter/material.dart';


class HomeController extends BaseController {
  final HomeChildrenRepo homeChildrenRepo;
  final ParentNameRepo parentNameRepo;

  HomeController({
    required this.homeChildrenRepo,
    required this.parentNameRepo,
  });

  final RxList<HomeChildModel> children = <HomeChildModel>[].obs;

  // ✅ اسم المستخدم
  final RxString parentName = ''.obs;

  @override
  void onInit() {
    super.onInit();
    fetchChildren();
    fetchParentName();
  }

  Future<void> fetchChildren() async {
    showLoading();
    try {
      final result = await homeChildrenRepo.getChildren();
      children.assignAll(result);
    } catch (e) {
      handleError(e);
    } finally {
      hideLoading();
    }
  }

  Future<void> fetchParentName() async {
    try {
      final name = await parentNameRepo.getParentName();
      parentName.value = name;
    } catch (e) {
      handleError(e);
    }
  }
  // ─── دالة التعامل مع زر الملفات/اللقاحات في النافيجيشن بار ───
  void onVaccinesTabTapped() {
    if (children.isEmpty) {
      showInfo('No children added yet'.tr); // استخدام دالة الـ BaseController
      return;
    }

    // إذا كان هناك طفل واحد فقط، ننتقل مباشرة
    if (children.length == 1) {
      Get.toNamed('/vaccinations', arguments: children.first.id);
      return;
    }

    // إذا كان هناك أكثر من طفل، نظهر النافذة السفلية للاختيار
    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Get.theme.scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Choose Child'.tr,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Get.textTheme.bodyLarge?.color,
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 16,
              runSpacing: 16,
              children: children.map((child) {
                return GestureDetector(
                  onTap: () {
                    Get.back(); // إغلاق النافذة
                    Get.toNamed('/vaccinations', arguments: child.id);
                  },
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircleAvatar(
                        radius: 30,
                        backgroundColor: Get.theme.primaryColor.withOpacity(0.1),
                        backgroundImage: (child.image != null && child.image!.isNotEmpty)
                            ? NetworkImage(child.image!)
                            : null,
                        child: (child.image == null || child.image!.isEmpty)
                            ? Icon(Icons.person, color: Get.theme.primaryColor)
                            : null,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        child.name,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: Get.textTheme.bodyLarge?.color,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}