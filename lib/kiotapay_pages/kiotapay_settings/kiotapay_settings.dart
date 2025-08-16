import 'dart:convert';

import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:bootstrap_icons/bootstrap_icons.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_initicon/flutter_initicon.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:kiotapay/globalclass/global_methods.dart';
import 'package:kiotapay/globalclass/chanzo_color.dart';
import 'package:kiotapay/globalclass/kiotapay_constants.dart';
import 'package:kiotapay/globalclass/kiotapay_fontstyle.dart';
import 'package:kiotapay/globalclass/kiotapay_global_classes.dart';
import 'package:kiotapay/globalclass/text_icon_button.dart';
import 'package:kiotapay/kiotapay_models/user_model.dart';
import 'package:kiotapay/kiotapay_pages/kiotapay_authentication/kiotapay_forgot_pin.dart';
import 'package:kiotapay/kiotapay_pages/kiotapay_authentication/kiotapay_onboarding.dart';
import 'package:kiotapay/kiotapay_pages/kiotapay_dahsboard/kiotapay_dahsboard.dart';
import 'package:kiotapay/kiotapay_pages/kiotapay_settings/kiotapay_language.dart';
import 'package:kiotapay/kiotapay_pages/notifications/notification_screen.dart';
import 'package:kiotapay/kiotapay_theme/kiotapay_themecontroller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import '../../globalclass/choose_student_page.dart';
import '../../globalclass/kiotapay_icons.dart';
import 'kiotapay_editprofile.dart';

class KiotaPaySettings extends StatefulWidget {
  const KiotaPaySettings({super.key});

  @override
  State<KiotaPaySettings> createState() => _KiotaPaySettingsState();
}

class _KiotaPaySettingsState extends State<KiotaPaySettings> {
  final _formKey = GlobalKey<FormState>();
  var confirmPass;
  dynamic size;
  double height = 0.00;
  double width = 0.00;
  final themedata = Get.put(KiotaPayThemecontroler());
  RefreshController refreshController =
      RefreshController(initialRefresh: false);
  final Future<SharedPreferences> _prefs = SharedPreferences.getInstance();
  bool isdark = false;
  bool isdark1 = true;
  bool isBioMetricEnabled = false;
  bool isMultiAccount = false;

  Map<String, dynamic>? _userDataLocal;
  late User _userData;
  bool _isLoading = true;
  String pinError = '';

  TextEditingController currentPinController = TextEditingController();
  TextEditingController newPinController = TextEditingController();
  TextEditingController confirmNewController = TextEditingController();

  @override
  initState() {
    super.initState();
    _loadUserAndBiometricState();
    // getUserData();
  }

  @override
  void dispose() {
    super.dispose();
    currentPinController.dispose();
    newPinController.dispose();
    confirmNewController.dispose();
  }

  void _onRefresh() {
    // isLoginedIn();
    refreshUserProfile(context);
    refreshController.refreshCompleted();
  }

  void _onLoading() {
    refreshUserProfile(context);
    refreshController.refreshCompleted();
  }

  void fetchAccounts() async {
    showLoading('Just a moment...');
    var minutes = await getTokenExpiryMinutes();
    if (minutes < 4) {
      refreshToken();
    }
    var token = await getAccessToken();

    final response = await http.get(
      Uri.parse(KiotaPayConstants.getUserAccounts),
      headers: {
        'Authorization': 'Bearer $token',
        "Content-Type": "application/json"
      },
    );

    if (response.statusCode == 200) {
      hideLoading();
      final data = jsonDecode(response.body);
      if (data['msg'] == 'Success') {
        // Open dialog to list accounts
        showAccountSelectionDialog(data['user_details']);
      } else {
        // Handle error message
        print('Failed to fetch accounts: ${data['msg']}');
      }
    } else {
      // Handle error response
      hideLoading();
      awesomeDialog(
          context,
          "Error",
          'Failed to fetch accounts with status: ${response.statusCode}',
          true,
          DialogType.error,
          ChanzoColors.secondary)
        ..show();
      print('Failed to fetch accounts with status: ${response.statusCode}');
    }
  }

  void showAccountSelectionDialog(List accounts) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Select Account'),
          content: Container(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: accounts.length,
              itemBuilder: (BuildContext context, int index) {
                return ListTile(
                  title: Text(accounts[index]['org_name']['organisation_name']),
                  onTap: () {
                    switchAccount(
                      accounts[index]['org_name']['uuid'],
                    );
                    Navigator.of(context).pop(); // Close the dialog
                  },
                );
              },
            ),
          ),
        );
      },
    );
  }

  void switchAccount(String orgUuid) async {
    showLoading('Switching...');
    var token = await getAccessToken();
    final response = await http.post(
      Uri.parse(KiotaPayConstants.switchUserAccounts),
      headers: {
        'Authorization': 'Bearer $token',
        "Content-Type": "application/json"
      },
      body: jsonEncode({
        'to_link_organisation': orgUuid,
      }),
    );

    if (response.statusCode == 200) {
      showLoading("Successfully logged in...");
      final json = jsonDecode(response.body);
      if (json['access_token'] != null) {
        final SharedPreferences? prefs = await _prefs;
        int timestamp = DateTime.now().millisecondsSinceEpoch;
        // Handle successful account switch
        Map<String, dynamic> user = {
          'access_token': json['access_token'],
          'refresh_token': json['refresh_token'],
          'user_id': json['user']['id'],
          'uuid': json['user']['client']['uuid'],
          'approver_uuid': json['user']['uuid'],
          'role': json['user']['role'],
          'primary_phone': json['user']['primary_phone'],
          'primary_email': json['user']['primary_email'],
          'email_verified': json['user']['email_verified'],
          'username': json['user']['username'],
          'full_name': json['user']['full_name'],
          'wallet_amount': json['user']['wallet_amount'],
          'company_name': json['organisation']['organisation_name'],
          'isTransactionRequestSubscribed': json['organisation']
              ['isTransactionRequestSubscribed'],
          'allocation_request': json['organisation']['allocation_request'],
          'active': json['user']['active'],
        };
        await prefs?.setString('user', jsonEncode(user));

        await prefs?.setString('access_token', json['access_token']);
        await prefs?.setString('refresh_token', json['refresh_token']);
        await prefs?.setInt('user_id', json['user']['id']);
        await prefs?.setString('uuid', json['user']['client']['uuid']);
        await prefs?.setString('approver_uuid', json['user']['uuid']);
        await prefs?.setString('role', json['user']['role']);
        await prefs?.setBool('isActive', json['user']['active']);
        await prefs?.setString('phone', json['user']['primary_phone']);
        await prefs?.setInt('login_timestamp', timestamp);

        print('Switched account successfully');
        Get.offAll(() => KiotaPayDashboard('3'));
        hideLoading();
      } else {
        // Handle error response
        var _error = jsonDecode(response.body)['message'];
        hideLoading();
        awesomeDialog(context, "Error", _error.toString(), true,
            DialogType.error, ChanzoColors.secondary)
          ..show();

        print('Failed to switch account with status: ${response.statusCode}');
        throw _error;
      }
    } else {
      // Handle error response
      var _error =
          jsonDecode(response.body)['message'] ?? "Unknown Error Occured";
      hideLoading();
      awesomeDialog(context, "Error", _error.toString(), true, DialogType.error,
          ChanzoColors.secondary)
        ..show();

      print('Failed to switch account with status: ${response.statusCode}');
      throw _error;
    }
  }

  getUserData() async {
    final SharedPreferences? prefs = await _prefs;
    String? userPref = prefs!.getString('user') ?? '';
    Map<String, dynamic> userData =
        jsonDecode(userPref) as Map<String, dynamic>;
    print(userData['access_token']);
    if (prefs.getString('access_token') != null)
      setState(() {
        _userDataLocal = jsonDecode(userPref) as Map<String, dynamic>;
      });
    print("getuser is $_userDataLocal");
  }

  Future<User> fetchUser2() async {
    var minutes = await getTokenExpiryMinutes();
    if (minutes < 4) {
      refreshToken();
    }
    var token = await getAccessToken();
    var headers = {'Authorization': 'Bearer $token'};
    final response = await http.get(Uri.parse(KiotaPayConstants.getUserProfile),
        headers: headers);
    if (response.statusCode == 200) {
      final Map<String, dynamic> parsedJson = jsonDecode(response.body);
      final userData = User.fromJson(parsedJson['data']);
      return userData;
    } else {
      print("Not 200 Response" + response.body);
      throw Exception('Failed to load user data');
    }
  }

  void _loadUserAndBiometricState() async {
    // Fetch UUID from shared preferences
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? userId = prefs.getString('uuid');
    bool? multAccount = prefs.getBool('multiple_account');
    if (userId != null) {
      await getBiometricSwitchValues(userId);
    }
    // Fetch user data
    refreshUserProfile(context);
  }

  Future<void> getBiometricSwitchValues(String userId) async {
    isBioMetricEnabled = await getBiometricSwitchState(userId);
    print('Biometric Switch Value loaded $isBioMetricEnabled for user $userId');
    setState(() {});
  }

  saveBiometricSwitchState(String userId, bool value) async {
    showPinVerifyBottomSheet(context, value, userId);
    //
  }

  Future<bool> getBiometricSwitchState(String userId) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String key = "BiometricSwitchState_$userId";
    bool isBioMetricEnabled = prefs.getBool(key) ?? false;
    print('Biometric Switch Value loaded $isBioMetricEnabled for user $userId');
    return isBioMetricEnabled;
  }

  Future<void> verifyPinBiometric(
      String pinCode, bool value, String userId) async {
    isLoginedIn();
    var minutes = await getTokenExpiryMinutes();
    if (minutes < 4) {
      refreshToken();
    }
    final token = await storage.read(key: 'token');
    var headers = {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    };
    var body = {"user_password": pinCode};
    showLoading("Activating");
    try {
      var url = Uri.parse(KiotaPayConstants.verifyUserPassword);
      http.Response response =
          await http.post(url, headers: headers, body: jsonEncode(body));

      final json = jsonDecode(response.body);
      if (response.statusCode == 200) {

        if (json['success'] == true) {
          hideLoading();
          setState(() {
            pinError = "";
          });
          SharedPreferences prefs = await SharedPreferences.getInstance();
          String key = "BiometricSwitchState_$userId";
          print('Biometric Switch Value saved $value for user $userId');
          prefs.setBool(key, value);
          // return prefs.setBool("BiometricSwitchState", value);
          isBioMetricEnabled = value;
          awesomeDialog(
              context,
              "Success",
              "You have changed your biometric settings successfully",
              true,
              DialogType.info,
              ChanzoColors.primary)
            ..show();
        }
      } else {
        hideLoading();
        // If validation errors exist
        String errorMessage = json['message'];

        if (json['data'] is Map && json['data'].isNotEmpty) {
          errorMessage = json['data'].values
              .map((e) => e.join(", "))
              .join("\n"); // Join multiple errors
        }

        awesomeDialog(
          context,
          "Failed",
          errorMessage,
          true,
          DialogType.error,
          ChanzoColors.secondary,
        )..show();

      }
    } catch (error) {
      hideLoading();
      setState(() {
        pinError = error.toString();
      });
    }
  }

  Future<void> resetPassword() async {
    final token = await storage.read(key: 'token');
    if (token == null) throw Exception('No authentication token found');

    var headers = {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    };
    var body = {
      'current_password': currentPinController.text,
      'new_password': newPinController.text,
      'confirm_new_password': confirmNewController.text,
    };

    showLoading("Just a moment");

    try {
      var url = Uri.parse(KiotaPayConstants.changePassword);
      http.Response response =
      await http.put(url, headers: headers, body: jsonEncode(body));

      hideLoading();
      final json = jsonDecode(response.body);

      if (response.statusCode == 200 && json['success'] == true) {
        // Success
        currentPinController.clear();
        newPinController.clear();
        confirmNewController.clear();

        awesomeDialog(
          context,
          "Success",
          json['message'],
          true,
          DialogType.success,
          ChanzoColors.primary,
        )..show();
      } else {
        // If validation errors exist
        String errorMessage = json['message'];

        if (json['data'] is Map && json['data'].isNotEmpty) {
          errorMessage = json['data'].values
              .map((e) => e.join(", "))
              .join("\n"); // Join multiple errors
        }

        awesomeDialog(
          context,
          "Failed",
          errorMessage,
          true,
          DialogType.error,
          ChanzoColors.secondary,
        )..show();
      }
    } catch (error) {
      hideLoading();
      awesomeDialog(
        context,
        "Error",
        "Something went wrong. Please try again.",
        true,
        DialogType.error,
        ChanzoColors.secondary,
      )..show();
    }
  }

  void showPinVerifyBottomSheet(
      BuildContext context, bool value, String userId) {
    TextEditingController pinController = TextEditingController();

    showModalBottomSheet(
      context: context,
      // isScrollControlled: true,
      // This ensures that the bottom sheet content scrolls up when the keyboard appears
      builder: (BuildContext context) {
        return SingleChildScrollView(
          // Wrap the content with SingleChildScrollView
          child: Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context)
                  .viewInsets
                  .bottom, // Ensure the bottom padding matches the keyboard height
            ),
            child: Container(
              padding: EdgeInsets.all(30.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // SizedBox(height: 16.0),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Enter Your Password",
                        style: pregular_hsm,
                      ),
                      InkWell(
                          onTap: () {
                            Navigator.of(context).pop();
                          },
                          child: Icon(
                            BootstrapIcons.x_circle,
                          )),
                    ],
                  ),

                  SizedBox(height: 16.0),
                  TextField(
                    obscureText: true,
                    autofocus: true,
                    controller: pinController,
                    decoration: InputDecoration(
                      labelText: 'Account Password',
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10.0)),
                      contentPadding: EdgeInsets.symmetric(
                          vertical: 12.0, horizontal: 16.0),
                    ),
                    // keyboardType: TextInputType.none,
                  ),
                  SizedBox(height: 16.0),
                  Text(
                    pinError,
                    style: pregular_sm.copyWith(color: ChanzoColors.secondary),
                  ),
                  SizedBox(height: 16.0),
                  ElevatedButton(
                    onPressed: () {
                      if (pinController.text.isNotEmpty) {
                        verifyPinBiometric(
                            pinController.text.toString(), value, userId);
                        print('Password: ${pinController.text}}');
                        Navigator.pop(context); // Close the bottom sheet
                      } else {
                        Fluttertoast.showToast(
                            msg: "Please fill in Password field!",
                            toastLength: Toast.LENGTH_LONG,
                            gravity: ToastGravity.CENTER,
                            timeInSecForIosWeb: 1,
                            backgroundColor: Colors.red,
                            textColor: Colors.white,
                            fontSize: 16.0);
                        // ScaffoldMessenger.of(context).showSnackBar(
                        //   SnackBar(
                        //       content: Text('Please fill in all fields')),
                        // );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: ChanzoColors.secondary,
                      foregroundColor: ChanzoColors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10.0)),
                    ),
                    child: Text('CONFIRM'),
                  ),
                  SizedBox(height: 30)
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void showResetPASSBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      // isScrollControlled: true,
      // This ensures that the bottom sheet content scrolls up when the keyboard appears
      builder: (BuildContext context) {
        return SingleChildScrollView(
          // Wrap the content with SingleChildScrollView
          child: Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context)
                  .viewInsets
                  .bottom, // Ensure the bottom padding matches the keyboard height
            ),
            child: Form(
              key: _formKey,
              child: Container(
                padding: EdgeInsets.all(30.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // SizedBox(height: 16.0),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "Change Your Password",
                          style: pregular_hsm,
                        ),
                        InkWell(
                            onTap: () {
                              Navigator.of(context).pop();
                            },
                            child: Icon(
                              BootstrapIcons.x_circle,
                            )),
                      ],
                    ),

                    SizedBox(height: 16.0),
                    TextFormField(
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return "Please enter current Password";
                        } else {
                          return null;
                        }
                      },
                      scrollPadding: EdgeInsets.only(
                          bottom: MediaQuery.of(context).viewInsets.bottom),
                      obscureText: true,
                      autofocus: true,
                      controller: currentPinController,
                      decoration: InputDecoration(
                        labelText: 'Current Password',
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10.0)),
                        contentPadding: EdgeInsets.symmetric(
                            vertical: 12.0, horizontal: 16.0),
                      ),
                      // keyboardType: TextInputType.none,
                    ),
                    SizedBox(height: 16.0),
                    TextFormField(
                      validator: (value) {
                        confirmPass = value;
                        if (value == null || value.isEmpty) {
                          return "Please Enter New Password";
                        } else if (value.length < 8) {
                          return "Password must be at least 8 digits long";
                        } else if (value == currentPinController.text) {
                          return "New password must be different from current password";
                        } else {
                          return null;
                        }
                      },
                      scrollPadding: EdgeInsets.only(
                          bottom: MediaQuery.of(context).viewInsets.bottom),
                      obscureText: true,
                      autofocus: true,
                      controller: newPinController,
                      decoration: InputDecoration(
                        labelText: 'New Password',
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10.0)),
                        contentPadding: EdgeInsets.symmetric(
                            vertical: 12.0, horizontal: 16.0),
                      ),
                      // keyboardType: TextInputType.none,
                    ),
                    SizedBox(height: 16.0),
                    TextFormField(
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return "Please Re-Enter New Password";
                        } else if (value.length < 8) {
                          return "Password must be at least 8 digits long";
                        } else if (value != confirmPass) {
                          return "Password and confirm Password did not match";
                        } else {
                          return null;
                        }
                      },
                      scrollPadding: EdgeInsets.only(
                          bottom: MediaQuery.of(context).viewInsets.bottom),
                      obscureText: true,
                      autofocus: true,
                      controller: confirmNewController,
                      decoration: InputDecoration(
                        labelText: 'Confirm New Password',
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10.0)),
                        contentPadding: EdgeInsets.symmetric(
                            vertical: 12.0, horizontal: 16.0),
                      ),
                      // keyboardType: TextInputType.number,
                    ),
                    SizedBox(height: 16.0),
                    ElevatedButton(
                      onPressed: () {
                        if (_formKey.currentState!.validate()) {
                          resetPassword();
                          print('Pass: ${newPinController.text}}');
                          Navigator.pop(context); // Close the bottom sheet
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: ChanzoColors.primary,
                        foregroundColor: ChanzoColors.white,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10.0)),
                      ),
                      child: Text('SUBMIT'),
                    ),
                    SizedBox(height: 20)
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDarkTheme = Theme.of(context).brightness == Brightness.dark;
    size = MediaQuery.of(context).size;
    height = size.height;
    width = size.width;
    return Scaffold(
      body: SmartRefresher(
        controller: refreshController,
        enablePullDown: true,
        // enablePullUp: true,
        header: WaterDropHeader(),
        onRefresh: _onRefresh,
        onLoading: _onLoading,
        child: SingleChildScrollView(
          child: Stack(
            alignment: Alignment.center,
            children: <Widget>[
              // background image and bottom contents
              Container(
                height: 1200,
                child: Column(
                  children: <Widget>[
                    Container(
                      height: 200.0,
                      decoration: BoxDecoration(
                        image: DecorationImage(
                          image: CachedNetworkImageProvider(
                            authController.user['cover_image'] != null
                                ? '${KiotaPayConstants.webUrl}storage/${authController.user['cover_image']}'
                                : KiotaPayPngimage.card,
                          ),
                          fit: BoxFit.cover,
                          onError: (exception, stackTrace) => Container(
                            color: ChanzoColors.primary,
                          ),
                        ),
                        color: ChanzoColors.primary, // This will show behind while loading/if image fails
                      ),
                    ),
                    Expanded(
                      child: Container(
                        color: isDarkTheme ? Theme.of(context).cardColor : ChanzoColors.bgcolor,
                        width: double.infinity,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              color: Theme.of(context).cardColor,
                              width: double.infinity,
                              child: Column(
                                children: [
                                  SizedBox(height: height / 14),
                                  Center(
                                    child: Text(
                                      authController.userFullName,
                                      style: pbold_hmd.copyWith(
                                          color: Theme.of(context).colorScheme.onSecondaryContainer),
                                    ),
                                  ),
                                  Center(
                                    child: Text(
                                      "${authController.userRole == 'parent' ? authController.schoolName : authController.userRole}",
                                      style: pmedium_md.copyWith(
                                          color: Theme.of(context).colorScheme.onSecondaryContainer),
                                    ),
                                  ),
                                  authController.userRole != 'parent' ? Center(
                                    child: OutlinedButton(
                                      onPressed: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) =>
                                                KiotaPayEditProfile(),
                                          ),
                                        );
                                      },
                                      style: ButtonStyle(
                                        side: WidgetStateProperty.all(
                                          BorderSide(
                                              color: ChanzoColors.primary,
                                              width: 1.0,
                                              style: BorderStyle.solid),
                                        ),
                                      ),
                                      child: Text(
                                        "Edit Profile",
                                        style: pbold_md.copyWith(
                                            color: ChanzoColors.primary),
                                      ),
                                    ),
                                  ) : SizedBox(),
                                  SizedBox(height: 20),
                                ],
                              ),
                            ),
                            Padding(
                              padding:
                                  const EdgeInsets.only(left: 20, right: 20),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  SizedBox(height: 20),
                                  Text(
                                    "My Account",
                                    style: pmedium_lg.copyWith(
                                        color: ChanzoColors.textgrey),
                                  ),
                                  SizedBox(height: 20),
                                  authController.userRole == 'parent'
                                      ? Container(
                                          decoration: BoxDecoration(
                                              color: Theme.of(context).cardColor,
                                              border: Border.all(
                                                color: Theme.of(context).cardColor,
                                              ),
                                              borderRadius: BorderRadius.all(
                                                  Radius.circular(30))),
                                          child: TextIconButton(
                                            onPressed: () {
                                              Get.to(() => ChooseStudentPage());
                                            },
                                            icon: Icons.switch_account,
                                            leftIcon: Icons.chevron_right,
                                            label: 'Switch Student',
                                          ),
                                        )
                                      : SizedBox(),
                                  SizedBox(height: 20),
                                  Container(
                                    decoration: BoxDecoration(
                                        color: Theme.of(context).cardColor,
                                        border: Border.all(
                                          color: Theme.of(context).cardColor,
                                        ),
                                        borderRadius: BorderRadius.all(
                                            Radius.circular(30))),
                                    child: TextIconButton(
                                      onPressed: () {
                                        Get.offAll(() => KiotaPayDashboard('1'));
                                      },
                                      icon: Icons.line_axis,
                                      leftIcon: Icons.chevron_right,
                                      label: 'Manage Fee',
                                    ),
                                  ),
                                  SizedBox(height: 20),
                                  Container(
                                    decoration: BoxDecoration(
                                        color: Theme.of(context).cardColor,
                                        border: Border.all(
                                          color: Theme.of(context).cardColor,
                                        ),
                                        borderRadius: BorderRadius.all(
                                            Radius.circular(30))),
                                    child: TextIconButton(
                                      onPressed: () {
                                        Get.to(() => NotificationScreen());
                                      },
                                      icon: Icons.notifications,
                                      leftIcon: Icons.chevron_right,
                                      label: 'Notifications',
                                    ),
                                  ),
                                  // SizedBox(height: 10),
                                  // Container(
                                  //   decoration: BoxDecoration(
                                  //       color: ChanzoColors.white,
                                  //       border: Border.all(
                                  //         color: ChanzoColors.white,
                                  //       ),
                                  //       borderRadius: BorderRadius.all(
                                  //           Radius.circular(30))),
                                  //   child: TextIconButton(
                                  //     onPressed: () {
                                  //       //
                                  //     },
                                  //     icon: Icons.shield,
                                  //     leftIcon: Icons.chevron_right,
                                  //     label: 'Subscription Plan',
                                  //   ),
                                  // ),
                                  SizedBox(height: 10),
                                  Text(
                                    "Preferences",
                                    style: pmedium_lg.copyWith(
                                        color: ChanzoColors.textgrey),
                                  ),
                                  SizedBox(height: 20),
                                  Container(
                                    decoration: BoxDecoration(
                                        color: Theme.of(context).cardColor,
                                        border: Border.all(
                                          color: Theme.of(context).cardColor,
                                        ),
                                        borderRadius: BorderRadius.all(
                                            Radius.circular(30))),
                                    child: ListTile(
                                      leading: ClipOval(
                                        child: Material(
                                          color: ChanzoColors.primary20,
                                          // Button color
                                          child: InkWell(
                                            splashColor: ChanzoColors.primary,
                                            // Splash color
                                            onTap: () {},
                                            child: SizedBox(
                                              width: 50,
                                              height: 50,
                                              child: Icon(
                                                Icons.dark_mode,
                                                size: 20,
                                                color: ChanzoColors.primary,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                      title: Text("Dark_Mode".tr,
                                          style: pregular_md.copyWith(
                                              color: ChanzoColors.textgrey)),
                                      trailing: Obx(() {
                                        final themeController =
                                            Get.find<KiotaPayThemecontroler>();
                                        return Switch(
                                          activeColor: ChanzoColors.primary,
                                          onChanged: (value) =>
                                              themeController.toggleTheme(),
                                          value: themeController.isdark.value,
                                        );
                                      }),
                                    ),
                                  ),
                                  SizedBox(height: 10),
                                  Container(
                                    decoration: BoxDecoration(
                                        color: Theme.of(context).cardColor,
                                        border: Border.all(
                                          color: Theme.of(context).cardColor,
                                        ),
                                        borderRadius: BorderRadius.all(
                                            Radius.circular(30))),
                                    child: TextIconButton(
                                      onPressed: () {
                                        Get.to(() => BankPickLanguage());
                                      },
                                      icon: BootstrapIcons.globe,
                                      leftIcon: Icons.chevron_right,
                                      label: 'Language',
                                      trailingText: 'English',
                                    ),
                                  ),
                                  SizedBox(height: 10),
                                  Container(
                                    decoration: BoxDecoration(
                                        color: Theme.of(context).cardColor,
                                        border: Border.all(
                                          color: Theme.of(context).cardColor,
                                        ),
                                        borderRadius: BorderRadius.all(
                                            Radius.circular(30))),
                                    child: TextIconButton(
                                      onPressed: () {
                                        //
                                      },
                                      icon: Icons.notifications,
                                      leftIcon: Icons.chevron_right,
                                      label: 'Notification Settings',
                                    ),
                                  ),
                                  SizedBox(height: 10),
                                  Text(
                                    "Security",
                                    style: pmedium_lg.copyWith(
                                        color: ChanzoColors.textgrey),
                                  ),
                                  SizedBox(height: 20),
                                  Container(
                                    decoration: BoxDecoration(
                                        color: Theme.of(context).cardColor,
                                        border: Border.all(
                                          color: Theme.of(context).cardColor,
                                        ),
                                        borderRadius: BorderRadius.all(
                                            Radius.circular(30))),
                                    child: TextIconButton(
                                      onPressed: () {
                                        showResetPASSBottomSheet(context);
                                      },
                                      icon: Icons.pin,
                                      leftIcon: Icons.chevron_right,
                                      label: 'Change Password',
                                    ),
                                  ),
                                  SizedBox(height: 10),
                                  Container(
                                    decoration: BoxDecoration(
                                        color: Theme.of(context).cardColor,
                                        border: Border.all(
                                          color: Theme.of(context).cardColor,
                                        ),
                                        borderRadius: BorderRadius.all(
                                            Radius.circular(30))),
                                    child: ListTile(
                                      leading: ClipOval(
                                        child: Material(
                                          color: ChanzoColors.primary20,
                                          // Button color
                                          child: InkWell(
                                            splashColor: ChanzoColors.primary,
                                            // Splash color
                                            onTap: () {},
                                            child: SizedBox(
                                              width: 50,
                                              height: 50,
                                              child: Icon(
                                                Icons.fingerprint,
                                                size: 20,
                                                color: ChanzoColors.primary,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                      title: Text("Enable Biometric".tr,
                                          style: pregular_md.copyWith(
                                              color: ChanzoColors.textgrey)),
                                      trailing: Switch(
                                        activeColor: ChanzoColors.primary,
                                        onChanged: (bool value) async {
                                          SharedPreferences prefs =
                                              await SharedPreferences
                                                  .getInstance();
                                          String? userId =
                                              prefs.getString('uuid');
                                          if (userId != null) {
                                            await saveBiometricSwitchState(
                                                userId, value);
                                            setState(() {
                                              // isBioMetricEnabled = value;
                                            });
                                          }
                                          print(isBioMetricEnabled);
                                        },
                                        value: isBioMetricEnabled,
                                      ),
                                    ),
                                  ),
                                  SizedBox(height: 10),
                                  // Text(
                                  //   "Support",
                                  //   style: pmedium_lg.copyWith(
                                  //       color: ChanzoColors.textgrey),
                                  // ),
                                  // SizedBox(height: 20),
                                  // Container(
                                  //   decoration: BoxDecoration(
                                  //       color: ChanzoColors.white,
                                  //       border: Border.all(
                                  //         color: ChanzoColors.white,
                                  //       ),
                                  //       borderRadius: BorderRadius.all(
                                  //           Radius.circular(30))),
                                  //   child: TextIconButton(
                                  //     onPressed: () {
                                  //       //Get.to(() => BankPickLanguage());
                                  //     },
                                  //     icon: BootstrapIcons.question_circle,
                                  //     leftIcon: Icons.chevron_right,
                                  //     label: 'Help and Support',
                                  //   ),
                                  // ),
                                  // SizedBox(height: 10),
                                  // Container(
                                  //   decoration: BoxDecoration(
                                  //       color: ChanzoColors.white,
                                  //       border: Border.all(
                                  //         color: ChanzoColors.white,
                                  //       ),
                                  //       borderRadius: BorderRadius.all(
                                  //           Radius.circular(30))),
                                  //   child: TextIconButton(
                                  //     onPressed: () {
                                  //       //
                                  //     },
                                  //     icon: Icons.info_outline,
                                  //     leftIcon: Icons.chevron_right,
                                  //     label: 'About App',
                                  //   ),
                                  // ),
                                  // SizedBox(height: 10),
                                  // Container(
                                  //   decoration: BoxDecoration(
                                  //       color: ChanzoColors.white,
                                  //       border: Border.all(
                                  //         color: ChanzoColors.white,
                                  //       ),
                                  //       borderRadius: BorderRadius.all(
                                  //           Radius.circular(30))),
                                  //   child: TextIconButton(
                                  //     onPressed: () {
                                  //       //
                                  //     },
                                  //     icon: Icons.delete,
                                  //     leftIcon: Icons.chevron_right,
                                  //     label: 'Delete my Account',
                                  //   ),
                                  // ),
                                  SizedBox(height: 10),
                                  InkWell(
                                    splashColor: ChanzoColors.transparent,
                                    highlightColor: ChanzoColors.transparent,
                                    onTap: () {
                                      logout(context);
                                    },
                                    child: Container(
                                      height:
                                          MediaQuery.of(context).size.height /
                                              15,
                                      width: MediaQuery.of(context).size.width /
                                          1.2,
                                      decoration: BoxDecoration(
                                          color: ChanzoColors.secondary,
                                          borderRadius:
                                              BorderRadius.circular(50)),
                                      child: Center(
                                        child: Text("Logout".tr,
                                            style: pbold_md.copyWith(
                                                color: ChanzoColors.white)),
                                      ),
                                    ),
                                  ),
                                  SizedBox(height: height / 30),
                                ],
                              ),
                            )
                          ],
                        ),
                      ),
                    )
                  ],
                ),
              ),
              // Profile image
              Positioned(
                top: 150.0, // (background container size) - (circle height / 2)
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: ChanzoColors.lightPrimary, // Use your desired border color
                      width: 3.0, // Adjust border width as needed
                    ),
                  ),
                  child: CircleAvatar(
                    radius: 50,
                    backgroundColor: ChanzoColors.lightPrimary,
                    child: CachedNetworkImage(
                      imageUrl: authController.user['avatar'] != null
                          ? '${KiotaPayConstants.webUrl}storage/${authController.user['avatar']}'
                          : '', // Empty string will trigger errorWidget
                      imageBuilder: (context, imageProvider) => Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          image: DecorationImage(
                            image: imageProvider,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      placeholder: (context, url) => CircleAvatar(
                        radius: 50,
                        backgroundImage: AssetImage(KiotaPayPngimage.profile),
                      ),
                      errorWidget: (context, url, error) => CircleAvatar(
                        radius: 50,
                        backgroundImage: AssetImage(KiotaPayPngimage.profile),
                      ),
                    ),
                  ),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  _showbottomsheet() {
    showModalBottomSheet(
        context: context,
        builder: (BuildContext context) {
          return StatefulBuilder(
              builder: (BuildContext context, StateSetter setState) {
            return Container(
              decoration: BoxDecoration(
                // color: Colors.white,
                borderRadius: BorderRadius.circular(7),
              ),
              height: height / 4,
              child: Column(
                children: [
                  Container(
                    margin: const EdgeInsets.only(
                      top: 10,
                      bottom: 10,
                    ),
                    child: Text('selectapplicationlayout'.tr,
                        style: psemibold.copyWith(
                          fontSize: 14,
                        )),
                  ),
                  const Divider(),
                  SizedBox(
                    height: height / 26,
                    child: InkWell(
                      highlightColor: ChanzoColors.transparent,
                      splashColor: ChanzoColors.transparent,
                      onTap: () async {
                        await Get.updateLocale(const Locale('en', 'US'));
                        // ignore: use_build_context_synchronously
                        Navigator.of(context).pop();
                      },
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'ltr'.tr,
                            style: psemibold.copyWith(
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const Divider(),
                  SizedBox(
                    height: height / 26,
                    child: InkWell(
                      highlightColor: ChanzoColors.transparent,
                      splashColor: ChanzoColors.transparent,
                      onTap: () async {
                        await Get.updateLocale(const Locale('ar', 'ab'));
                        // ignore: use_build_context_synchronously
                        Navigator.of(context).pop();
                      },
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'rtl'.tr,
                            style: psemibold.copyWith(
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const Divider(),
                  SizedBox(
                    height: height / 26,
                    child: InkWell(
                      highlightColor: ChanzoColors.transparent,
                      splashColor: ChanzoColors.transparent,
                      onTap: () async {
                        Navigator.of(context).pop();
                      },
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'cancel'.tr,
                            style: psemibold.copyWith(
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          });
        });
  }

  Future<bool> onbackpressed() async {
    return await showDialog(
        builder: (context) => AlertDialog(
              title: Center(
                child: Text("Logout".tr,
                    textAlign: TextAlign.end,
                    style: psemibold.copyWith(fontSize: 18)),
              ),
              content: Text(
                "Are_you_sure_you_want_to_logout".tr,
                style: pregular.copyWith(fontSize: 13),
              ),
              actionsAlignment: MainAxisAlignment.end,
              actions: [
                ElevatedButton(
                  onPressed: () async {
                    // Get.to(() => const KiotaPaySignIn());
                    Get.to(() => const KiotaPayOnboarding());
                  },
                  style: ElevatedButton.styleFrom(
                      backgroundColor: ChanzoColors.primary),
                  child: Text("Yes",
                      style: pregular.copyWith(
                          color: ChanzoColors.white, fontSize: 13)),
                ),
                ElevatedButton(
                    style: ElevatedButton.styleFrom(
                        backgroundColor: ChanzoColors.primary),
                    onPressed: () {
                      Get.back();
                    },
                    child: Text(
                      "No",
                      style: pregular.copyWith(
                          color: ChanzoColors.white, fontSize: 13),
                    )),
              ],
            ),
        context: context);
  }
}
