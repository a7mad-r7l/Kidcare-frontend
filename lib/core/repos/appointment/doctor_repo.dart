import 'dart:convert';
import '../../apis/appointment/doctor_api.dart';
import '../../helper/secure_storage_service.dart';
import '../../../models/appointment/doctor_model.dart';
import '../../../models/appointment/doctor_availability_model.dart';

class DoctorRepo {
  final DoctorApi _api;

  DoctorRepo({DoctorApi? api}) : _api = api ?? DoctorApi();

  Future<List<DoctorModel>> fetchByDepartment(int departmentId) async {
    final token = await SecureStorage.getToken();
    final response = await _api.getByDepartment(token, departmentId);
    final decoded = jsonDecode(response);

    // 🌟 تحصين دفاعي: استخراج المصفوفة بأمان سواء أتت خام أو مغلفة بداخل مفتاح بسبب اللغات
    List<dynamic> listToMap = [];
    if (decoded is List) {
      listToMap = decoded;
    } else if (decoded is Map) {
      if (decoded['doctors'] is List) {
        listToMap = decoded['doctors'];
      } else if (decoded['data'] is List) {
        listToMap = decoded['data'];
      }
    }

    if (listToMap.isNotEmpty || (decoded is Map && decoded['status'] == 'success')) {
      return listToMap
          .map((j) => DoctorModel.fromJson(j as Map<String, dynamic>))
          .toList();
    }

    final msg = (decoded is Map && decoded['message'] != null)
        ? decoded['message'].toString()
        : 'Failed to load doctors';
    throw Exception(msg);
  }

  Future<DoctorModel> fetchById(int doctorId) async {
    final token = await SecureStorage.getToken();
    final response = await _api.getById(token, doctorId);
    final decoded = jsonDecode(response);

    if (decoded is Map<String, dynamic>) {
      final raw = decoded['data'] is Map<String, dynamic>
          ? decoded['data'] as Map<String, dynamic>
          : decoded;
      return DoctorModel.fromJson(raw);
    }

    final msg = (decoded is Map && decoded['message'] != null)
        ? decoded['message'].toString()
        : 'Failed to load doctor';
    throw Exception(msg);
  }

  Future<List<DoctorAvailabilityModel>> fetchWeeklyAvailability(int doctorId) async {
    final token = await SecureStorage.getToken();
    final response = await _api.getAvailabilities(token, doctorId);
    final decoded = jsonDecode(response);

    List<dynamic> listToMap = [];
    if (decoded is List) {
      listToMap = decoded;
    } else if (decoded is Map) {
      if (decoded['availabilities'] is List) {
        listToMap = decoded['availabilities'];
      } else if (decoded['data'] is List) {
        listToMap = decoded['data'];
      }
    }

    return listToMap
        .map((j) => DoctorAvailabilityModel.fromJson(j as Map<String, dynamic>))
        .toList();
  }

  Future<List<String>> fetchSlots(int doctorId, String date) async {
    final token = await SecureStorage.getToken();
    final response = await _api.getAvailableTimes(token, doctorId, date);
    final decoded = jsonDecode(response);

    if (decoded is Map && decoded['times'] is List) {
      return List<String>.from(
        (decoded['times'] as List).map((e) => e.toString()),
      );
    }
    if (decoded is Map && decoded['data'] is Map && decoded['data']['times'] is List) {
      return List<String>.from(
        (decoded['data']['times'] as List).map((e) => e.toString()),
      );
    }
    return [];
  }
}