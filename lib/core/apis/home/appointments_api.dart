import 'package:http/http.dart' as http;
import '../../constants.dart';
import '../../helper/secure_storage_service.dart';
import 'package:get/get.dart';
import 'dart:convert'; // أضفنا هذا لفك تشفير الخطأ إذا حدث

class AppointmentsApi {
  final http.Client client = http.Client();

  // 1- Upcoming (لجميع مواعيد المستخدم)
  Future<String> getAllUpcoming() async {
    final token = await SecureStorage.getToken();
    if (token.isEmpty) throw Exception('Session expired. Please login again.');
    final response = await client.get(
      Uri.parse('$baseUrl/appointments/upcoming'),
      headers: {
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
        'ngrok-skip-browser-warning': 'true',
        'Accept-Language': Get.locale?.languageCode ?? 'en',
      },
    );
    return response.body;
  }

  // 2- Past (لجميع مواعيد المستخدم)
  Future<String> getAllPast() async {
    final token = await SecureStorage.getToken();
    if (token.isEmpty) throw Exception('Session expired. Please login again.');
    final response = await client.get(
      Uri.parse('$baseUrl/appointments/past'),
      headers: {
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
        'ngrok-skip-browser-warning': 'true',
        'Accept-Language': Get.locale?.languageCode ?? 'en',
      },
    );
    return response.body;
  }

  // 3- Upcoming by Child (لمواعيد طفل محدد)
  Future<String> getUpcomingForChild(int childId) async {
    final token = await SecureStorage.getToken();
    if (token.isEmpty) throw Exception('Session expired. Please login again.');
    final response = await client.get(
      Uri.parse('$baseUrl/appointments/upcoming/$childId'),
      headers: {
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
        'ngrok-skip-browser-warning': 'true',
        'Accept-Language': Get.locale?.languageCode ?? 'en',
      },
    );
    return response.body;
  }

  // 4- Past by Child (لمواعيد طفل محدد)
  Future<String> getPastForChild(int childId) async {
    final token = await SecureStorage.getToken();
    if (token.isEmpty) throw Exception('Session expired. Please login again.');
    final response = await client.get(
      Uri.parse('$baseUrl/appointments/past/$childId'),
      headers: {
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
        'ngrok-skip-browser-warning': 'true',
        'Accept-Language': Get.locale?.languageCode ?? 'en',
      },
    );
    return response.body;
  }

  // 5- Cancel Appointment (الدالة الجديدة لإلغاء الموعد)
  Future<String> cancelAppointment(int appointmentId) async {
    final token = await SecureStorage.getToken();
    if (token.isEmpty) throw Exception('Session expired. Please login again.');

    final response = await client.delete(
      Uri.parse('$baseUrl/appointments/$appointmentId'),
      headers: {
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
        'ngrok-skip-browser-warning': 'true',
        'Accept-Language': Get.locale?.languageCode ?? 'en',
      },
    );

    // طباعة النتيجة في الكونسول لمعرفة الخطأ الحقيقي إن وُجد
    print('🚨 Cancel Status: ${response.statusCode}');
    print('🚨 Cancel Body: ${response.body}');

    // التحقق من نجاح العملية (200 OK)
    if (response.statusCode == 200 || response.statusCode == 201) {
      return response.body;
    } else {
      // محاولة استخراج رسالة الخطأ من السيرفر وعرضها للمستخدم
      try {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['message'] ?? 'Failed to cancel appointment');
      } catch (e) {
        throw Exception('Server error: ${response.statusCode}');
      }
    }
  }
}