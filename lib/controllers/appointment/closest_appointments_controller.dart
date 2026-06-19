import 'package:get/get.dart';
import '../../core/repos/appointment/department_repo.dart';
import '../../core/repos/appointment/doctor_repo.dart';
import '../../models/appointment/department_model.dart';
import '../../models/appointment/closest_appointment_model.dart';
import '../base_controller.dart';

class ClosestAppointmentsController extends BaseController {
  final DepartmentRepo departmentRepo;
  final DoctorRepo doctorRepo;

  ClosestAppointmentsController({
    required this.departmentRepo,
    required this.doctorRepo,
  });

  final departments = <DepartmentModel>[].obs;
  final selectedDepartmentId = RxnInt();
  final closestAppointments = <ClosestAppointmentModel>[].obs;

  @override
  void onInit() {
    super.onInit();
    _initData();
  }

  Future<void> _initData() async {
    showLoading();
    try {
      // 1. جلب الأقسام
      departments.value = await departmentRepo.fetchAll();

      // 2. تحديد أول قسم افتراضياً وجلب مواعيده
      if (departments.isNotEmpty) {
        selectedDepartmentId.value = departments.first.id;
        await fetchClosestAppointments(departments.first.id);
      }
    } catch (e, stackTrace) {
      // إضافة الطباعة هنا لمعرفة سبب الخطأ عند تهيئة الواجهة
      print('=== Error in _initData ===');
      print('Exception: $e');
      print('StackTrace: $stackTrace');
      print('==========================');

      handleError(e);
    } finally {
      hideLoading();
    }
  }

  Future<void> fetchClosestAppointments(int departmentId) async {
    showLoading();
    try {
      selectedDepartmentId.value = departmentId;
      closestAppointments.value = await doctorRepo.fetchClosestAppointments(departmentId);
    } catch (e, stackTrace) {
      // إضافة الطباعة هنا لمعرفة سبب الخطأ عند جلب المواعيد
      print('=== Error in fetchClosestAppointments ===');
      print('Exception: $e');
      print('StackTrace: $stackTrace');
      print('=========================================');

      handleError(e);
    } finally {
      hideLoading();
    }
  }
}