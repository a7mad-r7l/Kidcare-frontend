import '../apis/sign_up_api.dart';

class SignUpRepo {
  final SignUpApi _api = SignUpApi();

  Future<void> registerUser({
    required String firstName,
    required String lastName,
    required String email,
    required String phone,
    required String address,
    required String password,
  }) async {
    await _api.register(
      firstName: firstName,
      lastName: lastName,
      email: email,
      phone: phone,
      address: address,
      password: password,
    );
  }
}
