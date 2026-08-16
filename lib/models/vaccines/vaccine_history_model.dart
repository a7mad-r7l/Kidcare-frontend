import '../../core/helper/json_utils.dart';

class VaccineHistoryModel {
  final int id;
  final String vaccineName;
  final String givenDate;
  final String? notes;

  VaccineHistoryModel({
    required this.id,
    required this.vaccineName,
    required this.givenDate,
    this.notes,
  });

  factory VaccineHistoryModel.fromJson(Map<String, dynamic> json) {
    return VaccineHistoryModel(
      id: toIntSafe(json['id']),
      vaccineName: json['vaccine_name']?.toString() ?? '',
      givenDate: json['given_date']?.toString() ?? '',
      notes: json['notes']?.toString(),
    );
  }
}