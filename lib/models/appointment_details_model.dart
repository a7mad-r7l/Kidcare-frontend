class AppointmentDetailsModel {
  final String patientName;
  final String patientAge;
  final String patientImageUrl;
  final String doctorName;
  final String departmentName;
  final String dateTime;
  final String price;
  final String currency;

  AppointmentDetailsModel({
    required this.patientName,
    required this.patientAge,
    required this.patientImageUrl,
    required this.doctorName,
    required this.departmentName,
    required this.dateTime,
    required this.price,
    required this.currency,
  });

  factory AppointmentDetailsModel.fromJson(Map<String, dynamic> json) {
    return AppointmentDetailsModel(
      patientName: json['patient_name'] ?? '',
      patientAge: json['patient_age'] ?? '',
      patientImageUrl: json['patient_image_url'] ?? '',
      doctorName: json['doctor_name'] ?? '',
      departmentName: json['department_name'] ?? '',
      dateTime: json['date_time'] ?? '',
      price: json['price'] ?? '0',
      currency: json['currency'] ?? '',
    );
  }
}
