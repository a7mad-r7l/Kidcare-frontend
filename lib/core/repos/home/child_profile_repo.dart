import 'dart:convert';
import '../../../models/appointment/child_model.dart';
import '../../apis/home/child_profile_api.dart';

class ChildProfileRepo {
  final ChildProfileApi _api = ChildProfileApi();

  // 1. الدالة المسؤولة عن جلب بيانات الطفل
  Future<ChildModel> getChildDetails(int childId) async {
    String response = await _api.getChildDetails(childId);

    if (response.contains('{')) {
      response = response.substring(response.indexOf('{'));
    }

    final body = json.decode(response);

    if (body is Map<String, dynamic> && body['id'] != null) {
      return ChildModel.fromJson(body);
    }

    throw Exception(body['message'] ?? 'Failed to load child details');
  }

  // 2. الدالة المسؤولة عن حذف الطفل (التي أضفناها للتو)
  Future<void> deleteChild(int childId) async {
    final response = await _api.deleteChild(childId);
    final body = json.decode(response);

    // التحقق من النجاح بناءً على استجابة السيرفر
    if (body['message'] != null &&
        (body['message'].toString().toLowerCase().contains('success') ||
            body['message'].toString().toLowerCase().contains('deleted'))) {
      return;
    }
    throw Exception(body['message'] ?? 'Failed to delete child');
  }
}