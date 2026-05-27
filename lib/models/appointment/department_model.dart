import '../../core/helper/json_utils.dart';

class DepartmentModel {
  final int id;
  final String name;
  final String? description;

  const DepartmentModel({
    required this.id,
    required this.name,
    this.description,
  });

  factory DepartmentModel.fromJson(Map<String, dynamic> json) {
    return DepartmentModel(
      id: toIntSafe(json['id']),
      name: json['name']?.toString() ?? '',
      description: json['description']?.toString(),
    );
  }
}
