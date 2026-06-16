import 'dart:convert';
import '../../../models/appointment/child_model.dart';
import '../../apis/home/child_profile_api.dart';

class ChildProfileRepo {
  final ChildProfileApi _api = ChildProfileApi();

  Future<ChildModel> getChildDetails(int childId) async {
    String response = await _api.getChildDetails(childId);

    if (response.contains('{')) {
      response = response.substring(response.indexOf('{'));
    }

    final body = json.decode(response);

    // 🌟 تحصين دفاعي: فحص ما إذا كانت البيانات قادمة مغلفة بداخل كائن 'data' بسبب مخرجات السيرفر الجديدة
    if (body is Map<String, dynamic>) {
      final rawChild = body['data'] is Map<String, dynamic>
          ? body['data'] as Map<String, dynamic>
          : body;

      if (rawChild['id'] != null) {
        return ChildModel.fromJson(rawChild);
      }
    }

    throw Exception(body['message'] ?? 'Failed to load child details');
  }

  Future<void> deleteChild(int childId) async {
    final response = await _api.deleteChild(childId);
    final body = json.decode(response);

    if (body['message'] != null &&
        (body['message'].toString().toLowerCase().contains('success') ||
            body['message'].toString().toLowerCase().contains('deleted'))) {
      return;
    }
    throw Exception(body['message'] ?? 'Failed to delete child');
  }
}