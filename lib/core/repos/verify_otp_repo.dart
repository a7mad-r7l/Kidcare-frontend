import '../apis/verify_otp_api.dart';

class VerifyOtpRepo {
  final VerifyOtpApi _api = VerifyOtpApi();

  Future<Map<String, dynamic>> verify({
    required String phone,
    required String otp,
  }) async {
    return await _api.verify(phone: phone, otp: otp);
  }

  Future<Map<String, dynamic>> resend({required String phone}) async {
    return await _api.resend(phone: phone);
  }
}
