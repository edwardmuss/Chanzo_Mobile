import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'dart:io' show Platform;

import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:bootstrap_icons/bootstrap_icons.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter/services.dart';
import 'package:flutter_initicon/flutter_initicon.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:kiotapay/globalclass/global_methods.dart';
import 'package:kiotapay/globalclass/biometric_auth.dart';
import 'package:kiotapay/globalclass/chanzo_color.dart';
import 'package:kiotapay/globalclass/kiotapay_constants.dart';
import 'package:kiotapay/globalclass/kiotapay_fontstyle.dart';
import 'package:kiotapay/globalclass/kiotapay_global_classes.dart';
import 'package:kiotapay/globalclass/kiotapay_icons.dart';
import 'package:kiotapay/kiotapay_pages/kiotapay_authentication/kiotapay_pincode.dart';
import 'package:kiotapay/kiotapay_pages/kiotapay_authentication/kiotapay_reset_password_email.dart';
import 'package:kiotapay/kiotapay_pages/kiotapay_authentication/kiotapay_verify_code.dart';
import 'package:kiotapay/kiotapay_pages/kiotapay_dahsboard/kiotapay_dahsboard.dart';
import 'package:kiotapay/kiotapay_theme/kiotapay_themecontroller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:kiotapay/models/user_model.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../globalclass/choose_student_page.dart';
import 'AuthController.dart';
import 'change_password_new_user.dart';

class KiotaPaySignIn extends StatefulWidget {
  const KiotaPaySignIn({super.key});

  @override
  State<KiotaPaySignIn> createState() => _KiotaPaySignInState();
}

class _KiotaPaySignInState extends State<KiotaPaySignIn> {
  dynamic size;
  double height = 0.00;
  double width = 0.00;
  final themedata = Get.put(KiotaPayThemecontroler());
  late bool isBioMetricEnabled = false;
  final usernameController = TextEditingController(text: '');
  final passwordController = TextEditingController(text: "");
  final Future<SharedPreferences> _prefs = SharedPreferences.getInstance();
  final secureStorage = FlutterSecureStorage();
  final authController = Get.put(AuthController());
  bool _obscureText = true;
  bool _isLoading = false;
  bool _rememberMe = false;
  String? _token;
  Map<String, dynamic>? _userData;
  List<dynamic> _accounts = [];

  void _togglePasswordStatus() {
    setState(() {
      _obscureText = !_obscureText;
    });
  }

  @override
  void initState() {
    super.initState();
    checkForUpdate();
    getBiometricSwitchState();
    // getUserData();
    isLoginedIn();
    isInternetConnected();
    _loadRememberMe();
    _loadRememberedCredentials();
  }

  void dispose() {
    super.dispose();
    usernameController.dispose();
    passwordController.dispose();
  }

  getBiometricSwitchState() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? userId = prefs.getString('uuid');
    String key = "BiometricSwitchState_$userId";
    bool _isBioMetricEnabled = prefs.getBool(key) ?? false;
    print('Biometric Switch Value loaded $isBioMetricEnabled for user $userId');
    setState(() {
      isBioMetricEnabled = _isBioMetricEnabled;
    });
  }

// Load the saved value
  void _loadRememberMe() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _rememberMe = prefs.getBool('remember_me') ?? false;
    });
  }

  // Save the value
  void _saveRememberMe(bool value) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool('remember_me', value);
  }

  Future<void> _loadRememberedCredentials() async {
    try {
      final username = await secureStorage.read(key: 'username');
      final password = await secureStorage.read(key: 'password');

      if (username != null && password != null) {
        setState(() {
          usernameController.text = username;
          passwordController.text = password;
          _rememberMe = true;
        });
      }
    } catch (e) {
      print('Error loading remembered credentials: $e');
    }
  }

  isInternetConnected() async {
    bool isConnected = await checkNetwork();
    if (!isConnected) {
      showSnackBar(context, "No internet connection", Colors.red, 2.00, 2, 5);
      return;
    }
  }

  Future<void> checkForUpdate() async {
    final String installedVersion = await getInstalledVersion();
    final String latestVersion = await fetchLatestVersion();

    if (_compareVersions(installedVersion, latestVersion) < 0) {
      // _showUpdateDialog();
    }
  }

  Future<String> getInstalledVersion() async {
    final PackageInfo packageInfo = await PackageInfo.fromPlatform();
    return packageInfo.version;
  }

  Future<String> fetchLatestVersion() async {
    final response = await http
        .get(Uri.parse('https://cloudrebue.co.ke/latest_version.txt'));
    if (response.statusCode == 200) {
      return response.body.trim();
    } else {
      throw Exception('Failed to fetch version info');
    }
  }

  int _compareVersions(String v1, String v2) {
    final List<int> version1 = v1.split('.').map(int.parse).toList();
    final List<int> version2 = v2.split('.').map(int.parse).toList();

    for (int i = 0; i < version1.length; i++) {
      if (i >= version2.length) return 1;
      if (version1[i] < version2[i]) return -1;
      if (version1[i] > version2[i]) return 1;
    }
    return 0;
  }

  void _showUpdateDialog() {
    showDialog(
      context: context,
      barrierDismissible: true, // Make dialog undismissible by tapping outside
      builder: (BuildContext context) {
        return WillPopScope(
          onWillPop: () async => false, // Prevent back button dismissal
          child: AlertDialog(
            title: Text('Update Available'),
            content: Text(
                'A new version of the app is available. Please update to the latest version.'),
            actions: <Widget>[
              TextButton(
                child: Text('Update'),
                onPressed: () {
                  // Open the appropriate store page
                  if (Platform.isAndroid) {
                    _launchURL(
                        'https://play.google.com/store/apps/details?id=com.chanzo.app');
                  } else if (Platform.isIOS) {
                    _launchURL('https://apps.apple.com/app/id6504042142');
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _launchURL(String url) async {
    final Uri uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      throw 'Could not launch $url';
    }
  }

  Future<void> saveAuthData({
    required String token,
    required Map<String, dynamic> user,
    required List<String> roles,
    required List<String> permissions,
  }) async {
    await secureStorage.write(key: 'token', value: token);
    await secureStorage.write(key: 'user', value: jsonEncode(user));
    await secureStorage.write(key: 'roles', value: jsonEncode(roles));
    await secureStorage.write(key: 'permissions', value: jsonEncode(permissions));
    await secureStorage.write(
        key: 'login_timestamp',
        value: DateTime.now().millisecondsSinceEpoch.toString());
  }

  Future<void> LoginWithBiometric() async {
    showSnackBar(context, "Please wait...", Colors.green, 2.00, 2, 2);

    try {
      //
    } catch (e) {
      hideLoading();
      // Log any errors
      print("Error during login: $e");
    }
  }

  Future<void> loginWithEmail() async {
    isInternetConnected();
    showLoading("Authenticating");

    if (usernameController.text == '' || passwordController.text == '') {
      hideLoading();
      showSnackBar(context, "All fields are required", Colors.red, 2.00, 2, 3);
      return;
    }

    var headers = {'Content-Type': 'application/json'};
    var payload = {
      'username': usernameController.text.trim(),
      'password': passwordController.text
    };

    try {
      var url = Uri.parse(KiotaPayConstants.login);
      http.Response response = await http.post(
        url,
        body: jsonEncode(payload),
        headers: headers,
      );
      final json = jsonDecode(response.body);

      if (response.statusCode == 200) {
        showLoading("Successfully logged in...");

        final data = json['data'];

        final token = data['token'];
        final school = data['school'];
        final currentAcademicSession = data['current_academic_session'];
        final currentAcademicTerm = data['current_academic_term'];
        final user = data['user'];
        final roles = List<String>.from(data['roles']);
        final permissions = List<String>.from(data['permissions']);

        SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setString('uuid', user['id'].toString());

        // Cache data in secure storage
        await saveAuthData(
          token: token,
          user: user,
          roles: roles,
          permissions: permissions,
        );

        // Populate AuthController
        authController.setUser(user);
        authController.setToken(token);
        authController.setRoles(roles);
        authController.setPermissions(permissions);
        authController.setSchool(school);
        authController.setCurrentAcademicSession(currentAcademicSession);
        authController.setCurrentAcademicTerm(currentAcademicTerm);

        // Optional: Setup biometric
        await KiotaPayBiometricAuth.checkBiometricSetup(user['id'].toString());
        print(await storage.read(key: 'token'));
        print("Token set in controller: ${authController.token.value}");

        hideLoading();
        // Handle parent students
        if (user['role'] == 'parent') {
          // Extract students array
          List<Map<String, dynamic>> students = List<Map<String, dynamic>>.from(data['students']);

          // Save all students in controller
          authController.setStudents(students);

          // If "Remember me" is checked, save credentials securely
          if (_rememberMe) {
            await secureStorage.write(
              key: 'username',
              value: usernameController.text,
            );
            await secureStorage.write(
              key: 'password',
              value: passwordController.text,
            );
          }

          // Check if biometric is enabled
          if (isBioMetricEnabled) {
            await KiotaPayBiometricAuth.saveBiometricSetup(user['id'].toString());
            // Require biometric auth immediately after enabling
            final authenticated = await KiotaPayBiometricAuth.authenticateUser();
            if (!authenticated) {
              SystemNavigator.pop();
              return;
            }
          } else {
            await KiotaPayBiometricAuth.clearBiometricSetup(user['id'].toString());
          }

          if (students.length == 1) {
            // Auto-select if only one child
            authController.setSelectedStudent(students.first);
            Get.offAll(() => KiotaPayDashboard('0'));
          } else {
            // Show modal/page to pick student
            Get.off(() => ChooseStudentPage());
          }
        } else {
          // Non-parent users
          Get.offAll(() => KiotaPayDashboard('0'));
        }
      } else {
        var error = jsonDecode(response.body)['message'] ?? "Unknown Error";
        // If validation errors exist
        String errorMessage = json['message'];

        if (json['data'] is Map && json['data'].isNotEmpty) {
          errorMessage = json['data'].values
              .map((e) => e.join(", "))
              .join("\n"); // Join multiple errors
        }
        hideLoading();
        awesomeDialog(
          context,
          "Error",
          errorMessage,
          true,
          DialogType.error,
          ChanzoColors.secondary,
        ).show();
      }
    } catch (error) {
      hideLoading();
      awesomeDialog(
        context,
        "Error",
        error.toString(),
        true,
        DialogType.error,
        ChanzoColors.secondary,
      ).show();
    }
  }

  getUserData() async {
    final SharedPreferences? prefs = await _prefs;
    String? userPref = prefs!.getString('user') ?? '';

    if (userPref.isNotEmpty) {
      Map<String, dynamic> userData =
          jsonDecode(userPref) as Map<String, dynamic>;
      print(userData['access_token']);
      if (prefs.getString('access_token') != null)
        setState(() {
          _userData = jsonDecode(userPref) as Map<String, dynamic>;
        });
      print("getuser is $_userData");
    }
  }

  @override
  Widget build(BuildContext context) {
    size = MediaQuery.of(context).size;
    height = size.height;
    width = size.width;
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage(KiotaPayPngimage.bg),
            fit: BoxFit.cover,
            colorFilter: ColorFilter.mode(
                ChanzoColors.primary.withOpacity(0.5), BlendMode.multiply),
          ),
        ),
        child: Column(
          children: <Widget>[
            SizedBox(height: 80),
            SizedBox(
              height: height / 20,
            ),
            Image.asset(
              KiotaPayPngimage.logohorizontalwhite,
              width: MediaQuery.of(context).size.width / 2.5,
              // height: MediaQuery.of(context).size.height / 3,
              fit: BoxFit.scaleDown,
            ),
            SizedBox(height: height / 20),
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).scaffoldBackgroundColor,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(30),
                    topRight: Radius.circular(30),
                  ),
                ),
                child: Padding(
                  padding: EdgeInsets.symmetric(
                      horizontal: width / 36, vertical: height / 36),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            "Welcome!".tr,
                            style: Theme.of(context).textTheme.headlineMedium,
                            textAlign: TextAlign.center,
                          ),
                          SizedBox(height: 8), // spacing
                          Text(
                            "Enter your credentials to access the account".tr,
                            style: Theme.of(context).textTheme.labelLarge,
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                      // Text(
                      //   "Welcome!".tr,
                      //   style: Theme.of(context).textTheme.headlineMedium,
                      // ),
                      // Text(
                      //   "Enter your credentials to access the account".tr,
                      //   style: pregular.copyWith(
                      //     fontSize: 14,
                      //     color: ChanzoColors.primary,
                      //   ),
                      // ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 20),
                          Text(
                            "${"Email_Address".tr} / ${"Phone_Number".tr}",
                            style: pregular.copyWith(
                                fontSize: 14, color: ChanzoColors.textgrey),
                          ),
                          SizedBox(
                            height: height / 200,
                          ),
                          TextFormField(
                              controller: usernameController,
                              scrollPadding: EdgeInsets.only(
                                  bottom:
                                      MediaQuery.of(context).viewInsets.bottom),
                              style: pregular.copyWith(fontSize: 14),
                              decoration: InputDecoration(
                                contentPadding: const EdgeInsets.all(8.0),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(50),
                                ),
                                hintText: 'Enter Username'.tr,
                                hintStyle: pregular.copyWith(fontSize: 14),
                                prefixIcon: Padding(
                                    padding: const EdgeInsets.all(14),
                                    child: Image.asset(
                                      KiotaPayPngimage.userprofile,
                                      height: height / 36,
                                      color: ChanzoColors.textgrey,
                                    )),
                                focusedBorder: UnderlineInputBorder(
                                    borderRadius: BorderRadius.circular(0),
                                    borderSide: const BorderSide(
                                        color: ChanzoColors.primary)),
                              )),
                          SizedBox(
                            height: height / 36,
                          ),
                          Text(
                            "Password".tr,
                            style: pregular.copyWith(
                                fontSize: 14, color: ChanzoColors.textgrey),
                          ),
                          SizedBox(
                            height: height / 200,
                          ),
                          TextFormField(
                            controller: passwordController,
                            obscureText: _obscureText,
                            scrollPadding: EdgeInsets.only(
                                bottom:
                                    MediaQuery.of(context).viewInsets.bottom),
                            style: pregular.copyWith(fontSize: 14),
                            decoration: InputDecoration(
                              contentPadding: const EdgeInsets.all(8.0),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(50),
                              ),
                              hintText: 'Enter_Password'.tr,
                              hintStyle: pregular.copyWith(fontSize: 14),
                              prefixIcon: Padding(
                                  padding: const EdgeInsets.all(14),
                                  child: Image.asset(
                                    KiotaPayPngimage.lock,
                                    height: height / 36,
                                    color: ChanzoColors.textgrey,
                                  )),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscureText
                                      ? Icons.visibility_off_outlined
                                      : Icons.visibility_outlined,
                                  size: height / 36,
                                  color: ChanzoColors.textgrey,
                                ),
                                onPressed: _togglePasswordStatus,
                              ),
                              focusedBorder: UnderlineInputBorder(
                                  borderRadius: BorderRadius.circular(0),
                                  borderSide: const BorderSide(
                                      color: ChanzoColors.primary)),
                            ),
                          ),
                          SizedBox(
                            height: 5,
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              // Remember Me switch and label
                              Row(
                                children: [
                                  Transform.scale(
                                    scale: 0.8,
                                    child: Switch(
                                      activeTrackColor: ChanzoColors.primary,
                                      inactiveThumbColor:
                                          ChanzoColors.secondary,
                                      trackOutlineColor: MaterialStateProperty
                                          .resolveWith<Color?>(
                                        (Set<WidgetState> states) {
                                          if (states
                                              .contains(WidgetState.selected)) {
                                            return Colors
                                                .transparent; // Selected state
                                          }
                                          return ChanzoColors
                                              .primary; // Default state
                                        },
                                      ),
                                      value: _rememberMe,
                                      onChanged: (value) {
                                        setState(() {
                                          _rememberMe = value;
                                        });
                                        _saveRememberMe(
                                            value); // Save to SharedPreferences
                                      },
                                    ),
                                  ),
                                  Text(
                                    "Remember_Me".tr,
                                    style: pregular.copyWith(
                                      fontSize: 14,
                                      // color: ChanzoColors.primary,
                                    ),
                                  ),
                                ],
                              ),
                              // Forgot Password link
                              InkWell(
                                splashColor: ChanzoColors.transparent,
                                highlightColor: ChanzoColors.transparent,
                                onTap: () {
                                  Navigator.push(context, MaterialPageRoute(
                                    builder: (context) {
                                      return const KiotaPayResetPasswordEmail();
                                    },
                                  ));
                                },
                                child: Text("Forgot_Password".tr,
                                    style: pregular.copyWith(
                                        fontSize: 14,
                                        color: ChanzoColors.primary)),
                              ),
                            ],
                          ),
                          SizedBox(
                            height: 10,
                          ),
                          InkWell(
                            splashColor: ChanzoColors.transparent,
                            highlightColor: ChanzoColors.transparent,
                            onTap: () async {
                              loginWithEmail();
                              print('Login btn clicked');
                            },
                            child: Container(
                              height: height / 15,
                              width: width / 1,
                              decoration: BoxDecoration(
                                  color: ChanzoColors.primary,
                                  borderRadius: BorderRadius.circular(50)),
                              child: Center(
                                child: Text("Log in to your account".tr,
                                    style: psemibold.copyWith(
                                        fontSize: 14,
                                        color: ChanzoColors.white)),
                              ),
                            ),
                          ),
                          SizedBox(
                            height: height / 100,
                          ),
                          // isBioMetricEnabled
                          //     ? InkWell(
                          //         splashColor:
                          //             ChanzoColors.primary.withOpacity(0.5),
                          //         highlightColor:
                          //             ChanzoColors.primary.withOpacity(0.3),
                          //         onTap: () async {
                          //           await LoginWithBiometric();
                          //           print('Biometric btn clicked');
                          //         },
                          //         child: Material(
                          //           type: MaterialType.card,
                          //           // Use transparency for a clean circle effect
                          //           borderRadius: BorderRadius.circular(50),
                          //           child: Container(
                          //             height: height / 15,
                          //             width: width / 1,
                          //             decoration: BoxDecoration(
                          //                 color: ChanzoColors.secondary,
                          //                 borderRadius:
                          //                     BorderRadius.circular(50)),
                          //             child: Center(
                          //               child: Row(
                          //                 mainAxisAlignment:
                          //                     MainAxisAlignment.center,
                          //                 children: [
                          //                   Icon(
                          //                     Icons.fingerprint,
                          //                     color: ChanzoColors.primary,
                          //                     size: 24.0,
                          //                   ),
                          //                   SizedBox(
                          //                     width: width / 96,
                          //                   ),
                          //                   Text(
                          //                     "Biometric/Face IDs".tr,
                          //                     style: pmedium_md.copyWith(
                          //                         color: ChanzoColors.primary),
                          //                   ),
                          //                 ],
                          //               ),
                          //             ),
                          //           ),
                          //         ),
                          //       )
                          //     : SizedBox(),
                          SizedBox(
                            height: height / 60,
                          ),
                          Row(children: <Widget>[
                            Expanded(child: Divider()),
                            Text(" New user? "),
                            Expanded(child: Divider()),
                          ]),
                          // : Container(),
                          SizedBox(
                            height: height / 36,
                          ),
                          // isBioMetricEnabled
                          //     ?
                          InkWell(
                            splashColor: ChanzoColors.transparent,
                            highlightColor: ChanzoColors.transparent,
                            onTap: () {
                              // Navigator.push(context, MaterialPageRoute(
                              //   builder: (context) {
                              //     return KiotaPayVerifyCode();
                              //   },
                              // ));

                              awesomeDialog(
                                context,
                                "Error",
                                "Coming Soon",
                                true,
                                DialogType.error,
                                ChanzoColors.secondary,
                              )..show();
                            },
                            child: Container(
                              height: height / 15,
                              width: width / 1,
                              decoration: BoxDecoration(
                                  color: ChanzoColors.transparent,
                                  borderRadius: BorderRadius.circular(50),
                                  border:
                                      Border.all(color: ChanzoColors.primary)),
                              child: Center(
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      "Book a Demo".tr,
                                      style: pmedium_md.copyWith(
                                          color: ChanzoColors.primary),
                                    ),
                                    SizedBox(
                                      width: width / 96,
                                    ),
                                    Icon(
                                      Icons.arrow_right_alt,
                                      color: ChanzoColors.primary,
                                      size: 24.0,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          // : Container(),
                          // Row(
                          //   mainAxisAlignment: MainAxisAlignment.center,
                          //   children: [
                          //     Text("Im_a_new_user".tr,
                          //         style: pregular.copyWith(
                          //             fontSize: 14,
                          //             color: ChanzoColors.textgrey)),
                          //     SizedBox(
                          //       width: width / 96,
                          //     ),
                          //     InkWell(
                          //       splashColor: ChanzoColors.transparent,
                          //       highlightColor: ChanzoColors.transparent,
                          //       onTap: () {
                          //         Navigator.push(context, MaterialPageRoute(
                          //           builder: (context) {
                          //             return const BankPickSignUp();
                          //           },
                          //         ));
                          //       },
                          //       child: Text("Sign_Up".tr,
                          //           style: pmedium.copyWith(
                          //               fontSize: 14,
                          //               color: ChanzoColors.primary)),
                          //     ),
                          //   ],
                          // )
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
