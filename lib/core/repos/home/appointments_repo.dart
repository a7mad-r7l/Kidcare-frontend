import 'dart:convert';
import '../../../models/home/appointments_model.dart';
import '../../apis/home/appointments_api.dart';

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
}