class AppointmentsModel {
  final int id;
  final String doctorName;
  final String specialty;
  final String date;
  final String time;
  final String status;
  final String? doctorImage;

  const AppointmentsModel({
    required this.id,
    required this.doctorName,
    required this.specialty,
    required this.date,
    required this.time,
    required this.status,
    this.doctorImage,
  });

  factory AppointmentsModel.fromJson(Map<String, dynamic> json) {
    return AppointmentsModel(
      id: json['id'] ?? 0,
      doctorName: json['doctor_name'] ?? '',
      specialty: json['specialty'] ?? '',
      date: json['date'] ?? '',
      time: json['time'] ?? '',
      status: json['status'] ?? '',
      doctorImage: json['doctor_image'],
    );
  }
}