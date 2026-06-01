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

    // ✅ التعديل هنا: الباك إند يرسل البيانات مباشرة بدون غلاف status أو data
    if (data is Map<String, dynamic> && data.containsKey('patient_name')) {
      return AppointmentDetailsModel.fromJson(data);
    } else {
      throw Exception(data['message'] ?? "Failed to parse summary details");
    }
  }

  Future<PaymentIntentModel> fetchPaymentIntent(
      String appointmentId,
      String currency,
      ) async {
    String token = await SecureStorage.getToken();
    final response = await api.createPaymentIntent(
      token,
      appointmentId,
      currency,
    );
    final data = jsonDecode(response);

    // ✅ التعديل هنا: نعتمد على وجود الـ client_secret بدلاً من كلمة success
    if (data['client_secret'] != null) {
      return PaymentIntentModel.fromJson(data);
    } else {
      throw Exception(data['message'] ?? "Failed to process payment data");
    }
  }
}