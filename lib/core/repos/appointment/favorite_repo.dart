import 'dart:convert';
import '../../apis/appointment/favorite_api.dart';
import '../../helper/secure_storage_service.dart';
import '../../../models/appointment/doctor_model.dart';

class FavoriteRepo {
  final FavoriteApi _api = FavoriteApi();


  Future<List<DoctorModel>> fetchFavoriteDoctors() async {
    final token = await SecureStorage.getToken();
    final response = await _api.getFavorites(token);
    final decoded = jsonDecode(response);

    if (decoded is List) {
      return decoded.map((j) => DoctorModel.fromJson(j as Map<String, dynamic>)).toList();
    } else if (decoded is Map && decoded['favorites'] is List) {
      return (decoded['favorites'] as List).map((j) => DoctorModel.fromJson(j as Map<String, dynamic>)).toList();
    }

    throw Exception(decoded['message'] ?? 'Failed to load favorite doctors');
  }


  Future<bool> toggleDoctorFavorite(int doctorId) async {
    final token = await SecureStorage.getToken();
    final response = await _api.toggleFavorite(token, doctorId);
    final decoded = jsonDecode(response);

    if (decoded is Map && decoded['status'] == 'success') {
      return true;
    }
    return false;
  }
}