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

  // 2. تعيين كلمة المرور مع التحقق من الـ OTP
  Future<String> verifyOtpAndSetPassword(String phoneNumber, String otp, String password) async {
    final response = await client.post(
      Uri.parse("$baseUrl/verifyOtpAndSetPassword"), // تعديل الـ Endpoint
      body: {
        "phone_number": phoneNumber,
        "otp": otp,
        "password": password,
        "password_confirmation": password
      },
    );
    return response.body;
  }
}