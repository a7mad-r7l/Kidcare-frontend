import 'package:get/get.dart';
import '../../core/repos/vaccines/vaccines_repo.dart';
import '../../models/vaccines/vaccine_schedule_model.dart';
import '../../models/vaccines/vaccine_history_model.dart';
import '../base_controller.dart';
import '../home/child_profile_controller.dart';
import '../../models/appointment/child_model.dart';

class VaccinesController extends BaseController {
  final VaccinesRepo repo;
  VaccinesController({required this.repo});

  late int childId;
  final Rx<ChildModel?> childInfo = Rx<ChildModel?>(null);

  final RxInt selectedTab = 0.obs; // 0 = Available, 1 = History
  final availableSchedules = <VaccineScheduleModel>[].obs;
  final historyRecords = <VaccineHistoryModel>[].obs;

  @override
  void onInit() {
    super.onInit();
    childId = Get.arguments as int? ?? 0;

    // استغلال الذاكرة: جلب بيانات الطفل من المتحكم الأب المفتوح حالياً دون الحاجة لاتصال API
    if (Get.isRegistered<ChildProfileController>()) {
      childInfo.value = Get.find<ChildProfileController>().child.value;
    }

    if (childId != 0) {
      _loadData();
    }
  }

  void switchTab(int index) {
    if (selectedTab.value == index) return;
    selectedTab.value = index;
  }

  Future<void> _loadData() async {
    showLoading();
    try {
      // جلب البيانات المتوازية لتقليل وقت الانتظار إلى النصف
      final results = await Future.wait([
        repo.fetchAvailableSchedules(childId),
        repo.fetchChildHistory(childId),
      ]);

      availableSchedules.assignAll(results[0] as List<VaccineScheduleModel>);
      historyRecords.assignAll(results[1] as List<VaccineHistoryModel>);
    } catch (e) {
      handleError(e);
    } finally {
      hideLoading();
    }
  }

  Future<void> refreshData() async => await _loadData();
}