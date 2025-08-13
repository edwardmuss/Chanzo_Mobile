import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:kiotapay/globalclass/kiotapay_constants.dart';
import 'notification_model.dart';

class NotificationProvider with ChangeNotifier {
  List<NotificationModel> _notifications = [];
  int _unreadCount = 0;

  List<NotificationModel> get notifications => _notifications;
  int get unreadCount => _unreadCount;

  Future<void> fetchNotifications({String? tab}) async {
    try {
      final response = await http.get(
        Uri.parse('${KiotaPayConstants.getNotifications}?tab=${tab ?? 'all'}'),
      );

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        final data = jsonResponse['data'];
        final List<dynamic> jsonList = data;
        _notifications = jsonList
            .map((json) => NotificationModel.fromJson(json))
            .toList();
        _unreadCount = _notifications.where((n) => !n.isRead).length;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error fetching notifications: $e');
    }
  }

  Future<void> markAsRead(String id) async {
    try {
      final response = await http.post(
          Uri.parse('${KiotaPayConstants.getNotifications}/$id/mark-as-read')
      );

      if (response.statusCode == 200) {
        final index = _notifications.indexWhere((n) => n.id == id);
        if (index != -1) {
          _notifications[index] = _notifications[index].copyWith(isRead: true);
          _unreadCount--;
          notifyListeners();
        }
      }
    } catch (e) {
      debugPrint('Error marking notification as read: $e');
    }
  }

  Future<void> markAllAsRead() async {
    try {
      final response = await http.post(
          Uri.parse('${KiotaPayConstants.getNotifications}/mark-all-read')
      );

      if (response.statusCode == 200) {
        _notifications = _notifications.map((n) => n.copyWith(isRead: true)).toList();
        _unreadCount = 0;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error marking all notifications as read: $e');
    }
  }

  void addNewNotification(NotificationModel notification) {
    _notifications.insert(0, notification);
    if (!notification.isRead) {
      _unreadCount++;
    }
    notifyListeners();
  }
}