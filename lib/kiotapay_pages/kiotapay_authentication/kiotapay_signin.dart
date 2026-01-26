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

import '../../globalclass/AppEnv.dart';
import '../../globalclass/choose_student_page.dart';
import 'AuthController.dart';
import 'BranchContext.dart';
import 'SelectBranchPage.dart';
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
  final _secure = const FlutterSecureStorage();
  String? _selectedCountry; // 'KE', 'TZ', etc.

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
    _loadCountry();
  }

  void dispose() {
    super.dispose();
    usernameController.dispose();
    passwordController.dispose();
  }

  Future<void> _loadCountry() async {
    final saved = await _secure.read(key: AppEnv.storageKeyCountry);
    setState(() {
      _selectedCountry = saved ?? AppEnv.defaultCountry;
    });
    setBaseUrlForCountry(_selectedCountry!);
  }

  Future<void> _saveCountry(String code) async {
    await _secure.write(key: AppEnv.storageKeyCountry, value: code);
    setBaseUrlForCountry(code);
    setState(() => _selectedCountry = code);
  }

  void setBaseUrlForCountry(String countryCode) {
    final url = AppEnv.baseUrls[countryCode];
    if (url != null) {
      KiotaPayConstants.baseUrl = url;
    }
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
    await secureStorage.write(
        key: 'permissions', value: jsonEncode(permissions));
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

    if (usernameController.text.trim().isEmpty || passwordController.text.isEmpty) {
      hideLoading();
      showSnackBar(context, "All fields are required", Colors.red, 2.00, 2, 3);
      return;
    }

    final headers = {'Content-Type': 'application/json'};
    final payload = {
      'username': usernameController.text.trim(),
      'password': passwordController.text,
    };

    // ---------- helpers (safe parsing) ----------
    Map<String, dynamic> asMap(dynamic v) {
      if (v is Map<String, dynamic>) return v;
      if (v is Map) return Map<String, dynamic>.from(v);
      return <String, dynamic>{};
    }

    List<String> asStringList(dynamic v) {
      if (v is List) return v.whereType<String>().toList();
      return <String>[];
    }

    List<Map<String, dynamic>> asListOfMap(dynamic v) {
      if (v is List) {
        return v
            .where((e) => e is Map) // filters out nulls & non-maps
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList();
      }
      return <Map<String, dynamic>>[];
    }

    try {
      final url = Uri.parse(KiotaPayConstants.login);
      final response = await http.post(url, body: jsonEncode(payload), headers: headers);
      final json = jsonDecode(response.body);

      if (response.statusCode != 200) {
        hideLoading();
        final msg = (json is Map && json['message'] != null) ? json['message'].toString() : "Unknown Error";
        awesomeDialog(
          context,
          "Error",
          msg,
          true,
          DialogType.error,
          ChanzoColors.secondary,
        ).show();
        return;
      }

      showLoading("Successfully logged in...");

      // Root shape safety
      final root = asMap(json);
      final data = asMap(root['data']);

      // Core fields (safe)
      final token = (data['token'] ?? '').toString();
      final user = asMap(data['user']);
      final school = asMap(data['school']);
      final currentAcademicSession = asMap(data['current_academic_session']);
      final currentAcademicTermRaw = data['current_academic_term']; // may be null
      final currentAcademicTerm = currentAcademicTermRaw == null ? <String, dynamic>{} : asMap(currentAcademicTermRaw);

      final roles = asStringList(data['roles']);
      final permissions = asStringList(data['permissions']);

      // Persist uuid
      final prefs = await SharedPreferences.getInstance();
      if (user['id'] != null) {
        await prefs.setString('uuid', user['id'].toString());
      }

      // Cache auth
      await saveAuthData(
        token: token,
        user: user,
        roles: roles,
        permissions: permissions,
      );

      // Populate controller
      authController.setUser(user);
      authController.setToken(token);
      authController.setRoles(roles);
      authController.setPermissions(permissions);
      authController.setSchool(school);
      authController.setCurrentAcademicSession(currentAcademicSession);
      authController.setCurrentAcademicTerm(currentAcademicTerm);

      // Apply context payload safely
      await authController.applyLoginPayload(data);

      // If backend says "select branch/role", go there and STOP
      final action = (data['context_action'] ?? 'skip').toString();
      final requiresContext = data['requires_context_selection'] == true;

      if (requiresContext || action == 'select_branch' || action == 'select_role') {
        hideLoading();
        Get.offAll(() => SelectBranchPage());
        return;
      }

      // Ensure activeContext is stored when skip + current_context exists
      final currentCtxRaw = data['current_context'];
      if (action == 'skip' && currentCtxRaw != null) {
        authController.activeContext.value = ActiveContext.fromJson(asMap(currentCtxRaw));
      }

      // Biometric (optional)
      await KiotaPayBiometricAuth.checkBiometricSetup(user['id'].toString());

      if (_rememberMe) {
        await secureStorage.write(key: 'username', value: usernameController.text.trim());
        await secureStorage.write(key: 'password', value: passwordController.text);
      }

      if (isBioMetricEnabled) {
        await KiotaPayBiometricAuth.saveBiometricSetup(user['id'].toString());
        final authenticated = await KiotaPayBiometricAuth.authenticateUser();
        if (!authenticated) {
          SystemNavigator.pop();
          return;
        }
      } else {
        await KiotaPayBiometricAuth.clearBiometricSetup(user['id'].toString());
      }

      hideLoading();

      // ---------- Parent flow ----------
      if ((user['role'] ?? '').toString() == 'parent') {
        // SAFE students parsing (this fixes your crash)
        final allStudents = asListOfMap(data['students']);
        authController.setStudents(allStudents);

        // Must run AFTER: activeContext + students are set
        authController.ensureSelectedStudentInActiveBranch();

        final filtered = studentsForActiveBranch(allStudents);

        if (filtered.length == 1) {
          authController.setSelectedStudent(filtered.first);
          Get.offAll(() => KiotaPayDashboard('0'));
        } else {
          Get.off(() => ChooseStudentPage());
        }
        return;
      }

      // ---------- Non-parent ----------
      Get.offAll(() => KiotaPayDashboard('0'));
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

  List<Map<String, dynamic>> studentsForActiveBranch(
      List<Map<String, dynamic>> students) {
    final branchId = authController.activeContext.value?.branchId;
    if (branchId == null) return students;
    return students.where((s) => s['branch_id'] == branchId).toList();
  }

  Future<void> routeAfterLogin(AuthController auth, Map<String, dynamic> data) async {
    final action = (data['context_action'] ?? 'skip').toString();
    final requiresContext = data['requires_context_selection'] == true;

    if (auth.isGlobalRole.value) {
      // Global role: no context UI, just continue caller flow
      return;
    }

    // Needs selection: go UI and stop caller flow
    if (requiresContext || action == 'select_branch' || action == 'select_role') {
      Get.offAll(() => SelectBranchPage());
      return;
    }

    // Has current context, just store it and continue caller flow (NO navigation)
    final ctx = data['current_context'];
    if (ctx is Map) {
      auth.activeContext.value =
          ActiveContext.fromJson(Map<String, dynamic>.from(ctx));
      return;
    } else {
      // Important: if backend sent null, clear it so you don't keep stale context
      auth.activeContext.value = null;
    }

    // Auto-select if needed (rare if backend already does it)
    if (auth.availableContexts.length == 1 && auth.availableContexts.first.roles.length == 1) {
      final b = auth.availableContexts.first;
      final role = b.roles.first;

      final updated = await auth.switchContextOnServer(branchId: b.branchId, role: role);

      // updated is the whole response body: { success, message, data: {...} }
      final updatedBody = (updated is Map) ? updated : <String, dynamic>{};
      final updatedDataRaw = updatedBody['data'];

      if (updatedDataRaw is Map) {
        final updatedData = Map<String, dynamic>.from(updatedDataRaw);
        final updatedCtx = updatedData['current_context'];

        if (updatedCtx is Map) {
          auth.activeContext.value =
              ActiveContext.fromJson(Map<String, dynamic>.from(updatedCtx));
        } else {
          auth.activeContext.value = ActiveContext(
            branchId: b.branchId,
            role: role,
            branchName: b.branchName,
          );
        }
      } else {
        // If API didn't return data for some reason, still set a fallback
        auth.activeContext.value = ActiveContext(
          branchId: b.branchId,
          role: role,
          branchName: b.branchName,
        );
      }
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

  Widget _countrySelector(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Country',
          style: pregular.copyWith(fontSize: 14, color: ChanzoColors.textgrey),
        ),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(50),
            border: Border.all(color: Colors.grey.shade300),
            color: Colors.white,
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              isExpanded: true,
              value: _selectedCountry,
              hint: const Text('Select country'),
              items: const [
                DropdownMenuItem(value: 'KE', child: Text('Kenya')),
                DropdownMenuItem(value: 'TZ', child: Text('Tanzania')),
              ],
              onChanged: (v) {
                if (v == null) return;
                _saveCountry(v);
              },
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    size = MediaQuery.of(context).size;
    height = size.height;
    width = size.width;
    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(), // Dismiss keyboard on tap outside
        child: Container(
          width: double.infinity,
          height: double.infinity, // Make container take full screen
          decoration: BoxDecoration(
            image: DecorationImage(
              image: AssetImage(KiotaPayPngimage.bg),
              fit: BoxFit.cover,
              colorFilter: ColorFilter.mode(
                  ChanzoColors.primary.withOpacity(0.5), BlendMode.multiply),
            ),
          ),
          child: SingleChildScrollView(
            child: Column(
              children: <Widget>[
                SizedBox(height: height * 0.1), // 10% of screen height
                Image.asset(
                  KiotaPayPngimage.logohorizontalwhite,
                  width: MediaQuery.of(context).size.width / 2.5,
                  fit: BoxFit.scaleDown,
                ),
                SizedBox(height: height / 20),
                Container(
                  constraints: BoxConstraints(
                    minHeight: height * 0.6, // Minimum 60% of screen height
                  ),
                  decoration: BoxDecoration(
                    color: Theme.of(context).scaffoldBackgroundColor,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(30),
                      topRight: Radius.circular(30),
                    ),
                  ),
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: width / 20, // Slightly larger padding
                      vertical: height / 25,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Welcome section
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Text(
                              "Welcome!".tr,
                              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                fontSize: 24,
                                fontWeight: FontWeight.w600,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            SizedBox(height: 8),
                            Text(
                              "Enter your credentials to access the account".tr,
                              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),

                        SizedBox(height: height / 40),

                        // Country selector
                        _countrySelector(context),

                        SizedBox(height: height / 40),

                        // Username field
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "${"Email_Address".tr} / ${"Phone_Number".tr}",
                              style: pregular.copyWith(
                                fontSize: 14,
                                color: ChanzoColors.textgrey,
                              ),
                            ),
                            SizedBox(height: 6),
                            TextFormField(
                              controller: usernameController,
                              style: pregular.copyWith(fontSize: 16),
                              decoration: InputDecoration(
                                contentPadding: EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 14,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(color: Colors.grey.shade300),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(color: Colors.grey.shade300),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(color: ChanzoColors.primary, width: 2),
                                ),
                                hintText: 'Enter Username'.tr,
                                hintStyle: pregular.copyWith(
                                  fontSize: 14,
                                  color: Colors.grey.shade500,
                                ),
                                prefixIcon: Padding(
                                  padding: const EdgeInsets.all(12),
                                  child: Image.asset(
                                    KiotaPayPngimage.userprofile,
                                    height: 20,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                                filled: true,
                                fillColor: Colors.grey.shade50,
                              ),
                            ),
                          ],
                        ),

                        SizedBox(height: height / 40),

                        // Password field
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Password".tr,
                              style: pregular.copyWith(
                                fontSize: 14,
                                color: ChanzoColors.textgrey,
                              ),
                            ),
                            SizedBox(height: 6),
                            TextFormField(
                              controller: passwordController,
                              obscureText: _obscureText,
                              style: pregular.copyWith(fontSize: 16),
                              decoration: InputDecoration(
                                contentPadding: EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 14,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(color: Colors.grey.shade300),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(color: Colors.grey.shade300),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(color: ChanzoColors.primary, width: 2),
                                ),
                                hintText: 'Enter_Password'.tr,
                                hintStyle: pregular.copyWith(
                                  fontSize: 14,
                                  color: Colors.grey.shade500,
                                ),
                                prefixIcon: Padding(
                                  padding: const EdgeInsets.all(12),
                                  child: Image.asset(
                                    KiotaPayPngimage.lock,
                                    height: 20,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscureText
                                        ? Icons.visibility_off_outlined
                                        : Icons.visibility_outlined,
                                    size: 20,
                                    color: Colors.grey.shade600,
                                  ),
                                  onPressed: _togglePasswordStatus,
                                ),
                                filled: true,
                                fillColor: Colors.grey.shade50,
                              ),
                            ),
                          ],
                        ),

                        SizedBox(height: height / 40),

                        // Remember me & Forgot password
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            // Remember Me
                            Row(
                              children: [
                                Transform.scale(
                                  scale: 0.9,
                                  child: Switch.adaptive(
                                    activeColor: ChanzoColors.primary,
                                    activeTrackColor: ChanzoColors.primary.withOpacity(0.5),
                                    value: _rememberMe,
                                    onChanged: (value) {
                                      setState(() {
                                        _rememberMe = value;
                                      });
                                      _saveRememberMe(value);
                                    },
                                  ),
                                ),
                                SizedBox(width: 4),
                                Text(
                                  "Remember_Me".tr,
                                  style: pregular.copyWith(
                                    fontSize: 14,
                                    color: Colors.grey.shade700,
                                  ),
                                ),
                              ],
                            ),

                            // Forgot Password
                            InkWell(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const KiotaPayResetPasswordEmail(),
                                  ),
                                );
                              },
                              child: Text(
                                "Forgot_Password".tr,
                                style: pregular.copyWith(
                                  fontSize: 14,
                                  color: ChanzoColors.primary,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),

                        SizedBox(height: height / 30),

                        // Login button
                        InkWell(
                          onTap: () async {
                            if (_selectedCountry == null) {
                              showSnackBar(
                                context,
                                "Please select a country first",
                                Colors.red,
                                2.00,
                                2,
                                3,
                              );
                              return;
                            }
                            await _saveCountry(_selectedCountry!);
                            loginWithEmail();
                          },
                          child: Container(
                            height: height / 14,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: ChanzoColors.primary,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: ChanzoColors.primary.withOpacity(0.3),
                                  blurRadius: 8,
                                  offset: Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Center(
                              child: _isLoading
                                  ? SizedBox(
                                height: 24,
                                width: 24,
                                child: CircularProgressIndicator(
                                  color: ChanzoColors.white,
                                  strokeWidth: 2,
                                ),
                              )
                                  : Text(
                                "Log in to your account".tr,
                                style: psemibold.copyWith(
                                  fontSize: 16,
                                  color: ChanzoColors.white,
                                ),
                              ),
                            ),
                          ),
                        ),

                        SizedBox(height: height / 40),

                        // Optional: Add a loading indicator if needed
                        if (_isLoading)
                          Center(
                            child: CircularProgressIndicator(
                              color: ChanzoColors.primary,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
