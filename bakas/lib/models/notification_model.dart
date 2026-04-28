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
      id: json['id'] ?? 0,
      userId: json['user_id'] ?? 0,
      title: json['title'] ?? '',
      message: json['message'] ?? '',
      type: json['type'] ?? 'general',
      isRead: json['is_read'] == 1 || json['is_read'] == true,
      createdAt: () {
        try {
          String dateStr = json['created_at'].toString().replaceAll(' ', 'T');
          if (!dateStr.contains('Z') && !dateStr.contains('+')) {
            dateStr += 'Z';
          }
          return DateTime.parse(dateStr).toUtc().add(const Duration(hours: 8));
        } catch (e) {
          return DateTime.now();
        }
      }(),
    );
  }
}
