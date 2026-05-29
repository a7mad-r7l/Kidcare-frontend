import 'package:get/get.dart';
import '../../core/repos/home/home_children_repo.dart';
import '../../core/repos/home/parent_name_repo.dart';
import '../../models/home/home_child_model.dart';
import '../base_controller.dart';


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
}