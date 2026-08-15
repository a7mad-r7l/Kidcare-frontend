import 'package:http/http.dart' as http;
import '../../constants.dart';
import 'package:get/get.dart';

class AppointmentApi {
  final http.Client client = http.Client();

  Future<String> create(String token, Map<String, dynamic> body) async {
    final response = await client.post(
      Uri.parse('$baseUrl/appointments'),
      headers: {
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
        'Accept-Language': Get.locale?.languageCode ?? 'en',
      },
      body: body.map((k, v) => MapEntry(k, v.toString())),
    );
    return response.body;
  }

  Future<String> listAll(String token) async {
    final response = await client.get(
      Uri.parse('$baseUrl/appointments'),
      headers: {
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
        'Accept-Language': Get.locale?.languageCode ?? 'en',
      },
    );
    return response.body;
  }

  Future<String> listUpcoming(String token) async {
    final response = await client.get(
      Uri.parse('$baseUrl/appointments/upcoming'),
      headers: {
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
        'Accept-Language': Get.locale?.languageCode ?? 'en',
      },
    );
    return response.body;
  }

  Future<String> listPast(String token) async {
    final response = await client.get(
      Uri.parse('$baseUrl/appointments/past'),
      headers: {
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
        'Accept-Language': Get.locale?.languageCode ?? 'en',
      },
    );
    return response.body;
  }

  Future<String> listUpcomingForChild(String token, int childId) async {
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

  Future<String> listPastForChild(String token, int childId) async {
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

  Future<String> getById(String token, String appointmentId) async {
    final response = await client.get(
      Uri.parse('$baseUrl/appointments/$appointmentId'),
      headers: {
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
        'Accept-Language': Get.locale?.languageCode ?? 'en',
      },
    );
    return response.body;
  }

  Future<String> update(
    String token,
      String appointmentId,
    Map<String, dynamic> body,
  ) async {
    final response = await client.put(
      Uri.parse('$baseUrl/appointment/$appointmentId'),
      headers: {
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
        'Accept-Language': Get.locale?.languageCode ?? 'en',
      },
      body: body.map((k, v) => MapEntry(k, v.toString())),
    );
    return response.body;
  }

  Future<String> delete(String token, String appointmentId) async {
    final response = await client.delete(
      Uri.parse('$baseUrl/appointment/$appointmentId'),
      headers: {
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
        'Accept-Language': Get.locale?.languageCode ?? 'en',
      },
    );
    // التحقق من نجاح الطلب
    if (response.statusCode == 200 || response.statusCode == 201) {
      return response.body;
    } else {
      throw Exception("Error ${response.statusCode}: ${response.body}");
  }}
}
