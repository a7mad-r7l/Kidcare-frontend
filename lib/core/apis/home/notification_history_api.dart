
import 'package:http/http.dart' as http;
import '../../constants.dart';
import '../../helper/secure_storage_service.dart';

class NotificationHistoryApi {
  Future<http.Response> getNotificationsHistory() async {
    final token = await SecureStorage.getToken();
    final lang = await SecureStorage.getLanguage() ?? 'en';

    return await http.get(
      Uri.parse('$baseUrl/notifications'),
      headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
        'Accept-Language': lang,
      },
    );
  }
}
