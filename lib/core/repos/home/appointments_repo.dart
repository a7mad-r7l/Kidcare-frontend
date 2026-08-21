import 'dart:convert';
import 'package:http/http.dart' as http;

import '../../../models/home/appointments_model.dart';
import '../../apis/home/appointments_api.dart';
import '../../constants.dart';
import '../../helper/secure_storage_service.dart';

class AppointmentsRepo {
  final AppointmentsApi _api = AppointmentsApi();

  // دالة مساعدة لتنظيف الرد القادم من الباك إند وتجنب أخطاء الـ HTML/PHP
  List<AppointmentsModel> _parseResponse(String response) {
    final int startIndex = response.indexOf(RegExp(r'[\{\[]'));
    if (startIndex != -1) {
      response = response.substring(startIndex);
    }

    final body = json.decode(response);

    if (body['appointments'] == null) {
      throw Exception(body['message'] ?? 'Failed to load appointments');
    }

    final List list = body['appointments'];
    return list.map((e) => AppointmentsModel.fromJson(e)).toList();
  }


  Future<List<AppointmentsModel>> getAllUpcoming() async {
    final response = await _api.getAllUpcoming();
    return _parseResponse(response);
  }
  Future<Map<String, dynamic>> cancelAppointment(int appointmentId) async {
    final token = await SecureStorage.getToken();

    final response = await http.delete(
      Uri.parse('$baseUrl/appointments/$appointmentId'),
      headers: {
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
        'ngrok-skip-browser-warning': 'true', // 👈 هذا هو السطر المنقذ!
      },
    );

    // ─── طباعة النتيجة في الكونسول للمراقبة ───
    print('🚨 Delete Status: ${response.statusCode}');
    print('🚨 Delete Body: ${response.body}');

    // التحقق من نجاح العملية قبل محاولة فك التشفير
    if (response.statusCode == 200 || response.statusCode == 201) {
      final data = json.decode(response.body);
      return data; // إرجاع الريسبونس (الذي يحتوي على رسالة النجاح وقيمة الاسترداد)
    } else {
      // محاولة استخراج رسالة الخطأ من السيرفر بشكل آمن
      try {
        final data = json.decode(response.body);
        throw Exception(data['message'] ?? 'Failed to cancel appointment');
      } catch (e) {
        throw Exception('Server error: ${response.statusCode}');
      }
    }
  }

  Future<List<AppointmentsModel>> getAllPast() async {
    final response = await _api.getAllPast();
    return _parseResponse(response);
  }

  Future<List<AppointmentsModel>> getUpcomingForChild(int childId) async {
    final response = await _api.getUpcomingForChild(childId);
    return _parseResponse(response);
  }

  Future<List<AppointmentsModel>> getPastForChild(int childId) async {
    final response = await _api.getPastForChild(childId);
    return _parseResponse(response);
  }
  Future<List<AppointmentsModel>> getAllCancelled() async {
    final response = await _api.getAllCancelled();
    return _parseResponse(response);
  }
}