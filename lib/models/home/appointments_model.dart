import 'package:get/get.dart'; // ─── استيراد مكتبة Get ضروري لاستخدام .tr ───

class AppointmentsModel {
  final int id;
  final String doctorName;
  final String specialty;
  final String date;
  final String time;
  final String status;
  final String? doctorImage;

  // الحقول الخاصة بالطفل
  final String childName;
  final String? childImage;

  const AppointmentsModel({
    required this.id,
    required this.doctorName,
    required this.specialty,
    required this.date,
    required this.time,
    required this.status,
    this.doctorImage,
    required this.childName,
    this.childImage,
  });

  factory AppointmentsModel.fromJson(Map<String, dynamic> json) {
    // 1. استخراج بيانات الطبيب من الكائن المتداخل (Nested Object)
    final doctor = json['doctor'] as Map<String, dynamic>?;

    // إضافة .tr للقيم الافتراضية
    final doctorName = doctor != null
        ? (doctor['full_name'] ?? 'Unknown Doctor'.tr)
        : (json['doctor_name'] ?? 'Unknown Doctor'.tr);

    final specialty = doctor != null
        ? (doctor['specialty'] ?? doctor['department'] ?? 'General'.tr)
        : (json['specialty'] ?? json['department'] ?? 'General'.tr);

    final doctorImage = doctor != null ? doctor['image'] : json['doctor_image'];

    // 2. استخراج بيانات الطفل من الكائن المتداخل (Nested Object)
    final child = json['child'] as Map<String, dynamic>?;

    // إضافة .tr للقيم الافتراضية
    final childName = child != null
        ? (child['first_name'] ?? 'Unknown Child'.tr)
        : (json['child_name'] ?? 'Unknown Child'.tr);

    final childImage = child != null ? child['image'] : json['child_image'];

    // 🌟 التعديل الجوهري هنا: تحصين الـ ID ضد أخطاء النوع (String vs Int)
    int parsedId = 0;
    if (json['id'] != null) {
      if (json['id'] is int) {
        parsedId = json['id'];
      } else {
        parsedId = int.tryParse(json['id'].toString()) ?? 0;
      }
    }

    return AppointmentsModel(
      id: parsedId, // استخدام الـ ID الآمن
      doctorName: doctorName,
      specialty: specialty,
      date: json['date']?.toString() ?? '', // تحصين التاريخ
      time: json['time']?.toString() ?? '', // تحصين الوقت
      status: json['status']?.toString() ?? 'pending',
      doctorImage: doctorImage?.toString(),
      childName: childName,
      childImage: childImage?.toString(),
    );
  }
}