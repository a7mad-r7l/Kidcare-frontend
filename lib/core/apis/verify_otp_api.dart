import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../constants.dart';

class VerifyOtpApi {
  final http.Client client = http.Client();

  // مهمة الدالة فقط إرسال البيانات وإرجاع الرد كـ String
  Future<String> verify({
    required String phone,
    required String otp,
  }) async {
    debugPrint('── VerifyOtpApi.verify ─────────────────');
    debugPrint('phone=$phone | otp=$otp');

    final response = await client.post(
      Uri.parse('$baseUrl/verifyOtp'),
      headers: {'Accept': 'application/json'},
      body: {'phone_number': phone, 'otp': otp},
    );

    debugPrint('Status: ${response.statusCode} | Body: ${response.body}');
    return response.body;
  }

  Future<String> resend({required String phone}) async {
    debugPrint('── VerifyOtpApi.resend ─────────────────');

    final response = await client.post(
      Uri.parse('$baseUrl/sendOtp'),
      headers: {'Accept': 'application/json'},
      body: {'phone_number': phone},
    );

    debugPrint('Status: ${response.statusCode} | Body: ${response.body}');
    return response.body;
  }
}