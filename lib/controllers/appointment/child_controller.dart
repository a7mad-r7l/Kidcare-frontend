import 'dart:convert';

import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import '../../core/constants.dart';
import '../../core/helper/secure_storage_service.dart';
import '../../core/repos/appointment/child_repo.dart';
import '../../models/appointment/child_model.dart';
import '../base_controller.dart';

class ChildController extends BaseController {
  final ChildRepo repo;

  ChildController({required this.repo});

  final children = <ChildModel>[].obs;

  @override
  void onInit() {
    super.onInit();
    loadChildren();
  }
  // دالة مخصصة لضرب مسار الـ POST الخاص بالحجز السريع
  Future<String> bookQuickAppointmentApi(int doctorId, int childId, String date, String time) async {
    final token = await SecureStorage.getToken();
    final response = await http.post(
      Uri.parse('$baseUrl/appointment'), // مسار الـ POST الذي جربته في Postman
      headers: {
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: {
        'doctor_id': doctorId.toString(),
        'child_id': childId.toString(),
        'date': date,
        'time': time,
      },
    );

    final data = jsonDecode(response.body);

    // 201 Created تعني نجاح الحجز كما ظهر معك في Postman
    if (response.statusCode == 201 && data['status'] == 'success') {
      return data['appointment_id']; // إرجاع الـ UUID الخاص بالموعد
    } else {
      throw Exception(data['message'] ?? 'Failed to book appointment');
    }
  }

  Future<void> loadChildren() async {
    showLoading();
    try {
      children.value = await repo.fetchMyChildren();
    } catch (e) {
      handleError(e);
    } finally {
      hideLoading();
    }
  }
}
