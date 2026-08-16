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

    // 👈 استنتاج ذكي للعنوان بناءً على النص القادم من السيرفر
    String generatedTitle = 'KidCare Clinic'.tr;
    if (content.toLowerCase().contains('confirmed') ||
        content.contains('تم تأكيد')) {
      generatedTitle = 'Appointment Confirmed'.tr;
    } else if (content.toLowerCase().contains('cancel') ||
        content.contains('إلغاء')) {
      generatedTitle = 'Appointment Cancelled'.tr;
    }

    return NotificationHistoryModel(
      id: json['id']?.toString() ?? '',
      title: generatedTitle,
      body: content,
      type: json['type']?.toString(),
      // تحسباً لإضافته مستقبلاً في الباك إند
      createdAt: json['created_at']?.toString() ?? '',
    );
  }
}
