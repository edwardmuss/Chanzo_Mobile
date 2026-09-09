import 'dart:io';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_ringtone_player/flutter_ringtone_player.dart';
import 'package:get/get.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;

import 'fcm_token_manager.dart';
import 'notification_provider.dart';
import 'notification_screen.dart';

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

    // 1. FOREGROUND TAP: Handle when a user taps the local notification popup
    await _notificationsPlugin.initialize(
      settings: initializationSettings,
      onDidReceiveNotificationResponse: (details) {
        Get.to(() => NotificationScreen());
      },
    );

    // 2. BACKGROUND TAP: Handle notification when app is minimized
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      Provider.of<NotificationProvider>(Get.context!, listen: false).fetchUnreadCount();
      Get.to(() => NotificationScreen());
    });

    // 3. TERMINATED TAP: Handle notification when app is completely closed
    RemoteMessage? initialMessage = await FirebaseMessaging.instance.getInitialMessage();
    if (initialMessage != null) {
      // Use a slight delay to ensure Flutter has mounted the initial route before pushing
      Future.delayed(const Duration(milliseconds: 500), () {
        Get.to(() => NotificationScreen());
      });
    }

    // 4. FOREGROUND MESSAGE RECEIVED: Build the custom popup
    FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
      print("🔥 FOREGROUND NOTIFICATION RECEIVED: ${message.notification?.title}");

      try {
        Provider.of<NotificationProvider>(Get.context!, listen: false).fetchUnreadCount();
        await _showNotification(message);
      } catch (e) {
        print("❌ LOCAL NOTIFICATION CRASHED: $e");
      }
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

  // --- Image Downloading Helper ---
  static Future<String> _downloadAndSaveFile(String url, String fileName) async {
    final Directory directory = await getApplicationDocumentsDirectory();
    final String filePath = '${directory.path}/$fileName';
    final http.Response response = await http.get(Uri.parse(url));
    final File file = File(filePath);
    await file.writeAsBytes(response.bodyBytes);
    return filePath;
  }

  static Future<void> _showNotification(RemoteMessage message) async {
    // Check if the payload contains an image URL
    String? imageUrl = message.notification?.android?.imageUrl ?? message.notification?.apple?.imageUrl;

    BigPictureStyleInformation? bigPictureStyle;

    // If there is an image, download it and prepare the BigPicture format
    if (imageUrl != null && imageUrl.isNotEmpty) {
      try {
        final String largeIconPath = await _downloadAndSaveFile(imageUrl, 'notification_img');
        bigPictureStyle = BigPictureStyleInformation(
          FilePathAndroidBitmap(largeIconPath),
          hideExpandedLargeIcon: true,
          contentTitle: message.notification?.title,
          summaryText: message.notification?.body,
        );
      } catch (e) {
        print("Failed to download notification image: $e");
      }
    }

    AndroidNotificationDetails androidPlatformChannelSpecifics = AndroidNotificationDetails(
      'your_channel_id',
      'Your Channel Name',
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
      // If image exists, apply the style. Otherwise, null uses the default text style.
      styleInformation: bigPictureStyle,
      sound: const RawResourceAndroidNotificationSound('notification'),
    );

    NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
      iOS: const DarwinNotificationDetails(), // Add iOS attachments here if you support iOS
    );

    await _notificationsPlugin.show(
      id: message.hashCode,
      title: message.notification?.title,
      body: message.notification?.body,
      notificationDetails: platformChannelSpecifics,
    );

    // Play sound
    final player = FlutterRingtonePlayer();
    await player.playNotification();
  }
}