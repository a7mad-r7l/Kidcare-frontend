import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../constants.dart';

class VerifyOtpApi {
  Future<Map<String, dynamic>> verify({
    required String phone,
    required String otp,
  }) async {
    debugPrint('── VerifyOtpApi.verify ─────────────────');
    debugPrint('phone=$phone | otp=$otp');

    final response = await http.post(
      Uri.parse('$baseUrl/verify-otp'),
      headers: {'Accept': 'application/json', 'Content-Type': 'application/json'},
      body: jsonEncode({'phone_number': phone, 'otp': otp}),
    );

    debugPrint('Status: ${response.statusCode} | Body: ${response.body}');

    final body = _decodeBody(response);

    if (response.statusCode == 200 || response.statusCode == 201) return body;
    throw Exception(body['message'] ?? 'Error ${response.statusCode}');
  }

  Future<Map<String, dynamic>> resend({required String phone}) async {
    debugPrint('── VerifyOtpApi.resend ─────────────────');

    final response = await http.post(
      Uri.parse('$baseUrl/resend-otp'),
      headers: {'Accept': 'application/json', 'Content-Type': 'application/json'},
      body: jsonEncode({'phone_number': phone}),
    );

    debugPrint('Status: ${response.statusCode} | Body: ${response.body}');

    final body = _decodeBody(response);

    if (response.statusCode == 200 || response.statusCode == 201) return body;
    throw Exception(body['message'] ?? 'Error ${response.statusCode}');
  }

  Map<String, dynamic> _decodeBody(http.Response response) {
    try {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } catch (_) {
      throw Exception('Unexpected server response (${response.statusCode})');
    }
  }
}
