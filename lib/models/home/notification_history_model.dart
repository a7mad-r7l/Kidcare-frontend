class NotificationHistoryModel {
  final int id;
  final String title;
  final String body;
  final String? type;
  final String createdAt;

  NotificationHistoryModel({
    required this.id,
    required this.title,
    required this.body,
    this.type,
    required this.createdAt,
  });

  factory NotificationHistoryModel.fromJson(Map<String, dynamic> json) {
    return NotificationHistoryModel(
      id: json['id'] is int ? json['id'] : int.parse(json['id'].toString()),
      title: json['title']?.toString() ?? '',
      body: json['body']?.toString() ?? '',
      type: json['type']?.toString(),
      createdAt: json['created_at']?.toString() ?? '',
    );
  }
}
