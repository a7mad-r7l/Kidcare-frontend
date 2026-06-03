import 'package:http/http.dart' as http;
import '../../constants.dart';
import '../../helper/secure_storage_service.dart';
import 'package:get/get.dart';



class AppointmentsApi {
  final http.Client client = http.Client();

  Future<String> getUpcoming(int childId) async {
    final token = await SecureStorage.getToken();
    if (token.isEmpty) throw Exception('Session expired. Please login again.');

    final response = await client.get(
      Uri.parse('$baseUrl/appointments/upcoming/$childId'),
      headers: {
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
        'Accept-Language': Get.locale?.languageCode ?? 'en',
      },
    );
    return response.body;
  }

  Future<String> getPast(int childId) async {
    final token = await SecureStorage.getToken();
    if (token.isEmpty) throw Exception('Session expired. Please login again.');

    final response = await client.get(
      Uri.parse('$baseUrl/appointments/past/$childId'),
      headers: {
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
        'Accept-Language': Get.locale?.languageCode ?? 'en',
      },
    );
    return response.body;
  }
}
