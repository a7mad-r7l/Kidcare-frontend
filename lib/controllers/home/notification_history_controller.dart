import 'package:get/get.dart';
import '../../core/repos/home/notification_history_repo.dart';
import '../../models/home/notification_history_model.dart';
import '../base_controller.dart';

class NotificationHistoryController extends BaseController {
  final NotificationHistoryRepo repo;

  NotificationHistoryController({required this.repo});

  final RxList<NotificationHistoryModel> notifications =
      <NotificationHistoryModel>[].obs;

  @override
  void onInit() {
    super.onInit();
    getNotifications();
  }

  Future<void> getNotifications() async {
    showLoading();
    try {
      final result = await repo.fetchNotifications();
      notifications.assignAll(result);
    } catch (e) {
      handleError(e);
    } finally {
      hideLoading();
    }
  }
}
