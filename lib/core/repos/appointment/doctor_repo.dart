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

    if (decoded is List) {
      return decoded
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
      if (raw['id'] != null) return DoctorModel.fromJson(raw);
    }

    final msg = (decoded is Map && decoded['message'] != null)
        ? decoded['message'].toString()
        : 'Failed to load doctor';
    throw Exception(msg);
  }

  Future<List<DoctorAvailabilityModel>> fetchWeeklyAvailability(
    int doctorId,
  ) async {
    final token = await SecureStorage.getToken();
    final response = await _api.getAvailabilities(token, doctorId);
    final decoded = jsonDecode(response);

    if (decoded is List) {
      return decoded
          .map(
            (j) =>
                DoctorAvailabilityModel.fromJson(j as Map<String, dynamic>),
          )
          .toList();
    }

    final msg = (decoded is Map && decoded['message'] != null)
        ? decoded['message'].toString()
        : 'Failed to load availability';
    throw Exception(msg);
  }

  /// Returns the list of available time slots for a doctor on a given date.
  /// An empty list is a valid result (backend returns `times: []`) — not an error.
  Future<List<String>> fetchSlots(int doctorId, String date) async {
    final token = await SecureStorage.getToken();
    final response = await _api.getAvailableTimes(token, doctorId, date);
    final decoded = jsonDecode(response);

    if (decoded is Map && decoded['times'] is List) {
      return List<String>.from(
        (decoded['times'] as List).map((e) => e.toString()),
      );
    }

    final msg = (decoded is Map && decoded['message'] != null)
        ? decoded['message'].toString()
        : 'Failed to load available times';
    throw Exception(msg);
  }
}
