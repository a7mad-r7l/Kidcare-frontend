import 'package:http/http.dart' as http;
import '../../constants.dart';
import '../../helper/secure_storage_service.dart';
import 'package:get/get.dart';

class NotificationHistoryApi {
  Future<http.Response> getNotificationsHistory() async {
    final token = await SecureStorage.getToken();

    return await http.get(
      Uri.parse('$baseUrl/notifications'),
      headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
        'Accept-Language': Get.locale?.languageCode ?? 'en',
      },
    );
  }
}
