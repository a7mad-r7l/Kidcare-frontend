import 'package:get/get.dart';
import '../../core/repos/home/child_profile_repo.dart';
import '../../models/appointment/child_model.dart';
import '../../models/home/home_child_model.dart';
import '../base_controller.dart';
import 'add_child_controller.dart';

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

  // استخدام دالة الحذف الموجودة في AddChildController لتجنب تكرار الكود
  Future<void> deleteCurrentChild() async {
    if (Get.isRegistered<AddChildController>()) {
      Get.find<AddChildController>().deleteChild(childId);
    }
  }
}