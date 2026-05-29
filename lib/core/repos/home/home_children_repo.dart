import 'dart:convert';
import '../../../models/home/home_child_model.dart';
import '../../apis/home/home_children_api.dart';


class HomeChildrenRepo {
  final HomeChildrenApi _api = HomeChildrenApi();

  Future<List<HomeChildModel>> getChildren() async {
    final response = await _api.getChildren();
    final body = json.decode(response);

    if (body['children'] == null) {
      throw Exception(body['message'] ?? 'Failed to load children');
    }

    final List list = body['children'];
    return list.map((e) => HomeChildModel.fromJson(e)).toList();
  }
}
