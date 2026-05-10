import 'dart:convert';
import '../apis/activation_api.dart';
import '../helper/secure_storage_service.dart';

class ActivationRepo {
  final ActivationApi api = ActivationApi();

  Future<bool> requestOtp(String phone) async {
    var response = await api.sendOtp(phone);
    var body = json.decode(response);

    if (body['status'] == 'success') return true;

    throw Exception(body['message'] ?? "Error sending OTP");
  }

  Future<bool> activateAndLogin(
    String phone,
    String otp,
    String password,
  ) async {
    var response = await api.verifyOtpAndSetPassword(phone, otp, password);
    var body = json.decode(response);

    if (body['status'] == 'success') {
      String token = body['token'];
      await SecureStorage.storeToken(token);
      return true;
    }

    throw Exception(body['message'] ?? "Activation failed");
  }
}
