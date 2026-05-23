import 'dart:convert';
import '../../models/appointment_details_model.dart';
import '../../models/payment_intent_model.dart';
import '../apis/payment_api.dart';
import '../helper/secure_storage_service.dart';

class PaymentRepo {
  final PaymentApi api = PaymentApi();

  Future<AppointmentDetailsModel> fetchAppointmentSummary(
    String appointmentId,
  ) async {
    String token = await SecureStorage.getToken();
    final response = await api.getAppointmentSummary(token, appointmentId);
    final data = jsonDecode(response);

    if (data['status'] == 'success') {
      return AppointmentDetailsModel.fromJson(data['data']);
    } else {
      throw Exception(data['message'] ?? "Failed to parse summary details");
    }

  }

  Future<PaymentIntentModel> fetchPaymentIntent(
    String appointmentId,
    String amount,
    String currency,
  ) async {
    String token = await SecureStorage.getToken();
    final response = await api.createPaymentIntent(
      token,
      appointmentId,
      amount,
      currency,
    );
    final data = jsonDecode(response);

    if (data['status'] == 'success') {
      return PaymentIntentModel.fromJson(data);
    } else {
      throw Exception(data['message'] ?? "Failed to process payment data");
    }
  }
}
