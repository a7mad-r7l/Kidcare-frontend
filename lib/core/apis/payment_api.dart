import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:get/get.dart';
import '../constants.dart';

class PaymentApi {

  // 1.   تفاصيل الموعد
  Future<String> getAppointmentSummary(
    String token,
    String appointmentId,
  ) async {
    try {
      var response = await http.get(
        Uri.parse('$baseUrl/appointments/$appointmentId/summary'),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
          'Accept-Language': Get.locale?.languageCode ?? 'en',
        },
      );
      if (response.statusCode == 200) {
        return response.body;
      } else {
        var errorData = jsonDecode(response.body);
        throw Exception(
          errorData['message'] ?? 'Failed to load appointment details',
        );
      }
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  // 2.  طلب الدفع
  Future<String> createPaymentIntent(
      String token,
      String appointmentId,
      String currency,
      ) async {
    try {


      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/payment/checkout'),
      );

      request.headers.addAll({
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
        'Accept-Language': Get.locale?.languageCode ?? 'en',
      });

      request.fields['appointment_id'] = appointmentId;
      request.fields['currency'] = currency.toUpperCase();

      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);



      if (response.statusCode == 200 || response.statusCode == 201) {
        return response.body;
      } else {
        var errorData = jsonDecode(response.body);
        throw Exception(
          errorData['message'] ?? 'Backend Error: ${response.body}',
        );
      }
    } catch (err) {

      throw Exception(err.toString());
    }
  }
}
