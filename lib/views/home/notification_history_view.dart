import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../controllers/home/notification_history_controller.dart';
import '../../models/home/notification_history_model.dart';

class NotificationHistoryView extends GetView<NotificationHistoryController> {
  const NotificationHistoryView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'Notifications'.tr,
          style: TextStyle(
            color: context.textTheme.bodyLarge?.color,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios,
            color: context.theme.iconTheme.color,
            size: 20,
          ),
          onPressed: () => Get.back(),
        ),
      ),
      body: Obx(() {
        if (controller.isLoading) {
          return Center(
            child: CircularProgressIndicator(color: context.theme.primaryColor),
          );
        }

        if (controller.notifications.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.notifications_off_outlined,
                  size: 60,
                  color: context.theme.dividerColor,
                ),
                const SizedBox(height: 16),
                Text(
                  'No notifications found'.tr,
                  style: TextStyle(
                    color: context.textTheme.bodyMedium?.color,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: controller.notifications.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final notification = controller.notifications[index];
            return _buildNotificationCard(context, notification);
          },
        );
      }),
    );
  }

  Widget _buildNotificationCard(
    BuildContext context,
    NotificationHistoryModel item,
  ) {

    String formattedDate = item.createdAt;
    try {
      final DateTime parsedDate = DateTime.parse(item.createdAt).toLocal();

      formattedDate = DateFormat(
        'dd MMM yyyy,   hh:mm a',
        Get.locale?.languageCode,
      ).format(parsedDate);
    } catch (_) {}

    return InkWell(
      onTap: () => _handleNotificationTap(item),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: context.theme.cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: context.theme.dividerColor.withOpacity(0.4),
          ),
          boxShadow: [
            BoxShadow(
              color: context.isDarkMode
                  ? Colors.transparent
                  : Colors.black.withOpacity(0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: context.theme.primaryColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.notifications_active_outlined,
                color: context.theme.primaryColor,
                size: 24,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: context.textTheme.bodyLarge?.color,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    item.body,
                    style: TextStyle(
                      fontSize: 13,
                      color: context.textTheme.bodyMedium?.color,

                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Icon(
                        Icons.access_time,
                        size: 12,
                        color: context.theme.hintColor,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        formattedDate,
                        style: TextStyle(
                          fontSize: 11,
                          color: context.theme.hintColor,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── الإجراء عند ضغط اليوزر على الإشعار ───
  void _handleNotificationTap(NotificationHistoryModel item) {


    final content = item.body.toLowerCase();

    if (content.contains('appointment') || content.contains('موعد')) {

      Get.toNamed('/appointments');
    } else {

      Get.offAllNamed('/home');
    }
  }
}
