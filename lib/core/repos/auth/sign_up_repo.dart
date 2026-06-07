import 'dart:convert';
import '../../apis/auth/sign_up_api.dart';
import '../../helper/secure_storage_service.dart';
import '../../../models/auth/sign_up_response_model.dart';

class SignUpRepo {
  final SignUpApi _api = SignUpApi();

  Future<SignUpResponseModel> registerUser({
    required String firstName,
    required String lastName,
    required String email,
    required String phone,
    required String address,
    required String password,
  }) async {
    String response = await _api.register(
      firstName: firstName,
      lastName: lastName,
      email: email,
      phone: phone,
      address: address,
      password: password,
    );

    // ─── Defensive Programming: Sanitize Backend Response ───
    // تجاهل أي رسائل خطأ أو HTML تسبق بداية الـ JSON الحقيقي
    final int startIndex = response.indexOf(RegExp(r'[\{\[]'));
    if (startIndex != -1) {
      response = response.substring(startIndex);
    }

    var body = json.decode(response);

    // ✅ إذا رجع errors أو لم يرجع phone_number = فشل
    if (body['errors'] != null || body['phone_number'] == null) {
      throw Exception(body['message'] ?? 'Registration failed');
    }

    final result = SignUpResponseModel.fromJson(body);

    if (result.accessToken.isNotEmpty) {
      await SecureStorage.storeToken(result.accessToken);
    }

    return result;
  }
}