import 'dart:convert';
import '../../apis/appointment/child_api.dart';
import '../../helper/secure_storage_service.dart';
import '../../../models/appointment/child_model.dart';

class ChildRepo {
  final ChildApi _api;

  ChildRepo({ChildApi? api}) : _api = api ?? ChildApi();

  Future<List<ChildModel>> fetchMyChildren() async {
    final token = await SecureStorage.getToken();
    final response = await _api.getMine(token);
    final decoded = jsonDecode(response);

    // 🌟 فحص مرن ومطاطي لاستخراج مصفوفة الأطفال أينما وجدت بداخل الـ JSON
    List<dynamic> listToMap = [];
    if (decoded is List) {
      listToMap = decoded;
    } else if (decoded is Map) {
      if (decoded['children'] is List) {
        listToMap = decoded['children'];
      } else if (decoded['data'] is List) {
        listToMap = decoded['data'];
      }
    }

    if (listToMap.isNotEmpty || (decoded is Map && decoded['status'] == 'success')) {
      return listToMap
          .map((j) => ChildModel.fromJson(j as Map<String, dynamic>))
          .toList();
    }

    final msg = (decoded is Map && decoded['message'] != null)
        ? decoded['message'].toString()
        : 'Failed to load children';
    throw Exception(msg);
  }
}