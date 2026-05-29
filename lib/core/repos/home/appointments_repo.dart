import 'dart:convert';


import '../../../models/home/appointments_model.dart';
import '../../apis/home/appointments_api.dart';



class AppointmentsRepo {
  final AppointmentsApi _api = AppointmentsApi();

  Future<List<AppointmentsModel>> getUpcoming(int childId) async {
    final response = await _api.getUpcoming(childId);
    final body = json.decode(response);

    if (body['appointments'] == null) {
      throw Exception(body['message'] ?? 'Failed to load appointments');
    }

    final List list = body['appointments'];
    return list.map((e) => AppointmentsModel.fromJson(e)).toList();
  }

  Future<List<AppointmentsModel>> getPast(int childId) async {
    final response = await _api.getPast(childId);
    final body = json.decode(response);

    if (body['appointments'] == null) {
      throw Exception(body['message'] ?? 'Failed to load appointments');
    }

    final List list = body['appointments'];
    return list.map((e) => AppointmentsModel.fromJson(e)).toList();
  }
}
