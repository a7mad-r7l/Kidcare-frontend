class UserModel {
  final int id;
  final String firstName;
  final String lastName;
  final String phoneNumber;
  final String token;

  UserModel({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.phoneNumber,
    required this.token,
  });

  factory UserModel.fromJson(Map<String, dynamic> json, String token) {
    return UserModel(
      id: json['id'],
      firstName: json['first_name'],
      lastName: json['last_name'],
      // ضفنا toString() لأن السيرفر يرسل الرقم كـ int وليس String
      phoneNumber: json['phone_number'].toString(),
      token: token,
    );
  }
}