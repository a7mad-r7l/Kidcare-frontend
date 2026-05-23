import 'dart:convert';
import 'dart:io';
import '../apis/AddChildApi.dart';

class AddChildRepo {
  final AddChildApi _api = AddChildApi();

  Future<void> addChild({
    required String firstName,
    required String lastName,
    required String gender,
    required String birthDate,
    required String bloodType,
    required String medicalHistory,
    required String allergies,
    File? image,
  }) async {
    final response = await _api.addChild(
      firstName: firstName,
      lastName: lastName,
      gender: gender,
      birthDate: birthDate,
      bloodType: bloodType,
      medicalHistory: medicalHistory,
      allergies: allergies,
      image: image,
    );

    final body = json.decode(response);

    if (body['child'] == null) {
      throw Exception(body['message'] ?? 'Failed to add child');
    }
  }
}