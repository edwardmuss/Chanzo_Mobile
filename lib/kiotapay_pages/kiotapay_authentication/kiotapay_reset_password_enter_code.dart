import 'dart:async';
import 'dart:convert';

import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:http/http.dart' as http;
import 'package:kiotapay/globalclass/global_methods.dart';
import 'package:kiotapay/globalclass/chanzo_color.dart';
import 'package:kiotapay/globalclass/kiotapay_constants.dart';
import 'package:kiotapay/globalclass/kiotapay_fontstyle.dart';
import 'package:kiotapay/globalclass/kiotapay_global_classes.dart';
import 'package:kiotapay/globalclass/kiotapay_icons.dart';
import 'package:kiotapay/kiotapay_pages/kiotapay_authentication/kiotapay_reset_password_validate.dart';
import 'package:kiotapay/kiotapay_pages/kiotapay_authentication/kiotapay_signin.dart';
import 'package:kiotapay/kiotapay_theme/kiotapay_themecontroller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

class KiotaPayResetPasswordEnterCode extends StatefulWidget {
  const KiotaPayResetPasswordEnterCode({super.key, required this.token});

  final String token;

  @override
  State<KiotaPayResetPasswordEnterCode> createState() =>
      _KiotaPayResetPasswordEnterCodeState();
}

class _KiotaPayResetPasswordEnterCodeState
    extends State<KiotaPayResetPasswordEnterCode> {
  dynamic size;
  double height = 0.00;
  double width = 0.00;
  final themedata = Get.put(KiotaPayThemecontroler());
  final otpCodeController = TextEditingController(text: '');
  final Future<SharedPreferences> _prefs = SharedPreferences.getInstance();
  bool _obscureText = true;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    isLoginedIn();
    isInternetConnected();
  }

  void dispose() {
    super.dispose();
    otpCodeController.dispose();
  }

  isInternetConnected() async {
    bool isConnected = await checkNetwork();
    if (!isConnected) {
      showSnackBar(context, "No internet connection", Colors.red, 2.00, 2, 10);
      return;
    }
  }

  Future<void> generateResetToken() async {
    isInternetConnected();
    showLoading("Just a moment");
    var headers = {
      'Authorization': 'Bearer ${widget.token}',
      'Content-Type': 'application/json'
    };
    var payload = {'token': otpCodeController.text.trim()};
    try {
      var url = Uri.parse(KiotaPayConstants.confirmPasswordOtp);
      Map body = payload;
      http.Response response =
          await http.post(url, body: jsonEncode(body), headers: headers);

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        if (json['msg'] == 'Success' && json['isValid'] == true) {
          // final SharedPreferences? prefs = await _prefs;
          // await prefs?.setString('reset_password_token_2', json['to_use_token']);
          hideLoading();
          otpCodeController.clear();
          Get.to(() => KiotaPayResetPasswordValidate(to_us_token: json['to_use_token'],));
          print(json['to_use_token']);
        }
      } else {
        var _error =
            jsonDecode(response.body)['message'] ?? "Unknown Error Occured";
        if(_error == "Unauthorized") {
          _error == "Unauthorized or token expired/already used";
        }
        hideLoading();
        awesomeDialog(context, "Error", _error.toString(), true,
            DialogType.error, ChanzoColors.secondary, btnOkOnPress: () {
          hideLoading();
        })
          ..show();
        throw _error ?? "Unknown Error Occured";
      }
    } catch (error) {
      hideLoading();
      // Fluttertoast.showToast(
      //     msg: "Something went wrong!",
      //     toastLength: Toast.LENGTH_LONG,
      //     gravity: ToastGravity.CENTER,
      //     timeInSecForIosWeb: 1,
      //     backgroundColor: Colors.red,
      //     textColor: Colors.white,
      //     fontSize: 16.0);
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
            // SizedBox(
            //   height: height / 10,
            // ),
            // Image.asset(
            //   KiotaPayPngimage.logohorizontalwhite,
            //   width: MediaQuery.of(context).size.width / 3,
            //   // height: MediaQuery.of(context).size.height / 3,
            //   fit: BoxFit.scaleDown,
            // ),
            SizedBox(height: height / 8),
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
                      Text(
                        "Confirm OTP".tr,
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      Text(
                        "Enter the OTP sent to registered email address".tr,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 40),
                            Text(
                              "One Time Password (OTP)",
                              style: pregular.copyWith(
                                  fontSize: 14, color: ChanzoColors.textgrey),
                            ),
                            SizedBox(
                              height: height / 200,
                            ),
                            TextFormField(
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'One Time Password (OTP) is required';
                                  }
                                  return null;
                                },
                                controller: otpCodeController,
                                keyboardType: TextInputType.number,
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
                                  hintText: 'Enter One Time Password (OTP)'.tr,
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
                            SizedBox(
                              height: 10,
                            ),
                            SizedBox(
                              height: 20,
                            ),
                            InkWell(
                              splashColor: ChanzoColors.transparent,
                              highlightColor: ChanzoColors.transparent,
                              onTap: () {
                                if (_formKey.currentState!.validate()) {
                                  generateResetToken();
                                }

                                print('generate btn clicked');
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
                            // isBioMetricEnabled
                            //     ?
                            Row(children: <Widget>[
                              Expanded(child: Divider()),
                              Text(" OR "),
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
                                Navigator.push(context, MaterialPageRoute(
                                  builder: (context) {
                                    return KiotaPaySignIn();
                                  },
                                ));
                              },
                              child: Container(
                                height: height / 15,
                                width: width / 1,
                                decoration: BoxDecoration(
                                    color: ChanzoColors.transparent,
                                    borderRadius: BorderRadius.circular(50),
                                    border: Border.all(
                                        color: ChanzoColors.primary)),
                                child: Center(
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.arrow_back,
                                        color: ChanzoColors.primary,
                                        size: 24.0,
                                      ),
                                      SizedBox(
                                        width: width / 96,
                                      ),
                                      Text("Back to Login".tr,
                                          style: pmedium_md.copyWith(
                                              color: ChanzoColors.primary)),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            // : Container(),
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
