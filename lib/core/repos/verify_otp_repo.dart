import 'dart:convert';
import '../apis/verify_otp_api.dart';

class VerifyOtpRepo {
  final VerifyOtpApi _api = VerifyOtpApi();

  Future<void> verify({
    required String phone,
    required String otp,
  }) async {
    final response = await _api.verify(phone: phone, otp: otp);
    final body = json.decode(response);

    if (body['status'] == 'success') return;

    throw Exception(body['message'] ?? 'Error verifying OTP');
  }

  Future<void> resend({required String phone}) async {
    final response = await _api.resend(phone: phone);
    final body = json.decode(response);

    if (body['status'] == 'success') return;

    throw Exception(body['message'] ?? 'Error resending OTP');
  }
}