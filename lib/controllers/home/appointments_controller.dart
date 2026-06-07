import 'package:get/get.dart';
import '../../core/repos/home/appointments_repo.dart';
import '../../models/home/appointments_model.dart';
import '../base_controller.dart';

class AppointmentsController extends BaseController {
  final AppointmentsRepo appointmentsRepo;

  AppointmentsController({required this.appointmentsRepo});

  // جعلناه Nullable، فإذا كان null، فهذا يعني أننا طلبنا كل المواعيد
  int? childId;

  final RxList<AppointmentsModel> upcoming = <AppointmentsModel>[].obs;
  final RxList<AppointmentsModel> past = <AppointmentsModel>[].obs;
  final RxBool showUpcoming = true.obs;

  @override
  void onInit() {
    super.onInit();
    // التقاط الـ ID إذا أتينا من شاشة الطفل، وإلا سيبقى null
    if (Get.arguments is int) {
      childId = Get.arguments as int;
    }
    fetchUpcoming();
  }

  void switchTab(bool isUpcoming) {
    showUpcoming.value = isUpcoming;
    if (isUpcoming && upcoming.isEmpty) {
      fetchUpcoming();
    } else if (!isUpcoming && past.isEmpty) {
      fetchPast();
    }
  }

  Future<void> fetchUpcoming() async {
    showLoading();
    try {
      // توجيه ذكي للطلب
      final result = childId != null
          ? await appointmentsRepo.getUpcomingForChild(childId!)
          : await appointmentsRepo.getAllUpcoming();
      upcoming.assignAll(result);
    } catch (e) {
      handleError(e);
    } finally {
      hideLoading();
    }
  }

  Future<void> fetchPast() async {
    showLoading();
    try {
      // توجيه ذكي للطلب
      final result = childId != null
          ? await appointmentsRepo.getPastForChild(childId!)
          : await appointmentsRepo.getAllPast();
      past.assignAll(result);
    } catch (e) {
      handleError(e);
    } finally {
      hideLoading();
    }
  }
}