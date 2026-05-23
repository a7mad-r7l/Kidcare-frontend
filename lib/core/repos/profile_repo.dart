import 'dart:convert';
import '../apis/profile_api.dart';
import '../../models/profile_model.dart';

class ProfileRepo {
  final ProfileApi _api = ProfileApi();

  Future<ProfileModel> getProfile() async {
    final response = await _api.getProfile();
    final body = json.decode(response);

    if (body['status'] != 'success') {
      throw Exception(body['message'] ?? 'Failed to load profile');
    }

    return ProfileModel.fromJson(body);
  }
}