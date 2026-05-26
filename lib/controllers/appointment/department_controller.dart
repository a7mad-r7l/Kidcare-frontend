import 'package:get/get.dart';
import '../../core/repos/appointment/department_repo.dart';
import '../../models/appointment/department_model.dart';
import '../base_controller.dart';

class DepartmentController extends BaseController {
  final DepartmentRepo repo;

  DepartmentController({required this.repo});

  final departments = <DepartmentModel>[].obs;

  @override
  void onInit() {
    super.onInit();
    loadDepartments();
  }

  Future<void> loadDepartments() async {
    showLoading();
    try {
      departments.value = await repo.fetchAll();
    } catch (e) {
      handleError(e);
    } finally {
      hideLoading();
    }
  }
}
