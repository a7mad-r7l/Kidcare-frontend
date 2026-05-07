import 'dart:convert';
import 'package:http/http.dart' as http;
import '../constants.dart';

class SignUpApi {
  Future<String> register({
    required String firstName,
    required String lastName,
    required String email,
    required String phone,
    required String address,
    required String password,
  }) async {
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

    if (response.statusCode == 200 || response.statusCode == 201) {
      return response.body;
    } else {
      throw Exception('Error ${response.statusCode}: ${response.body}');
    }
  }
}
