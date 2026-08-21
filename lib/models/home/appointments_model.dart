import 'package:get/get.dart';

class AppointmentsModel {
  final int id;
  final String doctorName;
  final String specialty;
  final String date;
  final String time;
  final String status;
  final String? doctorImage;

  // الحقول الخاصة بالطفل
  final int childId; // 👈 1. إضافة حقل childId هنا
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
    required this.childId, // 👈 2. إضافته للـ Constructor
    required this.childName,
    this.childImage,
  });

  factory AppointmentsModel.fromJson(Map<String, dynamic> json) {
    // 1. استخراج بيانات الطبيب
    final doctor = json['doctor'] as Map<String, dynamic>?;

    final doctorName = doctor != null
        ? (doctor['full_name'] ?? 'Unknown Doctor'.tr)
        : (json['doctor_name'] ?? 'Unknown Doctor'.tr);

    final specialty = doctor != null
        ? (doctor['specialty'] ?? doctor['department'] ?? 'General'.tr)
        : (json['specialty'] ?? json['department'] ?? 'General'.tr);

    final doctorImage = doctor != null ? doctor['image'] : json['doctor_image'];

    // 2. استخراج بيانات الطفل
    final child = json['child'] as Map<String, dynamic>?;

    final childName = child != null
        ? (child['first_name'] ?? 'Unknown Child'.tr)
        : (json['child_name'] ?? 'Unknown Child'.tr);

    final childImage = child != null ? child['image'] : json['child_image'];

    // 👈 3. استخراج childId بأمان من الـ JSON المتداخل أو الخارجي
    int parsedChildId = 0;
    if (child != null && child['id'] != null) {
      parsedChildId = int.tryParse(child['id'].toString()) ?? 0;
    } else if (json['child_id'] != null) {
      parsedChildId = int.tryParse(json['child_id'].toString()) ?? 0;
    }

    int parsedId = 0;
    if (json['id'] != null) {
      parsedId = int.tryParse(json['id'].toString()) ?? 0;
    }

    return AppointmentsModel(
      id: parsedId,
      doctorName: doctorName,
      specialty: specialty,
      date: json['date']?.toString() ?? '',
      time: json['time']?.toString() ?? '',
      status: json['status']?.toString() ?? 'pending',
      doctorImage: doctorImage?.toString(),
      childId: parsedChildId, // 👈 4. تمرير القيمة المستخرجة
      childName: childName,
      childImage: childImage?.toString(),
    );
  }
}