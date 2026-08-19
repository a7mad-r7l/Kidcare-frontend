import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:get/get.dart';
import '../../constants.dart';
import '../../helper/secure_storage_service.dart';

class ProfileApi {
  final http.Client client = http.Client();

  // ─── 1. دالة جلب البيانات ───
  Future<String> getProfile() async {
    final token = await SecureStorage.getToken();

    if (token == null || token.isEmpty) {
      throw Exception('Session expired. Please login again.');
    }

    final response = await client.get(
      Uri.parse('$baseUrl/parentProfile'),
      headers: {
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
        'Accept-Language': Get.locale?.languageCode ?? 'en',
      },
    );

    return response.body;
  }

  // ─── 2. دالة تحديث البيانات (تم إخراجها لتصبح دالة مستقلة) ───
  Future<String> updateParentProfile(Map<String, dynamic> updatedData) async {
    final token = await SecureStorage.getToken();

    if (token == null || token.isEmpty) {
      throw Exception('Session expired. Please login again.');
    }

    final response = await client.put(
      Uri.parse('$baseUrl/updateparentProfile'),
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json', // مهم جداً لإرسال الـ Body
        'Authorization': 'Bearer $token',
        'Accept-Language': Get.locale?.languageCode ?? 'en',
      },
      body: json.encode(updatedData),
    );

    if (response.statusCode == 200) {
      return response.body;
    } else {
      throw Exception('Failed to update profile: ${response.statusCode}');
    }
  }
}