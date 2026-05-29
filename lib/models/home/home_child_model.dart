// lib/models/home_child_model.dart
class HomeChildModel {
  final int id;
  final String name;
  final int age;
  final String? image;

  const HomeChildModel({
    required this.id,
    required this.name,
    required this.age,
    this.image,
  });

  factory HomeChildModel.fromJson(Map<String, dynamic> json) {
    return HomeChildModel(
      id: json['id'],
      name: json['name'] ?? '',
      age: json['age'] ?? 0,
      image: json['image'],
    );
  }
}
