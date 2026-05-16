import 'dart:convert';
import '../apis/forgot_password_api.dart';
import '../../models/forgot_password_response_model.dart';

class ForgotPasswordRepo {
  final ForgotPasswordApi _api = ForgotPasswordApi();

  Future<bool> sendCode(String phone) async {
    var response = await _api.sendCode(phone);
    var body = json.decode(response);

    if (body['status'] == 'success') return true;
    throw Exception(body['message'] ?? "Error sending OTP");

  }
}
