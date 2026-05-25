import 'package:http/http.dart' as http;

import '../../constants.dart';

class LoginApi {
  Future<String> login(String phoneNumber, String password) async {
    try {
      var response = await http.post(
        Uri.parse("$baseUrl/login"),
        headers: {"Accept": "application/json"},

        body: {"phone_number": phoneNumber, "password": password},
      );

      if (response.statusCode == 200) {
        return response.body;
      } else {
        throw Exception("Error ${response.statusCode}: ${response.body}");
      }
    } catch (e) {
      rethrow;
    }
  }
}
