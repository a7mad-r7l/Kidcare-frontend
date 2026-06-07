import 'dart:convert';
import '../../../models/appointment/child_model.dart';
import '../../apis/home/child_profile_api.dart';

class ChildProfileRepo {
  final ChildProfileApi _api = ChildProfileApi();

  Future<ChildModel> getChildDetails(int childId) async {
    String response = await _api.getChildDetails(childId);

    // معالجة دفاعية: تنظيف النص في حال كان السيرفر يرسل تحذيرات HTML قبل الـ JSON
    if (response.contains('{')) {
      response = response.substring(response.indexOf('{'));
    }

    final body = json.decode(response);

    if (body is Map<String, dynamic> && body['id'] != null) {
      return ChildModel.fromJson(body);
    }

    throw Exception(body['message'] ?? 'Failed to load child details');
  }
}