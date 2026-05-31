import 'dart:convert';
import '../../apis/appointment/appointment_api.dart';
import '../../helper/secure_storage_service.dart';
import '../../../models/appointment/appointment_model.dart';

class AppointmentRepo {
  final AppointmentApi _api;

  AppointmentRepo({AppointmentApi? api}) : _api = api ?? AppointmentApi();

  Future<AppointmentModel> book({
    required int doctorId,
    required int childId,
    required String date,
    required String time,
  }) async {
    final token = await SecureStorage.getToken();
    final response = await _api.create(token, {
      'doctor_id': doctorId,
      'child_id': childId,
      'date': date,
      'time': time,
    });
    print('🚨 BACKEND RESPONSE: $response');
    final decoded = jsonDecode(response);

    if (decoded is Map) {
      // جعلنا الكود ذكياً ومرناً: يبحث عن البيانات سواء كان اسمها appointment أو data أو أُرسلت مباشرة
      final raw = decoded['appointment'] ?? decoded['data'] ?? decoded;

      // إذا وجد البيانات وفيها ID الموعد، يكمل بنجاح
      if (raw is Map<String, dynamic> && raw['id'] != null) {
        return AppointmentModel.fromJson(raw);
      }
    }

    // if (decoded is Map && decoded['appointment'] is Map<String, dynamic>) {
    //   return AppointmentModel.fromJson(
    //     decoded['appointment'] as Map<String, dynamic>,
    //   );
    // }

    throw Exception(_errorMessage(decoded, 'Failed to book appointment'));
  }

  Future<List<AppointmentModel>> listAll() => _fetchList(_api.listAll);
  Future<List<AppointmentModel>> listUpcoming() =>
      _fetchList(_api.listUpcoming);
  Future<List<AppointmentModel>> listPast() => _fetchList(_api.listPast);

  Future<List<AppointmentModel>> listUpcomingForChild(int childId) async {
    final token = await SecureStorage.getToken();
    return _parseList(
      await _api.listUpcomingForChild(token, childId),
      'Failed to load upcoming appointments',
    );
  }

  Future<List<AppointmentModel>> listPastForChild(int childId) async {
    final token = await SecureStorage.getToken();
    return _parseList(
      await _api.listPastForChild(token, childId),
      'Failed to load past appointments',
    );
  }

  Future<AppointmentModel> fetchOne(int id) async {
    final token = await SecureStorage.getToken();
    final response = await _api.getById(token, id);
    final decoded = jsonDecode(response);

    if (decoded is Map<String, dynamic>) {
      final raw = decoded['appointment'] is Map<String, dynamic>
          ? decoded['appointment'] as Map<String, dynamic>
          : (decoded['data'] is Map<String, dynamic>
                ? decoded['data'] as Map<String, dynamic>
                : decoded);
      if (raw['id'] != null) return AppointmentModel.fromJson(raw);
    }

    throw Exception(_errorMessage(decoded, 'Failed to load appointment'));
  }

  Future<AppointmentModel> reschedule(
    int id, {
    String? date,
    String? time,
  }) async {
    final token = await SecureStorage.getToken();
    final body = <String, dynamic>{};
    if (date != null) body['date'] = date;
    if (time != null) body['time'] = time;

    final response = await _api.update(token, id, body);
    final decoded = jsonDecode(response);

    if (decoded is Map && decoded['appointment'] is Map<String, dynamic>) {
      return AppointmentModel.fromJson(
        decoded['appointment'] as Map<String, dynamic>,
      );
    }

    throw Exception(_errorMessage(decoded, 'Failed to reschedule appointment'));
  }

  Future<void> cancel(int id) async {
    final token = await SecureStorage.getToken();
    final response = await _api.delete(token, id);
    if (response.isEmpty) return;

    final decoded = jsonDecode(response);
    if (decoded is Map && decoded['errors'] != null) {
      throw Exception(_errorMessage(decoded, 'Failed to cancel appointment'));
    }
  }

  // ---- helpers ----

  Future<List<AppointmentModel>> _fetchList(
    Future<String> Function(String token) call,
  ) async {
    final token = await SecureStorage.getToken();
    return _parseList(await call(token), 'Failed to load appointments');
  }

  List<AppointmentModel> _parseList(String response, String fallbackMsg) {
    final decoded = jsonDecode(response);

    List? items;
    if (decoded is List) {
      items = decoded;
    } else if (decoded is Map) {
      if (decoded['appointments'] is List) {
        items = decoded['appointments'] as List;
      } else if (decoded['data'] is List) {
        items = decoded['data'] as List;
      }
    }

    if (items != null) {
      return items
          .map((j) => AppointmentModel.fromJson(j as Map<String, dynamic>))
          .toList();
    }

    throw Exception(_errorMessage(decoded, fallbackMsg));
  }

  String _errorMessage(dynamic decoded, String fallback) {
    if (decoded is Map && decoded['message'] != null) {
      return decoded['message'].toString();
    }
    return fallback;
  }
}
