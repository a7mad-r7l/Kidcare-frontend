import 'dart:convert';
import '../../../models/home/home_child_model.dart';
import '../../apis/home/home_children_api.dart';

class HomeChildrenRepo {
  final HomeChildrenApi _api = HomeChildrenApi();

  Future<List<HomeChildModel>> getChildren() async {
    String response = await _api.getChildren();

    // ─── Defensive Programming: Sanitize Backend Response ───
    // البحث عن أول ظهور لقوس بداية الـ JSON لتجاهل أي تحذيرات PHP أو HTML تسبقه
    final int startIndex = response.indexOf(RegExp(r'[\{\[]'));
    if (startIndex != -1) {
      response = response.substring(startIndex);
    }

    final body = json.decode(response);

    if (body['children'] == null) {
      throw Exception(body['message'] ?? 'Failed to load children');
    }

    final List list = body['children'];
    return list.map((e) => HomeChildModel.fromJson(e)).toList();
  }
}