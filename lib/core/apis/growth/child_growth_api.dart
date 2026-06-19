import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import '../../../core/constants.dart';
import '../../helper/secure_storage_service.dart';

class ChildGrowthApi {
  final http.Client client;

  ChildGrowthApi({http.Client? client}) : client = client ?? http.Client();

  /// 1. show child growth (GET)
  Future<http.Response> getGrowthData(int childId) async {
    final token = await SecureStorage.getToken();
    if (token.isEmpty) {
      throw Exception('Session expired. Please login again.'.tr);
    }

    final response = await client.get(
      Uri.parse('$baseUrl/children/$childId/growth'),
      headers: {
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
        'Accept-Language': Get.locale?.languageCode ?? 'en',
      },
    );
    return response;
  }

  /// 2. store growth (Post)
  Future<http.Response> storeGrowthRecord({
    required int childId,
    required double height,
    required double weight,
    required String recordDate,
  }) async {
    final token = await SecureStorage.getToken();
    if (token.isEmpty) {
      throw Exception('Session expired. Please login again.'.tr);
    }

    final response = await client.post(
      Uri.parse('$baseUrl/growth'),
      headers: {
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
        'Accept-Language': Get.locale?.languageCode ?? 'en',
      },
      body: {
        'child_id': childId.toString(),
        'height': height.toString(),
        'weight': weight.toString(),
        'date': recordDate,
      },
    );
    return response;
  }

  /// 3. delete growth (Delete)
  Future<http.Response> deleteGrowthRecord(int growthId) async {
    final token = await SecureStorage.getToken();
    if (token.isEmpty) {
      throw Exception('Session expired. Please login again.'.tr);
    }

    final response = await client.delete(
      Uri.parse('$baseUrl/growth/$growthId'),
      headers: {
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
        'Accept-Language': Get.locale?.languageCode ?? 'en',
      },
    );
    return response;
  }
}
