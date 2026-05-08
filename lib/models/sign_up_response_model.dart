class SignUpResponseModel {
  final String message;
  final String phoneNumber;
  final String nextStep;
  final String accessToken;

  SignUpResponseModel({
    required this.message,
    required this.phoneNumber,
    required this.nextStep,
    required this.accessToken,
  });

  factory SignUpResponseModel.fromJson(Map<String, dynamic> json) {
    return SignUpResponseModel(
      message: json['message'] ?? '',
      phoneNumber: json['phone_number'] ?? '',
      nextStep: json['next_step'] ?? '',
      accessToken: json['access_token'] ?? '',
    );
  }
}
