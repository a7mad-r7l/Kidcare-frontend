import 'dart:convert';
import '../../../models/home/profile_model.dart';
import '../../apis/home/profile_api.dart';


class ProfileRepo {
  final ProfileApi _api = ProfileApi();
  Future<void> updateProfile(Map<String, dynamic> data) async {
    final response = await _api.updateParentProfile(data);
    final body = json.decode(response);

    if (body['status'] == 'success') {
      return; // تم التحديث بنجاح
    }

    throw Exception(body['message'] ?? 'Failed to update profile');
  }

  Future<ProfileModel> getProfile() async {
    final response = await _api.getProfile();
    final body = json.decode(response);

    if (body['status'] != 'success') {
      throw Exception(body['message'] ?? 'Failed to load profile');
    }

    return ProfileModel.fromJson(body);
  }
}
