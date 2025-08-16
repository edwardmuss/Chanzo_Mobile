import 'dart:convert';
import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:http/http.dart' as http;

import '../../globalclass/global_methods.dart';
import '../../globalclass/kiotapay_constants.dart';

class FCMTokenManager {
  static Future<void> handleToken(String? token) async {
    // Get current token
    token ??= await FirebaseMessaging.instance.getToken();

    if (token == null) return;

    // Get device info
    final deviceInfo = DeviceInfoPlugin();
    String deviceId;
    String platform;

    if (Platform.isAndroid) {
      AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
      deviceId = androidInfo.id;
      platform = 'android';
    } else if (Platform.isIOS) {
      IosDeviceInfo iosInfo = await deviceInfo.iosInfo;
      deviceId = iosInfo.identifierForVendor!;
      platform = 'ios';
    } else {
      return;
    }

    // Send to backend
    await _sendTokenToBackend(
      fcm_token: token,
      deviceId: deviceId,
      platform: platform,
    );
  }

  static Future<void> _sendTokenToBackend({
    required String fcm_token,
    required String deviceId,
    required String platform,
  }) async {
    final token = await storage.read(key: 'token');
    // if (token == null) throw Exception('No authentication token found');
    try {
      final response = await http.post(
        Uri.parse('${KiotaPayConstants.sendNotificationTokens}'),
        headers: {
          'Authorization': 'Bearer ${token}',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'device_id': deviceId,
          'fcm_token': fcm_token,
          'platform': platform,
          'device_name': await _getDeviceName(),
        }),
      );

      print("Sending Token $fcm_token");
      if (response.statusCode != 200) {
        throw Exception('Failed to store token');
      }
    } catch (e) {
      // Implement retry logic
      print('Token submission failed: $e');
    }
  }

  static Future<String> _getDeviceName() async {
    final deviceInfo = DeviceInfoPlugin();

    if (Platform.isAndroid) {
      final androidInfo = await deviceInfo.androidInfo;
      return androidInfo.model ?? 'Android Device';
    } else if (Platform.isIOS) {
      final iosInfo = await deviceInfo.iosInfo;
      return iosInfo.name ?? 'iOS Device';
    }
    return 'Unknown Device';
  }

  static void initListeners() {
    FirebaseMessaging.instance.onTokenRefresh.listen((newToken) {
      handleToken(newToken); // Will automatically update with new token
    });
  }
}
