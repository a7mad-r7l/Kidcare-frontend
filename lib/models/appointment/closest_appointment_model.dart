class ClosestAppointmentModel {
  final int doctorId;
  final String doctorName;
  final String? profilePictureUrl;
  final String date;
  final String time;
  final String dayName;

  ClosestAppointmentModel({
    required this.doctorId,
    required this.doctorName,
    this.profilePictureUrl,
    required this.date,
    required this.time,
    required this.dayName,
  });

  factory ClosestAppointmentModel.fromJson(Map<String, dynamic> json) {
    final appointment = json['closest_appointment'] ?? {};
    return ClosestAppointmentModel(
      doctorId: json['doctor_id'] ?? 0,
      doctorName: json['doctor_name']?.toString() ?? '',
      profilePictureUrl: json['profile_picture_url']?.toString(),
      date: appointment['date']?.toString() ?? '',
      time: appointment['time']?.toString() ?? '',
      dayName: appointment['day_name']?.toString() ?? '',
    );
  }
}