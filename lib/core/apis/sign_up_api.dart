import 'package:http/http.dart' as http;
import '../constants.dart';

class SignUpApi {
  final http.Client client = http.Client();

  Future<String> register({
    required String firstName,
    required String lastName,
    required String email,
    required String phone,
    required String address,
    required String password,
  }) async {
    final response = await client.post(
      Uri.parse('$baseUrl/register'),
      headers: {
        'Accept': 'application/json',
      },
      body: {
        'first_name': firstName,
        'last_name': lastName,
        'email': email,
        'phone_number': phone,
        'address': address,
        'password': password,
        'password_confirmation': password,
      },
    );

    // ✅ API مسؤولة فقط عن إرجاع الرد كـ String
    return response.body;
  }
}