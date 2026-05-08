import '../apis/sign_up_api.dart';
import '../helper/secure_storage_service.dart';
import '../../models/sign_up_response_model.dart';

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
    final json = await _api.register(
      firstName: firstName,
      lastName: lastName,
      email: email,
      phone: phone,
      address: address,
      password: password,
    );

    final result = SignUpResponseModel.fromJson(json);

    await SecureStorage.storeToken(result.accessToken);

    return result;
  }
}
