import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:kiotapay/globalclass/chanzo_color.dart';
import 'package:kiotapay/globalclass/kiotapay_icons.dart';
import 'package:kiotapay/kiotapay_pages/kiotapay_authentication/kiotapay_onboarding.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:kiotapay/kiotapay_pages/kiotapay_authentication/kiotapay_signin.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../globalclass/global_methods.dart';
import '../kiotapay_dahsboard/kiotapay_dahsboard.dart';
import 'AuthController.dart';

class KiotaPaySplash extends StatefulWidget {
  const KiotaPaySplash({super.key});

  @override
  State<KiotaPaySplash> createState() => _KiotaPaySplashState();
}

class _KiotaPaySplashState extends State<KiotaPaySplash> {
  final storage = FlutterSecureStorage();
  final authController = Get.put(AuthController());

  @override
  void initState() {
    super.initState();
    // SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual, overlays: []);
    goup();
  }

  goup() async {
    var navigator = Navigator.of(context);

    // Wait 8 seconds (splash)
    await Future.delayed(const Duration(seconds: 8));

    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final bool isFirstTime = prefs.getInt('isFirstTime') != 0;

    if (isFirstTime) {
      // Onboarding for first-time users
      navigator.push(MaterialPageRoute(
        builder: (context) {
          return const KiotaPayOnboarding();
        },
      ));
    } else {
      // Check if token exists in secure storage
      final token = await storage.read(key: 'token');
      print("Token is $token");

      if (token != null) {
        authController.setToken(token);

        try {
          // Hydrate AuthController from secure storage
          final userJson = await storage.read(key: 'user');
          final schoolJson = await storage.read(key: 'school');
          final sessionJson = await storage.read(key: 'current_academic_session');
          final termJson = await storage.read(key: 'current_academic_term');
          final rolesJson = await storage.read(key: 'roles');
          final permsJson = await storage.read(key: 'permissions');
          final studentsJson = await storage.read(key: 'students');
          final selectedStudentJson = await storage.read(key: 'selectedStudent');
          final cachedBalanceJson = await storage.read(key: 'feeBalance');

          if (userJson != null) authController.setUser(jsonDecode(userJson));
          if (schoolJson != null) authController.setSchool(jsonDecode(schoolJson));
          if (sessionJson != null) authController.setCurrentAcademicSession(jsonDecode(sessionJson));
          if (termJson != null) authController.setCurrentAcademicTerm(jsonDecode(termJson));
          if (rolesJson != null) authController.setRoles(List<String>.from(jsonDecode(rolesJson)));
          if (permsJson != null) authController.setPermissions(List<String>.from(jsonDecode(permsJson)));
          if (studentsJson != null) {
            authController.setStudents(List<Map<String, dynamic>>.from(jsonDecode(studentsJson)));
          }
          if (selectedStudentJson != null) {
            authController.setSelectedStudent(jsonDecode(selectedStudentJson), fetchBalance: false);
          }

          // Load cached balance immediately (for instant UI display)
          if (cachedBalanceJson != null) {
            authController.setFeeBalance(double.tryParse(cachedBalanceJson) ?? 0.0);
          }

          // Refresh user profile
          // await refreshUserProfile(context);

          // Fetch balance
          // await authController.fetchAndCacheFeeBalance();

          Get.off(() => KiotaPayDashboard('0'));

        } on TokenExpiredException {
          // Token invalid - force logout
          await forceLogout();
          Get.off(() => const KiotaPaySignIn());
        }
      } else {
        Get.off(() => const KiotaPaySignIn());
      }

    }
  }

  dynamic size;
  double height = 0.00;
  double width = 0.00;

  @override
  Widget build(BuildContext context) {
    size = MediaQuery.of(context).size;
    height = size.height;
    width = size.width;
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.topRight,
            tileMode: TileMode.clamp,
            colors: <Color>[
              ChanzoColors.white,
              ChanzoColors.white,
            ],
          ),
        ),
        child: Center(
          child: Image.asset(
            KiotaPayPngimage.logohorizontaldark,
            width: width / 2,
            fit: BoxFit.fitHeight,
          ),
        ),
      ),
    );
  }
}
