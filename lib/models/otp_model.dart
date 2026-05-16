class OtpResponseModel {
  final String status;
  final String message;

  OtpResponseModel({required this.status, required this.message});

  factory OtpResponseModel.fromJson(Map<String, dynamic> json) {
    return OtpResponseModel(
      status: json['status'] ?? '',
      message: json['message'] ?? '',
    );
  }
}