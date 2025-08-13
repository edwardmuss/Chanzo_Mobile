import 'package:firebase_core/firebase_core.dart';
import 'package:kiotapay/kiotapay_pages/kiotapay_authentication/kiotapay_splash.dart';
import 'package:kiotapay/kiotapay_theme/kiotapay_theme.dart';
import 'package:kiotapay/kiotapay_theme/kiotapay_themecontroller.dart';
import 'package:kiotapay/kiotapay_translation/stringtranslation.dart';
import 'package:provider/provider.dart';
import '../kiotapay_pages/kiotapay_authentication/AuthController.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
// import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';

// import 'adapters/payment_adapter2.dart';
import 'kiotapay_pages/notifications/notification_provider.dart';
import 'kiotapay_pages/notifications/notification_service.dart';
import 'models/payment_model.dart';
late Box<Payment> paymentBox;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp();

  // Initialize notifications
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

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => NotificationProvider()),
      ],
      child: MyApp(),
    ),
  );
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
      themeMode: themeController.isdark.value ? ThemeMode.dark : ThemeMode.light,
      fallbackLocale: const Locale('en', 'US'),
      translations: Apptranslation(),
      locale: const Locale('en', 'US'),
      builder: EasyLoading.init(),
      home: const KiotaPaySplash(),
    ));
  }
}
