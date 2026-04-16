import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/notification_model.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  String _apiBaseUrl() {
    if (kIsWeb) return 'http://localhost:3001';
    if (Platform.isAndroid) return 'http://10.0.2.2:3001';
    return 'http://localhost:3001';
  }

  Future<List<NotificationModel>> fetchNotifications(int playerId) async {
    try {
      final res = await http.get(
        Uri.parse('${_apiBaseUrl()}/api/notifications?playerId=$playerId'),
      );
      if (res.statusCode == 200) {
        final payload = jsonDecode(res.body);
        if (payload['ok'] == true) {
          final List<dynamic> data = payload['data'];
          return data.map((json) => NotificationModel.fromJson(json)).toList();
        }
      }
      return [];
    } catch (e) {
      debugPrint('Error fetching notifications: $e');
      return [];
    }
  }

  Future<int> fetchUnreadCount(int playerId) async {
    try {
      final res = await http.get(
        Uri.parse('${_apiBaseUrl()}/api/notifications/unread-count?playerId=$playerId'),
      );
      if (res.statusCode == 200) {
        final payload = jsonDecode(res.body);
        if (payload['ok'] == true) {
          return payload['data']['count'] ?? 0;
        }
      }
      return 0;
    } catch (e) {
      debugPrint('Error fetching unread count: $e');
      return 0;
    }
  }

  Future<bool> markAsRead(int notificationId) async {
    try {
      final res = await http.put(
        Uri.parse('${_apiBaseUrl()}/api/notifications/$notificationId/read'),
      );
      return res.statusCode == 200;
    } catch (e) {
      debugPrint('Error marking notification as read: $e');
      return false;
    }
  }

  Future<bool> markAllAsRead(int playerId) async {
    try {
      final res = await http.post(
        Uri.parse('${_apiBaseUrl()}/api/notifications/mark-all-read'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'playerId': playerId}),
      );
      return res.statusCode == 200;
    } catch (e) {
      debugPrint('Error marking all as read: $e');
      return false;
    }
  }

  Future<bool> deleteNotification(int notificationId) async {
    try {
      final res = await http.delete(
        Uri.parse('${_apiBaseUrl()}/api/notifications/$notificationId'),
      );
      return res.statusCode == 200;
    } catch (e) {
      debugPrint('Error deleting notification: $e');
      return false;
    }
  }

  Future<bool> deleteAll(int playerId) async {
    try {
      final res = await http.delete(
        Uri.parse('${_apiBaseUrl()}/api/notifications/delete-all'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'playerId': playerId}),
      );
      return res.statusCode == 200;
    } catch (e) {
      debugPrint('Error deleting all notifications: $e');
      return false;
    }
  }
}
