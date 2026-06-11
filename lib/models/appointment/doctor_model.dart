import 'package:get/get.dart';
class DoctorModel {
  final int id;
  final String firstName;
  final String lastName;
  final String? profilePicture;
  final String departmentName;
  final bool isFavorite;

  // دالة مساعدة لجمع الاسم الأول والأخير مع بادئة "د."
  String get fullName => '${'Dr. '.tr}$firstName $lastName';

  DoctorModel({
    required this.id,
    required this.firstName,
    required this.lastName,
    this.profilePicture,
    required this.departmentName,
    required this.isFavorite,
  });

  factory DoctorModel.fromJson(Map<String, dynamic> json) {
    return DoctorModel(
      // معالجة الـ ID سواء جاء كنص أو رقم
      id: json['id'] is int ? json['id'] : int.parse(json['id'].toString()),

      firstName: json['first_name']?.toString() ?? '',
      lastName: json['last_name']?.toString() ?? '',

      // 🌟 الحماية الأولى: قراءة 'profile_picture' (للواجهة القديمة) وإن لم يجدها يقرأ 'image' (للمفضلة)
      profilePicture: json['profile_picture']?.toString() ?? json['image']?.toString(),

      // 🌟 الحماية الثانية: إذا كان القسم Map (واجهة قديمة) يقرأ اسمه، وإذا كان String (المفضلة) يقرأه مباشرة
      departmentName: json['department'] is Map
          ? (json['department']['name']?.toString() ?? '')
          : (json['department']?.toString() ?? ''),

      // معالجة حالة المفضلة سواء جاءت Boolean أو 0/1
      isFavorite: json['is_favorite'] is bool
          ? json['is_favorite']
          : (json['is_favorite'].toString() == '1' || json['is_favorite'].toString() == 'true'),
    );
  }
}