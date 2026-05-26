import '../../core/helper/json_utils.dart';

class DoctorModel {
  final int id;
  final int departmentId;
  final String firstName;
  final String lastName;
  final String email;
  final String address;
  final String? profilePicture;
  final double? rating;
  final String? fee;
  final String? phone;

  const DoctorModel({
    required this.id,
    required this.departmentId,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.address,
    this.profilePicture,
    this.rating,
    this.fee,
    this.phone,
  });

  factory DoctorModel.fromJson(Map<String, dynamic> json) {
    return DoctorModel(
      id: toIntSafe(json['id']),
      departmentId: toIntSafe(json['department_id']),
      firstName: json['first_name']?.toString() ?? '',
      lastName: json['last_name']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      address: json['address']?.toString() ?? '',
      profilePicture: json['profile_picture']?.toString(),
      rating: toDoubleOrNull(json['rating']),
      fee: json['fee']?.toString(),
      phone: json['phone']?.toString(),
    );
  }

  String get fullName => 'Dr. $firstName $lastName';
}
