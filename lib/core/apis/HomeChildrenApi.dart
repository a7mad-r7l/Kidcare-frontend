import 'package:http/http.dart' as http;
import '../constants.dart';
import '../helper/secure_storage_service.dart';

class HomeChildrenApi {
  final http.Client client = http.Client();

  Future<String> getChildren() async {
    final token = await SecureStorage.getToken();

    if (token == null || token.isEmpty) {
      throw Exception('Session expired. Please login again.');
    }

    final response = await client.get(
      Uri.parse('$baseUrl/home-children'),
      headers: {
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    return response.body;
  }
}