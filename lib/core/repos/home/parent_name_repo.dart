import 'dart:convert';
import '../../apis/home/parent_name_api.dart';


class ParentNameRepo {
  final ParentNameApi _api = ParentNameApi();

  Future<String> getParentName() async {
    final response = await _api.getParentName();
    final body = json.decode(response);

    if (body['user'] == null) {
      throw Exception(body['message'] ?? 'Failed to load user');
    }

    final firstName = body['user']['first_name'] ?? '';
    final lastName = body['user']['last_name'] ?? '';
    return '$firstName $lastName';
  }
}
