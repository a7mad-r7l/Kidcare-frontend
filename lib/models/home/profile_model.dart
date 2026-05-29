// lib/models/profile_model.dart
class ProfileModel {
  final int id;
  final String firstName;
  final String lastName;
  final String email;
  final String phoneNumber;
  final String address;
  final int childrenCount;

  ProfileModel({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.phoneNumber,
    required this.address,
    required this.childrenCount,
  });

  String get fullName => '$firstName $lastName';

  factory ProfileModel.fromJson(Map<String, dynamic> json) {
    final user = json['user'];
    return ProfileModel(
      id: user['id'] ?? 0,
      firstName: user['first_name'] ?? '',
      lastName: user['last_name'] ?? '',
      email: user['email'] ?? '',
      phoneNumber: user['phone_number'] ?? '',
      address: user['address'] ?? '',
      childrenCount: (user['children'] as List?)?.length ?? 0,
    );
  }
}
