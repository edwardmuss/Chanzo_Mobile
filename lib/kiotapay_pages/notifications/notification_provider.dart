import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:kiotapay/globalclass/kiotapay_constants.dart';
import '../../globalclass/global_methods.dart';
import 'notification_model.dart';

class NotificationProvider with ChangeNotifier {
  List<NotificationModel> _notifications = [];
  int _unreadCount = 0;
  bool _isLoading = false;
  Timer? _pollingTimer;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  int _currentPage = 1;
  String? _currentTab;

  List<NotificationModel> get notifications => _notifications;
  int get unreadCount => _unreadCount;
  bool get isLoading => _isLoading;
  bool get isLoadingMore => _isLoadingMore;
  bool get hasMore => _hasMore;
  String get currentTab => _currentTab!;

  Future<void> fetchNotifications({String? tab, bool loadMore = false}) async {
    if (tab != _currentTab) {
      _currentTab = tab;
      _currentPage = 1;
      _hasMore = true;
      _notifications = [];
    }

    if (!loadMore) {
      _isLoading = true;
    } else {
      if (!_hasMore || _isLoadingMore) return;
      _isLoadingMore = true;
    }

    notifyListeners();

    try {
      final token = await storage.read(key: 'token');
      if (token == null) throw Exception('No authentication token found');

      final response = await http.get(
        Uri.parse('${KiotaPayConstants.getNotifications}?page=$_currentPage&tab=${tab ?? 'all'}'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        final List<dynamic> newItems = jsonResponse['data'];
        final pagination = jsonResponse['pagination'];

        final newNotifications = newItems.map((json) => NotificationModel.fromJson(json)).toList();

        if (loadMore) {
          _notifications.addAll(newNotifications);
        } else {
          _notifications = newNotifications;
        }

        _unreadCount = _notifications.where((n) => n.unread).length;
        _hasMore = pagination['current_page'] < pagination['last_page'];
        _currentPage = pagination['current_page'] + 1;
      }
    } catch (e) {
      debugPrint('Error fetching notifications: $e');
    } finally {
      _isLoading = false;
      _isLoadingMore = false;
      notifyListeners();
    }
  }

  Future<void> loadMoreNotifications() async {
    await fetchNotifications(tab: _currentTab, loadMore: true);
  }

  Future<void> markAsRead(String id) async {
    try {
      final token = await storage.read(key: 'token');
      if (token == null) throw Exception('No authentication token found');
      final response = await http.post(
        Uri.parse('${KiotaPayConstants.getNotifications}/$id/mark-as-read'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final index = _notifications.indexWhere((n) => n.id == id);
        if (index != -1) {
          _notifications[index] = _notifications[index].copyWith(unread: true);
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
      final token = await storage.read(key: 'token');
      if (token == null) throw Exception('No authentication token found');
      final response = await http.post(
        Uri.parse('${KiotaPayConstants.getNotifications}/mark-all-read'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        _notifications =
            _notifications.map((n) => n.copyWith(unread: true)).toList();
        _unreadCount = 0;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error marking all notifications as read: $e');
    }
  }

  Future<void> fetchUnreadCount() async {
    final token = await storage.read(key: 'token');
    if (token == null) throw Exception('No authentication token found');
    try {
      final response = await http.get(
          Uri.parse('${KiotaPayConstants.getNotifications}/unread-count'),
          headers: {
            'Authorization': 'Bearer $token',
            'Accept': 'application/json',
          },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        _unreadCount = data['data']['count'] ?? 0;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error fetching unread count: $e');
    }
  }

  void startPolling() {
    // Fetch immediately
    // fetchUnreadCount();

    // Then poll every 120 seconds, 2 mins
    _pollingTimer = Timer.periodic(Duration(seconds: 120), (_) {
      fetchUnreadCount();
    });
  }

  void stopPolling() {
    _pollingTimer?.cancel();
  }

  @override
  void dispose() {
    stopPolling();
    super.dispose();
  }

  void addNewNotification(NotificationModel notification) {
    _notifications.insert(0, notification);
    if (!notification.unread) {
      _unreadCount++;
    }
    notifyListeners();
  }
}
