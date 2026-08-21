import 'package:get/get.dart';

class NotificationHistoryModel {
  final String id;
  final String title;
  final String body;
  final String? type;
  final String createdAt;

  NotificationHistoryModel({
    required this.id,
    required this.title,
    required this.body,
    this.type,
    required this.createdAt,
  });

  factory NotificationHistoryModel.fromJson(Map<String, dynamic> json) {
    final String content =
        json['message']?.toString() ?? json['body']?.toString() ?? '';

    String generatedTitle = 'KidCare Clinic'.tr;
    if (content.toLowerCase().contains('confirmed') ||
        content.contains('تم تأكيد')) {
      generatedTitle = 'Appointment Confirmed'.tr;
    } else if (content.toLowerCase().contains('cancel') ||
        content.contains('إلغاء')) {
      generatedTitle = 'Appointment Cancelled'.tr;
    }

    String rawDate = json['created_at']?.toString() ?? '';
    String formattedDate = '';

    if (rawDate.isNotEmpty) {
      try {
        DateTime dt = DateTime.parse(rawDate).toLocal();

        String year = dt.year.toString().padLeft(4, '0');
        String month = dt.month.toString().padLeft(2, '0');
        String day = dt.day.toString().padLeft(2, '0');
        String hour = dt.hour.toString().padLeft(2, '0');
        String minute = dt.minute.toString().padLeft(2, '0');

        formattedDate = '$year-$month-$day   $hour:$minute';
      } catch (_) {
        formattedDate = rawDate.split('.').first.replaceAll('T', ' ');
      }
    }

    return NotificationHistoryModel(
      id: json['id']?.toString() ?? '',
      title: generatedTitle,
      body: content,
      type: json['type']?.toString(),
      createdAt: formattedDate,
    );
  }
}
