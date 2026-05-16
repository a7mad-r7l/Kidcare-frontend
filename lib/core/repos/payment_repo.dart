import 'dart:convert';
import '../../models/appointment_details_model.dart';
import '../../models/payment_intent_model.dart';
import '../apis/payment_api.dart';

class PaymentRepo {
  final PaymentApi api = PaymentApi();

  Future<AppointmentDetailsModel> fetchAppointmentSummary(
    String appointmentId,
  ) async {
    final response = await api.getAppointmentSummary(appointmentId);
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
    final response = await api.createPaymentIntent(
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
