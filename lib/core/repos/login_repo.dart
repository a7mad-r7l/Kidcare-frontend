import 'dart:convert';
import '../apis/login_api.dart';
import '../../models/user_model.dart';
import '../helper/secure_storage_service.dart';

class LoginRepo {
  final LoginApi loginApi = LoginApi();

  Future<UserModel> loginUser(String phone, String password) async {
    var response = await loginApi.login(phone, password);

    var responseBody = json.decode(response);

    String token = responseBody['Token'];
    Map<String, dynamic> userData = responseBody['user'];

    UserModel user = UserModel.fromJson(userData, token);

    await SecureStorage.storeToken(token);

    return user;
  }
}
