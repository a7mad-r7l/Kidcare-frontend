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

  factory UserModel.fromJson(Map<String, dynamic> json,String token) {
    return UserModel(
      id: json['user']['id'],
      firstName: json['user']['first_name'],
      lastName: json['user']['last_name'],
      phoneNumber: json['user']['phone_number'],

      token: json['Token'],
    );
  }
}
