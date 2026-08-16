import 'package:http/http.dart' as http;
import 'package:get/get.dart';
import '../../constants.dart';
import '../../helper/secure_storage_service.dart';

class VaccinesApi {
  Future<Map<String, String>> _getHeaders() async {
    final token = await SecureStorage.getToken();
    return {
      'Accept': 'application/json',
      'Authorization': 'Bearer $token',
      'Accept-Language': Get.locale?.languageCode ?? 'en',
    };
  }

  Future<http.Response> getAvailableSchedules(int childId) async {
    return await http.get(
      Uri.parse('$baseUrl/vaccines/available-schedules?child_id=$childId'),
      headers: await _getHeaders(),
    ).timeout(const Duration(seconds: 15));
  }

  Future<http.Response> getChildHistory(int childId) async {
    return await http.get(
      Uri.parse('$baseUrl/vaccines/child-history/$childId'),
      headers: await _getHeaders(),
    ).timeout(const Duration(seconds: 15));
  }
}