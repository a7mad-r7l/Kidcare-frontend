class ForgotPasswordResponse {
  final String status;
  final String message;
  final int? otp;


  ForgotPasswordResponse({required this.status, required this.message, this.otp});

  factory ForgotPasswordResponse.fromJson(Map<String, dynamic> json) {
    return ForgotPasswordResponse(
      status: json['status'] ?? '',
      message: json['message'] ?? '',
      otp: json['otp'],
    );
  }
}