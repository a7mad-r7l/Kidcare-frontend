import '../../core/helper/json_utils.dart';

class AppointmentModel {
  final String id;
  final int childId;
  final int doctorId;
  final String date;
  final String time;
  final String status;
  final num price;
  final String? doctorName;
  final String? childName;

  const AppointmentModel({
    required this.id,
    required this.childId,
    required this.doctorId,
    required this.date,
    required this.time,
    required this.status,
    required this.price,
    this.doctorName,
    this.childName,
  });

  factory AppointmentModel.fromJson(Map<String, dynamic> json) {
    return AppointmentModel(
      id:  json['id']?.toString() ?? '',
      childId: toIntSafe(json['child_id']),
      doctorId: toIntSafe(json['doctor_id']),
      date: json['date']?.toString() ?? '',
      time: json['time']?.toString() ?? '',
      status: json['status']?.toString() ?? '',
      price: toNumSafe(json['price']),
    );
  }

  AppointmentModel withNames({String? doctorName, String? childName}) {
    return AppointmentModel(
      id: id,
      childId: childId,
      doctorId: doctorId,
      date: date,
      time: time,
      status: status,
      price: price,
      doctorName: doctorName ?? this.doctorName,
      childName: childName ?? this.childName,
    );
  }

  DateTime? get dateAsDate => DateTime.tryParse(date);
}
