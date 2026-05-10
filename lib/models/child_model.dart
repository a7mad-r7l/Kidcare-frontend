// lib/core/models/child_model.dart
class ChildModel {
  final String name;
  final String age;
  final String gender; // 'male' or 'female'
  final bool isSelected;

  const ChildModel({
    required this.name,
    required this.age,
    required this.gender,
    this.isSelected = false,
  });
}