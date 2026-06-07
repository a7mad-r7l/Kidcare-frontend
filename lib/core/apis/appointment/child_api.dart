import 'package:http/http.dart' as http;
import '../../constants.dart';
import 'package:get/get.dart';

class ChildApi {
  final http.Client client = http.Client();

  Future<String> getMine(String token) async {
    final response = await client.get(
      Uri.parse('$baseUrl/children'),
      headers: {
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
        "Accept-Language": Get.locale?.languageCode ?? "en",
      },
    );
    return response.body;
  }
}
