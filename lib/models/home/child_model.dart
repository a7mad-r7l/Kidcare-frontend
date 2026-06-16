class ChildModel {
  final int id;
  final int parentId;
  final String name;
  final String gender;
  final String birthDate;
  final String? profilePicture;

  ChildModel({
    required this.id,
    required this.parentId,
    required this.name,
    required this.gender,
    required this.birthDate,
    this.profilePicture,
  });

  factory ChildModel.fromJson(Map<String, dynamic> json) {
    return ChildModel(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      parentId: json['parent_id'] is int ? json['parent_id'] : int.tryParse(json['parent_id']?.toString() ?? '0') ?? 0,
      name: json['name']?.toString() ?? '',
      // 🌟 حماية حقل الجنس المترجم من الباك إند لمنع الكراش الشهير
      gender: json['gender']?.toString() ?? '',
      birthDate: json['birth_date']?.toString() ?? json['birthDate']?.toString() ?? '',
      profilePicture: json['profile_picture']?.toString(),
    );
  }
}