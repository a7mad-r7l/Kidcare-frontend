import 'package:http/http.dart' as http;
import '../../constants.dart';

class DoctorApi {
  final http.Client client = http.Client();

  Future<String> getByDepartment(String token, int departmentId) async {
    final response = await client.get(
      Uri.parse('$baseUrl/departments/$departmentId/doctors'),
      headers: {
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
    return response.body;
  }

  Future<String> getById(String token, int doctorId) async {
    final response = await client.get(
      Uri.parse('$baseUrl/doctors/$doctorId'),
      headers: {
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
    return response.body;
  }

  Future<String> getAvailabilities(String token, int doctorId) async {
    final response = await client.get(
      Uri.parse('$baseUrl/doctors/$doctorId/availabilities'),
      headers: {
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
    return response.body;
  }

  Future<String> getAvailableTimes(
    String token,
    int doctorId,
    String date,
  ) async {
    final response = await client.post(
      Uri.parse('$baseUrl/doctors/$doctorId/available-times'),
      headers: {
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: {'date': date},
    );
    return response.body;
  }
}
