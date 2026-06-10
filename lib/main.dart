import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:in_app_idle_detector/in_app_idle_detector.dart';
import 'package:chanzo/pages/authentication/splash.dart';
import 'package:chanzo/theme/theme.dart';
import 'package:chanzo/theme/theme_controller.dart';
import 'package:chanzo/translation/stringtranslation.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../pages/authentication/AuthController.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

// import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';

// import 'adapters/payment_adapter2.dart';
import 'firebase_options.dart';
import 'globalclass/biometric_auth.dart';
import 'globalclass/chanzo_color.dart';
import 'globalclass/constants.dart';
import 'pages/notifications/notification_provider.dart';
import 'pages/notifications/notification_service.dart';
import 'models/payment_model.dart';

late Box<Payment> paymentBox;
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  print("Handling a background message: ${message.messageId}");
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  final timeLeft = InAppIdleDetector.remainingTime;
  final idleStatus = InAppIdleDetector.isIdle;
  final userId = prefs.getString('uuid');

  // INITIALIZE FIREBASE
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // REGISTER NOTIFICATION BACKGROUND HANDLER
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  // NOTIFICATION SERVICE
  await NotificationService.initialize();

  // SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual, overlays: []);
// Initialize ObjectBox
//   final objectBox = await ObjectBox.create();
//   objectBox = await ObjectBox.create();

  await Hive.initFlutter();
  // await Hive.deleteBoxFromDisk('payments');
  Hive
    ..registerAdapter(PaymentResponseAdapter())
    ..registerAdapter(PaymentAdapter())
    ..registerAdapter(FeeCategoryAdapter())
    ..registerAdapter(AccountAdapter())
    ..registerAdapter(StudentAdapter())
    ..registerAdapter(BranchAdapter())
    ..registerAdapter(PaginationAdapter());
  paymentBox = await Hive.openBox<Payment>('payments');
  // await paymentBox.clear();

  // Register AuthController so it's available everywhere
  Get.put(AuthController());
  // Get.put<Box<Payment>>(paymentBox);

  SystemChrome.setPreferredOrientations(
      [DeviceOrientation.portraitDown, DeviceOrientation.portraitUp]);
  EasyLoading.init();
  await KiotaPayConstants.ensureCountryLoaded();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => NotificationProvider()),
      ],
      child: MyApp(),
    ),
  );

  if (userId != null) {
    final isBiometricEnabled =
        prefs.getBool('BiometricSwitchState_$userId') ?? false;

    if (isBiometricEnabled)
      InAppIdleDetector.initialize(
        timeout: const Duration(seconds: 120),
        onIdle: () {
          final context = navigatorKey.currentContext;
          _checkBiometricAuth();
          // if (context != null) {
          //   showDialog(
          //     context: context,
          //     builder: (context) => AlertDialog(
          //       title: const Text("App Idle"),
          //       content: const Text(
          //         "You've been inactive for 10 seconds, to continue please authenticate with Biometrics",
          //       ),
          //       actions: [
          //         Row(
          //           mainAxisAlignment: MainAxisAlignment.spaceBetween,
          //           children: [
          //             TextButton.icon(
          //               icon: const Icon(Icons.close),
          //               label: const Text(
          //                 "Close App",
          //                 style: TextStyle(color: ChanzoColors.secondary),
          //               ),
          //               onPressed: () {
          //                 SystemNavigator.pop(); // Close the app if biometric fails
          //               },
          //             ),
          //             TextButton.icon(
          //               icon: const Icon(Icons.fingerprint),
          //               label: const Text(
          //                 "Continue",
          //                 style: TextStyle(color: ChanzoColors.primary),
          //               ),
          //               onPressed: () {
          //                 Navigator.of(navigatorKey.currentContext!).pop();
          //                 // _checkBiometricAuth();
          //               },
          //             ),
          //           ],
          //         ),
          //       ],
          //     ),
          //   );
          // }
        },
        onActive: () {
          // _checkBiometricAuth();
          debugPrint("✅ User is active again.");
        },
      );
  }
  // InAppIdleDetector.pause();  // Stop tracking temporarily
  InAppIdleDetector.resume(); // Resume tracking
  // InAppIdleDetector.reset();  // Manually reset idle timer
}

class MyApp extends StatefulWidget {
  // final ObjectBox objectBox;
  const MyApp({Key? key}) : super(key: key);

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final themedata = Get.put(KiotaPayThemecontroler());

  @override
  Widget build(BuildContext context) {
    MediaQuery.of(context).viewInsets.bottom;
    final themeController = Get.put(KiotaPayThemecontroler());

    // Check system theme after first frame is rendered
    // WidgetsBinding.instance.addPostFrameCallback((_) {
    //   themeController.checkSystemTheme();
    // });

    return Obx(() => GetMaterialApp(
          // builder: (context, child) {
          //   // This will check system theme whenever the app resumes
          //   final themeController = Get.find<KiotaPayThemecontroler>();
          //   WidgetsBinding.instance.addPostFrameCallback((_) {
          //     themeController.checkSystemTheme();
          //   });
          //   return child!;
          // },
          debugShowCheckedModeBanner: false,
          theme: KiotaPayMythemes.lightTheme,
          darkTheme: KiotaPayMythemes.darkTheme,
          themeMode:
              themeController.isdark.value ? ThemeMode.dark : ThemeMode.light,
          fallbackLocale: const Locale('en', 'US'),
          translations: Apptranslation(),
          locale: const Locale('en', 'US'),
          builder: EasyLoading.init(),
          navigatorKey: navigatorKey,
          home: const Splash(),
        ));
  }
}

Future<void> _checkBiometricAuth() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('uuid');

    if (userId != null) {
      final isBiometricEnabled =
          prefs.getBool('BiometricSwitchState_$userId') ?? false;
      if (isBiometricEnabled) {
        final success = await _requireBiometricAuth();
        if (success) {
          // _lastAuthTime = DateTime.now(); // mark successful auth time
        }
      }
    }
  } finally {
    // _isAuthenticating = false;
  }
}

Future<bool> _requireBiometricAuth() async {
  final isAuthenticated = await KiotaPayBiometricAuth.authenticateUser();
  if (!isAuthenticated) {
    SystemNavigator.pop(); // Close the app if biometric fails
    return false;
  }
  return true;
}
