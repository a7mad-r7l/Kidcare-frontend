class SignUpResponseModel {
  final String message;
  final String phoneNumber;
  final String nextStep;
  final String accessToken;
  final int otp;
  final String tokenType;

  SignUpResponseModel({
    required this.message,
    required this.phoneNumber,
    required this.nextStep,
    required this.accessToken,
    required this.otp,
    required this.tokenType,
  });

  factory SignUpResponseModel.fromJson(Map<String, dynamic> json) {
    return SignUpResponseModel(
      message: json['message'] ?? '',
      phoneNumber: json['phone_number'] ?? '',
      nextStep: json['next_step'] ?? '',
      accessToken: json['access_token'] ?? '',
      otp: json['otp'] ?? 0,
      tokenType: json['token_type'] ?? '',
    );
  }
}