import 'dart:convert';
import '../../../models/vaccines/vaccine_schedule_model.dart';
import '../../../models/vaccines/vaccine_history_model.dart';
import '../../apis/vaccines/vaccines_api.dart';

class VaccinesRepo {
  final VaccinesApi _api = VaccinesApi();

  // القاعدة الصارمة 1: معالجة الـ JSON المعطوب من السيرفر
  String _cleanJson(String response) {
    final startIndex = response.indexOf(RegExp(r'[\{\[]'));
    if (startIndex != -1) return response.substring(startIndex);
    return response;
  }

  Future<List<VaccineScheduleModel>> fetchAvailableSchedules(int childId) async {
    final res = await _api.getAvailableSchedules(childId);
    final decoded = jsonDecode(_cleanJson(res.body));

    if (res.statusCode == 200 && decoded['status'] == 'success') {
      final List list = decoded['schedules'] ?? [];
      return list.map((e) => VaccineScheduleModel.fromJson(e)).toList();
    }
    throw Exception(decoded['message'] ?? 'Failed to load schedules');
  }

  Future<List<VaccineHistoryModel>> fetchChildHistory(int childId) async {
    final res = await _api.getChildHistory(childId);
    final decoded = jsonDecode(_cleanJson(res.body));

    if (res.statusCode == 200 && decoded['status'] == 'success') {
      final List list = decoded['records'] ?? [];
      return list.map((e) => VaccineHistoryModel.fromJson(e)).toList();
    }
    throw Exception(decoded['message'] ?? 'Failed to load history');
  }
}