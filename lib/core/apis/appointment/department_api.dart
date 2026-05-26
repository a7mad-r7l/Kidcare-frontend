import 'package:http/http.dart' as http;
import '../../constants.dart';

class DepartmentApi {
  final http.Client client = http.Client();

  Future<String> getAll(String token) async {
    final response = await client.get(
      Uri.parse('$baseUrl/departments'),
      headers: {
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
    return response.body;
  }
}
