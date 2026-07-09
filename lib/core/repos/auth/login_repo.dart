import 'dart:convert';
import '../../../models/auth/user_model.dart';
import '../../apis/auth/login_api.dart';
import '../../helper/secure_storage_service.dart';

class LoginRepo {
  final LoginApi _api = LoginApi();

  Future<UserModel> loginUser(String phone, String password) async {
    var response = await _api.login(phone, password);
    var responseBody = json.decode(response);

    if (responseBody['status'] == 'success') {
      if (responseBody['user'] == null) {
        throw Exception(
          "Login successful, but 'user' data is missing from server!",
        );
      }

      String token = responseBody['Token'];
      Map<String, dynamic> userData = responseBody['user'];

      UserModel user = UserModel.fromJson(userData, token);

      await SecureStorage.storeToken(token);

      return user;
    } else {
      throw Exception(responseBody['message'] ?? 'Invalid login details');
    }
  }

  Future<String> deletePatientAccount() async {
    String rawResponse = await _api.deletePatientAccount();

    if (rawResponse.contains('{')) {
      rawResponse = rawResponse.substring(rawResponse.indexOf('{'));
    }

    final decoded = jsonDecode(rawResponse);

    if (decoded['status'] == 'success' || decoded['message'] != null) {
      return decoded['message'] ?? 'Account terminated successfully.';
    } else {
      throw Exception('Failed to terminate account');
    }
  }
}
