import 'package:flutter/material.dart';
import 'package:kiotapay/globalclass/kiotapay_prefsname.dart';
import 'package:kiotapay/kiotapay_theme/kiotapay_theme.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

class KiotaPayThemecontroler extends GetxController {
  var isdark = false.obs; // Make it observable

  @override
  void onInit() {
    _loadTheme();
    // WidgetsBinding.instance.addPostFrameCallback((_) => checkSystemTheme());
    super.onInit();
  }

  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    isdark.value = prefs.getBool(isDarkMode) ?? false;
    _applyTheme();
  }

  Future<void> toggleTheme() async {
    final prefs = await SharedPreferences.getInstance();
    isdark.value = !isdark.value;
    await prefs.setBool(isDarkMode, isdark.value);
    _applyTheme();
  }

  void _applyTheme() {
    Get.changeThemeMode(isdark.value ? ThemeMode.dark : ThemeMode.light);
    Get.changeTheme(isdark.value
        ? KiotaPayMythemes.darkTheme
        : KiotaPayMythemes.lightTheme);
  }

  void checkSystemTheme() {
    // Use try-catch as context might not be available immediately
    try {
      final brightness = MediaQuery.of(Get.context!).platformBrightness;
      isdark.value = brightness == Brightness.dark;
      _applyTheme();
    } catch (e) {
      print('Could not check system theme: $e');
    }
  }
}