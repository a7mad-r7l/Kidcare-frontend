import '../../core/helper/json_utils.dart';

class ChildModel {
  final int id;
  final int parentId;
  final String firstName;
  final String lastName;
  final String gender;
  final DateTime birthDate;
  final String? bloodType;
  final String? image;
  final String? medicalHistory;
  final String? allergies;

  const ChildModel({
    required this.id,
    required this.parentId,
    required this.firstName,
    required this.lastName,
    required this.gender,
    required this.birthDate,
    this.bloodType,
    this.image,
    this.medicalHistory,
    this.allergies,
  });

  factory ChildModel.fromJson(Map<String, dynamic> json) {
    return ChildModel(
      id: toIntSafe(json['id']),
      parentId: toIntSafe(json['parent_id']),
      firstName: json['first_name']?.toString() ?? '',
      lastName: json['last_name']?.toString() ?? '',
      gender: json['gender']?.toString() ?? '',
      birthDate:
          DateTime.tryParse(json['birth_date']?.toString() ?? '') ??
              DateTime.now(),
      bloodType: json['blood_type']?.toString(),
      image: json['image']?.toString(),
      medicalHistory: json['medical_history']?.toString(),
      allergies: json['allergies']?.toString(),
    );
  }

  String get fullName => '$firstName $lastName';

  // 👈 احذف دالة `int get ageYears` القديمة وضع مكانها هذا الكود:

  int get ageNumber {
    final now = DateTime.now();
    int years = now.year - birthDate.year;
    if (now.month < birthDate.month || (now.month == birthDate.month && now.day < birthDate.day)) years--;

    if (years >= 1) return years;

    int months = (now.year - birthDate.year) * 12 + now.month - birthDate.month;
    if (now.day < birthDate.day) months--;

    if (months >= 1) return months;

    int days = now.difference(birthDate).inDays;
    return days >= 0 ? days : 0;
  }

  String get ageType {
    final now = DateTime.now();
    int years = now.year - birthDate.year;
    if (now.month < birthDate.month || (now.month == birthDate.month && now.day < birthDate.day)) years--;

    if (years >= 1) return 'year';

    int months = (now.year - birthDate.year) * 12 + now.month - birthDate.month;
    if (now.day < birthDate.day) months--;

    if (months >= 1) return 'month';
    return 'day';
  }
}
