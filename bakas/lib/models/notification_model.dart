class NotificationModel {
  final int id;
  final int userId;
  final String title;
  final String message;
  final String type;
  final bool isRead;
  final DateTime createdAt;

  NotificationModel({
    required this.id,
    required this.userId,
    required this.title,
    required this.message,
    required this.type,
    required this.isRead,
    required this.createdAt,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'],
      userId: json['user_id'],
      title: json['title'],
      message: json['message'],
      type: json['type'] ?? 'general',
      isRead: json['is_read'] == 1 || json['is_read'] == true,
      createdAt: () {
        DateTime utc = DateTime.parse(json['created_at'].toString().endsWith('Z')
            ? json['created_at']
            : json['created_at'] + 'Z');

        if (utc.toLocal().isAtSameMomentAs(utc)) {
          return utc.add(const Duration(hours: 8));
        }
        return utc.toLocal();
      }(),
    );
  }
}
