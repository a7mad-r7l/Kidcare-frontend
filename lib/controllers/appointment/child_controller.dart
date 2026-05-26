import 'package:get/get.dart';
import '../../core/repos/appointment/child_repo.dart';
import '../../models/appointment/child_model.dart';
import '../base_controller.dart';

class ChildController extends BaseController {
  final ChildRepo repo;

  ChildController({required this.repo});

  final children = <ChildModel>[].obs;

  @override
  void onInit() {
    super.onInit();
    loadChildren();
  }

  Future<void> loadChildren() async {
    showLoading();
    try {
      children.value = await repo.fetchMyChildren();
    } catch (e) {
      handleError(e);
    } finally {
      hideLoading();
    }
  }
}
