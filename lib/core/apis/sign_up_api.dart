import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../constants.dart';

class SignUpApi {
  Future<Map<String, dynamic>> register({
    required String firstName,
    required String lastName,
    required String email,
    required String phone,
    required String address,
    required String password,
  }) async {
    debugPrint('── SignUpApi.register ──────────────────');
    debugPrint('URL   : $baseUrl/register');
    debugPrint('Body  : firstName=$firstName | email=$email | phone=$phone');

    final response = await http.post(
      Uri.parse('$baseUrl/register'),
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'first_name': firstName,
        'last_name': lastName,
        'email': email,
        'phone_number': phone,
        'address': address,
        'password': password,
      }),
    );

    debugPrint('Status: ${response.statusCode}');
    debugPrint('Raw   : ${response.body}');

    Map<String, dynamic> body;
    try {
      body = jsonDecode(response.body) as Map<String, dynamic>;
    } catch (e) {
      debugPrint('JSON parse failed: $e');
      throw Exception('Unexpected server response (${response.statusCode})');
    }

    if (response.statusCode == 200 || response.statusCode == 201) {
      return body;
    }

    throw Exception(body['message'] ?? 'Error ${response.statusCode}');
  }
}
