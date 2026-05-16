import 'package:http/http.dart' as http;
import 'package:kidcare/core/constants.dart';

class ForgotPasswordApi {
  
  Future<String> sendCode(String phoneNumber) async {
    final response = await http.post(
      Uri.parse("$baseUrl/sendOtp"),
      headers: {
        "Accept": "application/json",
      },
      body: {
        "phone_number": phoneNumber,
      },
    );


    if (response.statusCode == 200 || response.statusCode == 201) {
      return response.body;
    } else {
      
      throw Exception("Server Error: ${response.statusCode}");
    }
  }

  Future<Object?> sendOtp(String phone) async {}
}