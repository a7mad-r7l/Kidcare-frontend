import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:get/get.dart';
import '../../constants.dart';
import '../../helper/secure_storage_service.dart';

class LoginApi {
  Future<String> login(String phoneNumber, String password) async {
    try {
      var response = await http
          .post(
            Uri.parse("$baseUrl/login"),
            headers: {
              "Accept": "application/json",
              "Accept-Language": Get.locale?.languageCode ?? "en",
            },
            body: {"phone_number": phoneNumber, "password": password},
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        return response.body;
      } else {
        throw Exception("Error ${response.statusCode}: ${response.body}");
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<String> deletePatientAccount() async {
    final token = await SecureStorage.getToken();

    final url = Uri.parse('$baseUrl/parent/account/terminate');

    final response = await http
        .delete(
          url,
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
            'Accept-Language': Get.locale?.languageCode ?? 'en',
            'Authorization': 'Bearer $token',
          },
        )
        .timeout(const Duration(seconds: 15));

    return response.body;
  }
}
