// lib/core/models/appointment_model.dart
class AppointmentModel {
  final String doctorName;
  final String specialty;
  final String date;
  final String status;

  const AppointmentModel({
    required this.doctorName,
    required this.specialty,
    required this.date,
    required this.status,
  });
}