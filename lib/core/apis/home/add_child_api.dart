import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../../constants.dart';
import '../../helper/secure_storage_service.dart';


class AddChildApi {

  Future<String> deleteChild(int childId) async {
    final token = await SecureStorage.getToken();
    if (token == null || token.isEmpty) {
      throw Exception('Session expired. Please login again.');
    }

    // ✅ استخدام http.delete مباشرة بدل client.delete
    final response = await http.delete(
      Uri.parse('$baseUrl/children/$childId'),
      headers: {
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    debugPrint('── Delete Status: ${response.statusCode}');
    debugPrint('── Delete Body: ${response.body}');

    return response.body;
  }

  Future<String> addChild({
    required String firstName,
    required String lastName,
    required String gender,
    required String birthDate,
    required String bloodType,
    required String medicalHistory,
    required String allergies,
    File? image,
  }) async {
    final token = await SecureStorage.getToken();
    debugPrint('── Token: $token');

    if (token == null || token.isEmpty) {
      throw Exception('Session expired. Please login again.');
    }

    final request = http.MultipartRequest(
      'POST',
      Uri.parse('$baseUrl/children?token=$token'),
    );

    request.headers.addAll({
      'Authorization': 'Bearer $token',
      'Accept': 'application/json',
    });

    request.fields['first_name'] = firstName;
    request.fields['last_name'] = lastName;
    request.fields['gender'] = gender;
    request.fields['birth_date'] = birthDate;
    request.fields['blood_type'] = bloodType;
    request.fields['medical_history'] = medicalHistory;
    request.fields['allergies'] = allergies;

    if (image != null) {
      request.files.add(
        await http.MultipartFile.fromPath('image', image.path),
      );
    }

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    debugPrint('── Status: ${response.statusCode}');
    debugPrint('── Body: ${response.body}');

    return response.body;
  }
}
