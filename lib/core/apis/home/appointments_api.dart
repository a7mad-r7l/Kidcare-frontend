import 'package:http/http.dart' as http;
import '../../constants.dart';
import '../../helper/secure_storage_service.dart';
import 'package:get/get.dart';

class AppointmentsApi {
  final http.Client client = http.Client();

  // 1- Upcoming (لجميع مواعيد المستخدم)
  Future<String> getAllUpcoming() async {
    final token = await SecureStorage.getToken();
    if (token.isEmpty) throw Exception('Session expired. Please login again.');
    final response = await client.get(
      Uri.parse('$baseUrl/appointments/upcoming'),
      headers: {'Accept': 'application/json', 'Authorization': 'Bearer $token'},
    );
    return response.body;
  }

  // 2- Past (لجميع مواعيد المستخدم)
  Future<String> getAllPast() async {
    final token = await SecureStorage.getToken();
    if (token.isEmpty) throw Exception('Session expired. Please login again.');
    final response = await client.get(
      Uri.parse('$baseUrl/appointments/past'),
      headers: {'Accept': 'application/json', 'Authorization': 'Bearer $token'},
    );
    return response.body;
  }

  // 3- Upcoming by Child (لمواعيد طفل محدد)
  Future<String> getUpcomingForChild(int childId) async {
    final token = await SecureStorage.getToken();
    if (token.isEmpty) throw Exception('Session expired. Please login again.');
    final response = await client.get(
      Uri.parse('$baseUrl/appointments/upcoming/$childId'),
      headers: {'Accept': 'application/json', 'Authorization': 'Bearer $token'},
    );
    return response.body;
  }

  // 4- Past by Child (لمواعيد طفل محدد)
  Future<String> getPastForChild(int childId) async {
    final token = await SecureStorage.getToken();
    if (token.isEmpty) throw Exception('Session expired. Please login again.');
    final response = await client.get(
      Uri.parse('$baseUrl/appointments/past/$childId'),
      headers: {'Accept': 'application/json', 'Authorization': 'Bearer $token'},
    );
    return response.body;
  }
}