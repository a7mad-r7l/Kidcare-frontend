import 'package:http/http.dart' as http;
import '../../constants.dart';
import '../../helper/secure_storage_service.dart';
import 'package:get/get.dart';
import 'dart:io';

class ChildProfileApi {
  final http.Client client = http.Client();

  // 1. الدالة المسؤولة عن جلب التفاصيل من السيرفر
  Future<String> getChildDetails(int childId) async {
    final token = await SecureStorage.getToken();
    if (token.isEmpty) {
      throw Exception('Session expired. Please login again.');
    }

    final response = await client.get(
      Uri.parse('$baseUrl/children/$childId'),
      headers: {
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
        'Accept-Language': Get.locale?.languageCode ?? 'en',
      },
    );

    return response.body;
  }

  // 2. الدالة المسؤولة عن إرسال طلب الحذف (DELETE)
  Future<String> deleteChild(int childId) async {
    final token = await SecureStorage.getToken();
    if (token.isEmpty) {
      throw Exception('Session expired. Please login again.');
    }

    final response = await client.delete(
      Uri.parse('$baseUrl/children/$childId'),
      headers: {
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
        'Accept-Language': Get.locale?.languageCode ?? 'en',
      },
    );

    // التحقق من حالة الطلب
    if (response.statusCode == 200) {
      return response.body;
    } else {
      throw Exception('Failed to delete child: ${response.statusCode}');
    }
  }
  Future<String> updateChild({
    required int childId,
    Map<String, String>? fields,
    File? image,
  }) async {
    final token = await SecureStorage.getToken();
    if (token.isEmpty) {
      throw Exception('Session expired. Please login again.');
    }

    // يجب استخدام POST مع إرسال _method = PUT في Laravel عند رفع الملفات
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('$baseUrl/children/$childId'),
    );

    request.headers.addAll({
      'Authorization': 'Bearer $token',
      'Accept': 'application/json',
      'Accept-Language': Get.locale?.languageCode ?? 'en',
    });

    // خدعة Laravel لاستقبال PUT عبر form-data
    request.fields['_method'] = 'PUT';

    // إضافة الحقول النصية إن وجدت
    if (fields != null) {
      request.fields.addAll(fields);
    }

    // إضافة الصورة إن وجدت
    if (image != null) {
      request.files.add(
        await http.MultipartFile.fromPath('image', image.path),
      );
    }

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);
    return response.body;
  }
}