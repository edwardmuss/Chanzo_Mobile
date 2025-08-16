import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_ringtone_player/flutter_ringtone_player.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';

import 'fcm_token_manager.dart';
import 'notification_provider.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin =
  FlutterLocalNotificationsPlugin();

  static Future<void> initialize() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
    AndroidInitializationSettings('@mipmap/ic_launcher');

    final InitializationSettings initializationSettings =
    InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: DarwinInitializationSettings(),
    );

    await _notificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (details) {
        // Handle notification tap
      },
    );

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      // Refresh count when new notification arrives
      Provider.of<NotificationProvider>(Get.context!, listen: false)
          .fetchUnreadCount();
      _showNotification(message);
    });

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      // Handle notification when app is opened from terminated state
      Provider.of<NotificationProvider>(Get.context!, listen: false)
          .fetchUnreadCount();
    });

    // Setup token refresh listener
    FirebaseMessaging.instance.onTokenRefresh.listen((newToken) {
      print("Refreshed FCM Token: $newToken");
      FCMTokenManager.handleToken(newToken);
    });

    // Request permissions
    await FirebaseMessaging.instance.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    // Get initial FCM token
    final token = await FirebaseMessaging.instance.getToken();
    if (token != null) {
      print("Initial FCM Token: $token");
      await FCMTokenManager.handleToken(token);
    }
  }

  static Future<void> _showNotification(RemoteMessage message) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
    AndroidNotificationDetails(
      'your_channel_id',
      'Your Channel Name',
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
      sound: RawResourceAndroidNotificationSound('notification'),
    );

    const NotificationDetails platformChannelSpecifics =
    NotificationDetails(
      android: androidPlatformChannelSpecifics,
      iOS: DarwinNotificationDetails(),
    );

    await _notificationsPlugin.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      message.notification?.title,
      message.notification?.body,
      platformChannelSpecifics,
    );

    // Play sound
    final player = FlutterRingtonePlayer();
    await player.playNotification();
  }

  // void handleNotification(RemoteMessage message) {
  //   Provider.of<NotificationProvider>(context, listen: false).addNewNotification(
  //     NotificationModel(
  //       id: message.messageId!,
  //       title: message.notification?.title ?? 'New Notification',
  //       body: message.notification?.body ?? '',
  //       isRead: false,
  //       createdAt: DateTime.now(),
  //     ),
  //   );
  // }
}