class AppointmentDetailsModel {
  final String patientName;
  final String patientAge;
  final String ageType;
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
    required this.ageType,
  });

  factory AppointmentDetailsModel.fromJson(Map<String, dynamic> json) {

    String rawUrl = json['patient_image_url']?.toString() ?? '';
    if (rawUrl.contains('storage/http')) {
      rawUrl = rawUrl.split('storage/').last;
    }

    return AppointmentDetailsModel(
      patientName: json['patient_name']?.toString() ?? '',
      patientAge: json['patient_age']?.toString() ?? '',
      ageType: json['age_type']?.toString() ?? 'year',
      patientImageUrl: rawUrl,
      doctorName: json['doctor_name']?.toString() ?? '',
      departmentName: json['department_name']?.toString() ?? '',
      dateTime: json['date_time']?.toString() ?? '',
      price: json['price']?.toString() ?? '0',
      currency: json['currency']?.toString() ?? '',
    );
  }
}