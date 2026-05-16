import 'dart:convert';
import 'package:http/http.dart' as http;
import '../constants.dart';

class OtpApi {
   final http.Client client = http.Client();
  Future<String> verifyOtp(String phone, String Otp) async {
   
    
    final response = await client.post(
     Uri.parse("$baseUrl/verify-otp"),
      headers: {
        "Accept": "application/json",
        
      },
      body: jsonEncode({
        "phone_number": phone,
        "otp": Otp,
      }),
    );

 
      return response.body;
    } 
  }
