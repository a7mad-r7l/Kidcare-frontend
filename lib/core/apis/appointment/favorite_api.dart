import 'package:http/http.dart' as http;
import 'package:get/get.dart';
import '../../constants.dart';

class FavoriteApi {
  final http.Client client = http.Client();


  Future<String> getFavorites(String token) async {
    final response = await client.get(
      Uri.parse('$baseUrl/favorite-doctors'),
      headers: {
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
        'Accept-Language': Get.locale?.languageCode ?? 'en',
      },
    );
    return response.body;
  }


  Future<String> toggleFavorite(String token, int doctorId) async {
    final response = await client.post(
      Uri.parse('$baseUrl/doctors/$doctorId/favorite'),
      headers: {
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
        'Accept-Language': Get.locale?.languageCode ?? 'en',
      },
    );
    return response.body;
  }
}