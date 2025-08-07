import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import 'package:local_auth_darwin/local_auth_darwin.dart';
import 'package:local_auth_android/local_auth_android.dart';
import 'package:shared_preferences/shared_preferences.dart';

class KiotaPayBiometricAuth {
  static final _auth = LocalAuthentication();

  static Future<bool> hasBiometrics() async {
    try {
      return await _auth.canCheckBiometrics;
    } on PlatformException {
      return false;
    }
  }

  static Future<List<BiometricType>> getBiometrics() async {
    try {
      return await _auth.getAvailableBiometrics();
    } on PlatformException {
      return <BiometricType>[];
    }
  }

  static Future<bool> authenticateUser() async {
    final isAvailable = await hasBiometrics();

    if (!isAvailable) return false;

    try {
      return await _auth.authenticate(
        localizedReason: 'Authenticate using biometrics',
        authMessages: const <AuthMessages>[
          AndroidAuthMessages(
            signInTitle: "Chanzo Biometrics",
            cancelButton: 'No thanks',
            // biometricHint: 'Use your device fingerprint or face ID',
            biometricSuccess: 'Successfully logged in'
          ),
          IOSAuthMessages(
            cancelButton: 'No thanks',
          ),
        ],
        options: const AuthenticationOptions(
          useErrorDialogs: true,
          stickyAuth: false,
          biometricOnly: true,
          sensitiveTransaction: true,
        ),
      );
    } on PlatformException {
      return false;
    }
  }

  static Future<void> checkBiometricSetup(String userId) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    bool? isBiometricSetup = prefs.getBool('BiometricSwitchState_$userId');

    if (isBiometricSetup == true) {
      // Biometric setup is enabled for this user
      print('Biometric authentication is enabled for user: $userId');
    } else {
      // Remove any biometric setup flags for different UUIDs
      await disableBiometricForOtherUsers(userId);
    }
  }

  static Future<void> disableBiometricForOtherUsers(
      String currentUserId) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    Set<String> keys = prefs.getKeys();

    for (String key in keys) {
      if (key.startsWith('BiometricSwitchState_') &&
          key != 'BiometricSwitchState_$currentUserId') {
        await prefs.remove(key);
      }
    }
  }

  static Future<void> saveBiometricSetup(String userId) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool('BiometricSwitchState_$userId', true);
  }

  static Future<void> clearBiometricSetup(String userId) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove('BiometricSwitchState_$userId');
  }
}
