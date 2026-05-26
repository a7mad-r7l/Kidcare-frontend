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

    if (decoded is Map && decoded['children'] is List) {
      return (decoded['children'] as List)
          .map((j) => ChildModel.fromJson(j as Map<String, dynamic>))
          .toList();
    }

    final msg = (decoded is Map && decoded['message'] != null)
        ? decoded['message'].toString()
        : 'Failed to load children';
    throw Exception(msg);
  }
}
