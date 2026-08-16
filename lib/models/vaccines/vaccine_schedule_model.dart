import '../../core/helper/json_utils.dart';

class VaccineScheduleModel {
  final int id;
  final String vaccineName;
  final int minAgeMonths;
  final int maxAgeMonths;
  final String date;
  final String startTime;
  final String endTime;
  final String? notes;

  VaccineScheduleModel({
    required this.id,
    required this.vaccineName,
    required this.minAgeMonths,
    required this.maxAgeMonths,
    required this.date,
    required this.startTime,
    required this.endTime,
    this.notes,
  });

  factory VaccineScheduleModel.fromJson(Map<String, dynamic> json) {
    return VaccineScheduleModel(
      id: toIntSafe(json['id']),
      vaccineName: json['vaccine_name']?.toString() ?? '',
      minAgeMonths: toIntSafe(json['min_age_months']),
      maxAgeMonths: toIntSafe(json['max_age_months']),
      date: json['date']?.toString() ?? '',
      // قص الثواني إن وجدت (12:00:00 -> 12:00)
      startTime: (json['start_time']?.toString() ?? '').split(':').take(2).join(':'),
      endTime: (json['end_time']?.toString() ?? '').split(':').take(2).join(':'),
      notes: json['notes']?.toString(),
    );
  }
}