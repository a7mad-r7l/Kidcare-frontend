import 'dart:convert';
import '../apis/otp_api.dart';
import '../../models/otp_model.dart';

class OtpRepo {
  final OtpApi _api = OtpApi();

  Future<OtpResponseModel> verify(String phone, String code) async {
   final responseText = await _api.verifyOtp(phone, code);
    final responseBody = json.decode(responseText);

    // تحويل الـ Map القادم من السيرفر إلى مودل
    return OtpResponseModel.fromJson(responseBody);
  }
}