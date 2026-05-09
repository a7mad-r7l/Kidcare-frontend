import 'package:http/http.dart' as http;
import '../constants.dart';

class ActivationApi {
  final http.Client client = http.Client();

  // 1. طلب إرسال رمز OTP
  Future<String> sendOtp(String phoneNumber) async {
    final response = await client.post(
      Uri.parse("$baseUrl/sendOtp"),
      body: {"phone_number": phoneNumber},
    );
    return response.body;
  }

  // 2. التحقق من الرمز
  Future<String> verifyOtp(String phoneNumber, String otp) async {
    final response = await client.post(
      Uri.parse("$baseUrl/verifyOtp"),
      body: {
        "phone_number": phoneNumber,
        "otp": otp
      },
    );
    return response.body;
  }

  // 3. تعيين كلمة المرور
  Future<String> setPassword(String phoneNumber, String password) async {
    final response = await client.post(
      Uri.parse("$baseUrl/SetPassword"),
      body: {
        "phone_number": phoneNumber,
        "password": password,
        "password_confirmation": password
      },
    );
    return response.body;
  }
}