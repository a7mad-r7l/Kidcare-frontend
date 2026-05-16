import 'dart:convert';
import 'package:http/http.dart' as http;

import '../constants.dart';

class PaymentApi {
  // 1.   تفاصيل الموعد
  Future<String> getAppointmentSummary(String appointmentId) async {
    try {
      var response = await http.get(
        Uri.parse('$baseUrl/appointments/$appointmentId/summary'),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
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
    String appointmentId,
    String amount,
    String currency,
  ) async {
    try {
      Map<String, dynamic> body = {
        'appointment_id': appointmentId,
        'amount': amount,
        'currency': currency.toLowerCase(),
      };

      var response = await http.post(
        Uri.parse('$baseUrl/payment/checkout'),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: body,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return response.body;
      } else {
        var errorData = jsonDecode(response.body);
        throw Exception(
          errorData['message'] ?? 'Failed to initialize payment from server',
        );
      }
    } catch (err) {
      throw Exception(err.toString());
    }
  }
}
