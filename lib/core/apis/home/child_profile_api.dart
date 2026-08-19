import 'package:http/http.dart' as http;
import '../../constants.dart';
import '../../helper/secure_storage_service.dart';
import 'package:get/get.dart';

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
}