import 'dart:convert';
import '../../apis/appointment/department_api.dart';
import '../../helper/secure_storage_service.dart';
import '../../../models/appointment/department_model.dart';

class DepartmentRepo {
  final DepartmentApi _api;

  DepartmentRepo({DepartmentApi? api}) : _api = api ?? DepartmentApi();

  Future<List<DepartmentModel>> fetchAll() async {
    final token = await SecureStorage.getToken();
    final response = await _api.getAll(token);
    final decoded = jsonDecode(response);

    if (decoded is List) {
      return decoded
          .map((j) => DepartmentModel.fromJson(j as Map<String, dynamic>))
          .toList();
    }

    final msg = (decoded is Map && decoded['message'] != null)
        ? decoded['message'].toString()
        : 'Failed to load departments';
    throw Exception(msg);
  }
}
