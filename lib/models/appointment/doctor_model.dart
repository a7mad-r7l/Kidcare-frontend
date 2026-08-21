class DoctorModel {
  final int id;
  final String firstName;
  final String lastName;
  final String email;
  final String address;
  final String? departmentName;
  final String? profilePicture;
  final bool isFavorite;
  final String? department;

  DoctorModel({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.address,
    this.departmentName,
    this.profilePicture,
    required this.isFavorite,
    this.department,
  });

  String get fullName => '$firstName $lastName';

  factory DoctorModel.fromJson(Map<String, dynamic> json) {
    bool favoriteValue = false;
    final fav = json['is_favorite'] ?? json['isFavorite'];
    if (fav != null) {
      if (fav is bool) favoriteValue = fav;
      if (fav is int) favoriteValue = fav == 1;
      if (fav is String) {
        favoriteValue = fav == '1' || fav.toLowerCase() == 'true';
      }
    }

    return DoctorModel(
      id: json['id'] is int
          ? json['id']
          : int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      firstName:
          json['first_name']?.toString() ?? json['firstName']?.toString() ?? '',
      lastName:
          json['last_name']?.toString() ?? json['lastName']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      address: json['address']?.toString() ?? '',
      departmentName:
          json['department_name']?.toString() ??
          json['departmentName']?.toString() ??
          '',
      profilePicture:
          json['profile_picture']?.toString() ?? json['image']?.toString(),
      department: json['department']?.toString() ?? '',
      isFavorite: favoriteValue,
    );
  }
}
