import 'package:http/http.dart' as http;
import 'package:get/get.dart';
import '../../constants.dart';

class PrescriptionApi {
  final http.Client client = http.Client();

  Future<http.Response> getMedicalRecord(
    String token,
    int appointmentId,
  ) async {
    return await client
        .get(
          Uri.parse('$baseUrl/medical-record/$appointmentId'),
          headers: {
            'Accept': 'application/json',
            'Authorization': 'Bearer $token',
            'Accept-Language': Get.locale?.languageCode ?? 'en',
          },
        )
        .timeout(const Duration(seconds: 15));
  }

  Future<http.Response> getPrescription(String token, int recordId) async {
    return await client
        .get(
          Uri.parse('$baseUrl/prescription/$recordId'),
          headers: {
            'Accept': 'application/json',
            'Authorization': 'Bearer $token',
            'Accept-Language': Get.locale?.languageCode ?? 'en',
          },
        )
        .timeout(const Duration(seconds: 15));
  }
}
