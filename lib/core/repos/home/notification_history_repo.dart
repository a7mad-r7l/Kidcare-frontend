import 'dart:convert';
import '../../../models/home/notification_history_model.dart';
import '../../apis/home/notification_history_api.dart';

class NotificationHistoryRepo {
  final NotificationHistoryApi _api = NotificationHistoryApi();

  Future<List<NotificationHistoryModel>> fetchNotifications() async {
    final response = await _api.getNotificationsHistory();

    if (response.statusCode == 200) {
      final decoded = json.decode(response.body);

      if (decoded is List) {
        return decoded
            .map(
              (json) => NotificationHistoryModel.fromJson(
                json as Map<String, dynamic>,
              ),
            )
            .toList();
      } else if (decoded is Map && decoded['notifications'] is List) {
        return (decoded['notifications'] as List)
            .map(
              (json) => NotificationHistoryModel.fromJson(
                json as Map<String, dynamic>,
              ),
            )
            .toList();
      } else if (decoded is Map && decoded['data'] is List) {
        return (decoded['data'] as List)
            .map(
              (json) => NotificationHistoryModel.fromJson(
                json as Map<String, dynamic>,
              ),
            )
            .toList();
      }
      return [];
    } else {
      throw Exception('Failed to load notifications history.');
    }
  }
}
