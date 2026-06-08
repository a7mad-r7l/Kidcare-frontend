import 'dart:convert';
import '../../../models/growth/child_growth_response_model.dart';
import '../../apis/growth/child_growth_api.dart';

class ChildGrowthRepo {
  final ChildGrowthApi api;

  ChildGrowthRepo({ChildGrowthApi? api}) : api = api ?? ChildGrowthApi();

  /// 1. معالجة  بيانات مخطط النمو (GET)

  Future<ChildGrowthResponseModel> fetchChildGrowthData(int childId) async {
    final response = await api.getGrowthData(childId);

    if (response.statusCode == 200) {
      final Map<String, dynamic> decodedData = json.decode(response.body);
      return ChildGrowthResponseModel.fromJson(decodedData);
    } else if (response.statusCode == 401) {
      throw Exception('401');
    } else {
      throw _parseError(response.body);
    }
  }

  /// 2. معالجة  إضافة سجل قياس جديد (POST)

  Future<String> addNewGrowthRecord({
    required int childId,
    required double height,
    required double weight,
    required String recordDate,
  }) async {
    final response = await api.storeGrowthRecord(
      childId: childId,
      height: height,
      weight: weight,
      recordDate: recordDate,
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      final Map<String, dynamic> decodedData = json.decode(response.body);

      return decodedData['status']?.toString() ??
          decodedData['message']?.toString() ??
          'Success';
    } else if (response.statusCode == 401) {
      throw Exception('401');
    } else {
      throw _parseError(response.body);
    }
  }

  /// 3. معالجة حذف سجل قياس سابق (DELETE)
  Future<void> removeGrowthRecord(int growthId) async {
    final response = await api.deleteGrowthRecord(growthId);

    if (response.statusCode == 200) {
      return;
    } else if (response.statusCode == 401) {
      throw Exception('401');
    } else {
      throw _parseError(response.body);
    }
  }

  ///  مساعدة لقراءة تفاصيل الخطأ  من الـ API
  dynamic _parseError(String responseBody) {
    try {
      final decoded = json.decode(responseBody);
      if (decoded is Map && decoded.containsKey('message')) {
        return decoded['message'];
      }
    } catch (_) {}
    return 'Something went wrong. Please try again.';
  }
}
