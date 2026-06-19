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

    // 🌟 التعديل هنا: استخراج المصفوفة بمرونة سواء كانت مباشرة أو داخل غلاف (data أو departments)
    List<dynamic> listToMap = [];
    if (decoded is List) {
      listToMap = decoded;
    } else if (decoded is Map) {
      if (decoded['departments'] is List) {
        listToMap = decoded['departments'];
      } else if (decoded['data'] is List) {
        listToMap = decoded['data'];
      }
    }

    // التحقق من وجود البيانات أو رسالة النجاح
    if (listToMap.isNotEmpty || (decoded is Map && decoded['status'] == 'success')) {
      return listToMap
          .map((j) => DepartmentModel.fromJson(j as Map<String, dynamic>))
          .toList();
    }

    final msg = (decoded is Map && decoded['message'] != null)
        ? decoded['message'].toString()
        : 'Failed to load departments';
    throw Exception(msg);
  }
}