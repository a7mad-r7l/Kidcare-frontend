// lib/models/home_child_model.dart
class HomeChildModel {
  final int id;
  final String name;
  final int age;
  final String ageType;
  final String? image;

  const HomeChildModel({
    required this.id,
    required this.name,
    required this.age,
    this.image, required this.ageType,
  });

  factory HomeChildModel.fromJson(Map<String, dynamic> json) {
    return HomeChildModel(
      id: json['id'],
      name: json['name'] ?? '',
      age: json['age'] ?? 0,
      ageType: json['age_type']?.toString() ?? 'year',
      image: json['image'],
    );
  }
}
