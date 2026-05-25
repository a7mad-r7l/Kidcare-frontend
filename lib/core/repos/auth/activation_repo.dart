import 'dart:convert';
import '../../apis/auth/activation_api.dart';
import '../../helper/secure_storage_service.dart';


class ActivationRepo {
  final ActivationApi api = ActivationApi();

  Future<bool> requestOtp(String phone) async {
    var response = await api.sendOtp(phone);
    var body = json.decode(response);

    if (body['status'] == 'success') return true;
    throw Exception(body['message'] ?? "Error sending OTP");
  }

  Future<bool> verifyOtp(String phone, String otp) async {
    var response = await api.verifyOtp(phone, otp);
    var body = json.decode(response);

    if (body['status'] == 'success') return true;
    throw Exception(body['message'] ?? "Invalid OTP");
  }

  Future<bool> activateAndLogin(String phone, String password) async {
    var response = await api.setPassword(phone, password);
    var body = json.decode(response);

    if (body['status'] == 'success') {
      String token = body['token'];
      await SecureStorage.storeToken(token);
      return true;
    }
    throw Exception(body['message'] ?? "Activation failed");
  }
}