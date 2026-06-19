import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/home/notification_history_controller.dart';

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
            fontSize: 18,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios,
            color: context.iconColor,
            size: 20,
          ),
          onPressed: () => Get.back(),
        ),
      ),
      body: SafeArea(
        child: Obx(() {
          if (controller.isLoading && controller.notifications.isEmpty) {
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
                    size: 64,
                    color: context.theme.dividerColor,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No notifications found'.tr,
                    style: TextStyle(
                      color: context.textTheme.bodyMedium?.color,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () => controller.getNotifications(),
            color: context.theme.primaryColor,
            child: ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              itemCount: controller.notifications.length,
              itemBuilder: (context, index) {
                final item = controller.notifications[index];
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: context.theme.cardColor,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      if (!context.isDarkMode)
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.04),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                    ],
                    border: Border.all(color: context.theme.dividerColor),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: context.isDarkMode
                              ? context.theme.primaryColor.withValues(alpha: 0.15)
                              : context.theme.primaryColor.withValues(alpha: 0.08),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.notifications_outlined,
                          color: context.theme.primaryColor,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.title,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                color: context.textTheme.bodyLarge?.color,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              item.body,
                              style: TextStyle(
                                fontSize: 12.5,
                                color: context.textTheme.bodyMedium?.color,
                                height: 1.4,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              item.createdAt,
                              style: TextStyle(
                                fontSize: 10,
                                color: context.isDarkMode
                                    ? Colors.grey.shade500
                                    : Colors.grey.shade400,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          );
        }),
      ),
    );
  }
}