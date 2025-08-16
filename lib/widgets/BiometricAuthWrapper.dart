import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../globalclass/biometric_auth.dart';

class BiometricAuthWrapper2 extends StatefulWidget {
  final Widget child;

  const BiometricAuthWrapper2({Key? key, required this.child}) : super(key: key);

  @override
  _BiometricAuthWrapperState createState() => _BiometricAuthWrapperState();
}

class _BiometricAuthWrapperState extends State<BiometricAuthWrapper2>
    with WidgetsBindingObserver {
  DateTime? _lastActiveTime;
  Timer? _inactivityTimer;
  bool _isAuthenticating = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _startInactivityTimer();
  }

  @override
  void dispose() {
    _inactivityTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkAuthOnResume();
      _startInactivityTimer();
    } else if (state == AppLifecycleState.paused) {
      _inactivityTimer?.cancel();
      _lastActiveTime = DateTime.now();
    }
  }

  void _startInactivityTimer() {
    _inactivityTimer?.cancel();
    _inactivityTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      if (_lastActiveTime != null &&
          DateTime.now().difference(_lastActiveTime!) > const Duration(minutes: 1)) {
        _requireBiometricAuth();
      }
    });
  }

  Future<void> _checkAuthOnResume() async {
    if (_isAuthenticating) return;
    _isAuthenticating = true;

    try {
      final prefs = await SharedPreferences.getInstance();
      final isLoggedIn = prefs.getString('auth_token') != null;
      final userId = prefs.getString('uuid');

      if (isLoggedIn && userId != null) {
        final isBiometricEnabled = prefs.getBool('BiometricSwitchState_$userId') ?? false;
        if (isBiometricEnabled) {
          await _requireBiometricAuth();
        }
      }
    } finally {
      _isAuthenticating = false;
    }
  }

  Future<void> _requireBiometricAuth() async {
    final isAuthenticated = await KiotaPayBiometricAuth.authenticateUser();
    if (!isAuthenticated) {
      SystemNavigator.pop(); // Close the app if biometric fails
    }
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: (_) => _lastActiveTime = DateTime.now(),
      child: widget.child,
    );
  }
}