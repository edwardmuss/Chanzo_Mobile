import 'dart:async';
import 'dart:convert';

import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:kiotapay/globalclass/global_methods.dart';
import 'package:kiotapay/globalclass/chanzo_color.dart';
import 'package:kiotapay/globalclass/kiotapay_constants.dart';
import 'package:kiotapay/globalclass/kiotapay_fontstyle.dart';
import 'package:kiotapay/globalclass/kiotapay_global_classes.dart';
import 'package:kiotapay/globalclass/kiotapay_icons.dart';
import 'package:kiotapay/kiotapay_pages/kiotapay_authentication/kiotapay_reset_password_enter_code.dart';
import 'package:kiotapay/kiotapay_pages/kiotapay_authentication/kiotapay_signin.dart';
import 'package:kiotapay/kiotapay_theme/kiotapay_themecontroller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../kiotapay_dahsboard/kiotapay_dahsboard.dart';

class ChangePasswordNewUserScreen extends StatefulWidget {
  const ChangePasswordNewUserScreen({super.key});

  @override
  State<ChangePasswordNewUserScreen> createState() =>
      _ChangePasswordNewUserScreenState();
}

class _ChangePasswordNewUserScreenState
    extends State<ChangePasswordNewUserScreen> {
  dynamic size;
  double height = 0.00;
  double width = 0.00;
  final themedata = Get.put(KiotaPayThemecontroler());
  final newPasswordController = TextEditingController(text: '');
  final confirmNewPasswordController = TextEditingController(text: '');
  final Future<SharedPreferences> _prefs = SharedPreferences.getInstance();
  bool _obscureText = true;
  final _formKey = GlobalKey<FormState>();
  var confirmPass;
  final secureStorage = FlutterSecureStorage();

  @override
  void initState() {
    super.initState();
    isLoginedIn();
    isInternetConnected();
  }

  void dispose() {
    super.dispose();
    confirmNewPasswordController.dispose();
    newPasswordController.dispose();
  }

  isInternetConnected() async {
    bool isConnected = await checkNetwork();
    if (!isConnected) {
      showSnackBar(context, "No internet connection", Colors.red, 2.00, 2, 10);
      return;
    }
  }

  Future<void> changePassword() async {
    final token = await storage.read(key: 'token');
    if (token == null) throw Exception('No authentication token found');

    var headers = {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    };
    var body = {
      'new_password': newPasswordController.text,
      'confirm_new_password': confirmNewPasswordController.text,
    };

    showLoading("Just a moment");

    try {
      var url = Uri.parse(KiotaPayConstants.changePasswordNewUser);
      http.Response response =
      await http.put(url, headers: headers, body: jsonEncode(body));

      hideLoading();
      final json = jsonDecode(response.body);

      if (response.statusCode == 200 && json['success'] == true) {
        final data = json['data'];
        final user = data['user'];
        // Populate AuthController
        await secureStorage.write(key: 'user', value: jsonEncode(user));
        authController.setUser(user);
        // print(json['message']);
        // return;
        // Success
        newPasswordController.clear();
        confirmNewPasswordController.clear();
        print(json['message']);

        awesomeDialog(
          context,
          "Success",
          json['message'],
          true,
          DialogType.success,
          ChanzoColors.primary,
          btnOkText: "Continue",
          btnOkOnPress: (){
            Future.delayed(Duration(milliseconds: 200), () {
              Get.off(() => KiotaPayDashboard('0'));
            });
            },
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
                  color: themedata.isdark == false
                      ? ChanzoColors.bgcolor
                      : ChanzoColors.bgdark,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(30),
                    topRight: Radius.circular(30),
                  ),
                ),
                child: Padding(
                  padding: EdgeInsets.symmetric(
                      horizontal: width / 36, vertical: height / 36),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            "Change Password".tr,
                            style: Theme.of(context).textTheme.headlineSmall,
                            textAlign: TextAlign.center,
                          ),
                          SizedBox(height: 8), // spacing
                          Text(
                            "To get started please change your password".tr,
                            style: Theme.of(context).textTheme.labelLarge,
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                      Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 40),
                            Text(
                              "New Password",
                              style: pregular.copyWith(
                                  fontSize: 14, color: ChanzoColors.textgrey),
                            ),
                            SizedBox(
                              height: height / 200,
                            ),
                            TextFormField(
                                validator: (value) {
                                  confirmPass = value;
                                  if (value == null || value.isEmpty) {
                                    return "Please Enter New Password";
                                  } else if (value.length < 8) {
                                    return "Password must be at least 8 digits long";
                                  } else {
                                    return null;
                                  }
                                },
                                controller: confirmNewPasswordController,
                                obscureText: true,
                                scrollPadding: EdgeInsets.only(
                                    bottom: MediaQuery.of(context)
                                        .viewInsets
                                        .bottom),
                                style: pregular.copyWith(fontSize: 14),
                                decoration: InputDecoration(
                                  contentPadding: const EdgeInsets.all(8.0),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(50),
                                  ),
                                  hintText: 'New Password'.tr,
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
                            const SizedBox(height: 40),
                            Text(
                              "Confirm Password",
                              style: pregular.copyWith(
                                  fontSize: 14, color: ChanzoColors.textgrey),
                            ),
                            SizedBox(
                              height: height / 200,
                            ),
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
                                controller: newPasswordController,
                                obscureText: true,
                                scrollPadding: EdgeInsets.only(
                                    bottom: MediaQuery.of(context)
                                        .viewInsets
                                        .bottom),
                                style: pregular.copyWith(fontSize: 14),
                                decoration: InputDecoration(
                                  contentPadding: const EdgeInsets.all(8.0),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(50),
                                  ),
                                  hintText: 'New Password'.tr,
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
                            InkWell(
                              splashColor: ChanzoColors.transparent,
                              highlightColor: ChanzoColors.transparent,
                              onTap: () {
                                if (_formKey.currentState!.validate()) {
                                  changePassword();
                                }

                                print('change password btn clicked');
                              },
                              child: Container(
                                height: height / 15,
                                width: width / 1,
                                decoration: BoxDecoration(
                                    color: ChanzoColors.primary,
                                    borderRadius: BorderRadius.circular(50)),
                                child: Center(
                                  child: Text("Continue".tr,
                                      style: pbold_md.copyWith(
                                          color: ChanzoColors.white)),
                                ),
                              ),
                            ),
                            SizedBox(
                              height: height / 36,
                            ),
                          ],
                        ),
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
