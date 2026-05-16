import 'dart:convert';
import 'package:http/http.dart' as http;
import '../constants.dart';

class ResetPasswordApi {
  final http.Client client = http.Client();
  Future<String> resetPassword(String phoneNumber, String Password) async {
    
    final response = await client.post(
      Uri.parse("$baseUrl/reset-password"),
      
      headers: {"Accept": "application/json"},
      body: {
        "phone_number": phoneNumber,
        "password": Password,
        "Password_confirmation":Password
      },
    );

    return response.body;
  }
}