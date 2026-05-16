import 'dart:convert';
import '../apis/reset_password_api.dart';
import '../../models/reset_password_model.dart';

class ResetPasswordRepo {
  final ResetPasswordApi _api = ResetPasswordApi();

  Future<ResetPasswordResponse> reset(String phone, String password) async {
     final responseText = await _api.resetPassword(phone, password);
    final responseBody = json.decode(responseText);

    // إذا كانت العملية ناجحة نرجع المودل
    return ResetPasswordResponse.fromJson(responseBody);
  }
}