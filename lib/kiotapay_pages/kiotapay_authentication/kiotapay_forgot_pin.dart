import 'dart:async';
import 'dart:convert';

import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:http/http.dart' as http;
import 'package:kiotapay/globalclass/global_methods.dart';
import 'package:kiotapay/globalclass/chanzo_color.dart';
import 'package:kiotapay/globalclass/kiotapay_constants.dart';
import 'package:kiotapay/globalclass/kiotapay_fontstyle.dart';
import 'package:kiotapay/globalclass/kiotapay_global_classes.dart';
import 'package:kiotapay/globalclass/kiotapay_icons.dart';
import 'package:kiotapay/kiotapay_pages/kiotapay_authentication/kiotapay_signin.dart';
import 'package:kiotapay/kiotapay_theme/kiotapay_themecontroller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

class KiotaPayChangePin extends StatefulWidget {
  const KiotaPayChangePin({super.key});

  @override
  State<KiotaPayChangePin> createState() => _KiotaPayChangePinState();
}

class _KiotaPayChangePinState extends State<KiotaPayChangePin> {
  dynamic size;
  double height = 0.00;
  double width = 0.00;
  final themedata = Get.put(KiotaPayThemecontroler());
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
  }

  isInternetConnected() async {
    bool isConnected = await checkNetwork();
    if (!isConnected) {
      showSnackBar(context, "No internet connection", Colors.red, 2.00, 2, 10);
      return;
    }
  }

  Future<void> resetPin() async {
    isInternetConnected();
    showLoading("Just a moment");
    var minutes = await getTokenExpiryMinutes();
    if (minutes < 4) {
      refreshToken();
    }
    var token = await getAccessToken();
    var headers = {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json'
    };
    try {
      var url = Uri.parse(KiotaPayConstants.forgotUserPin);
      http.Response response = await http.put(url, headers: headers);

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        showLoading("Success...");
        hideLoading();
        Future.delayed(Duration(seconds: 3), () {
          // hideLoading();
          awesomeDialog(
            context,
            "Success",
            json['msg'],
            true,
            DialogType.info,
            ChanzoColors.primary,
            btnOkOnPress: () {
              hideLoading();
            },
          )..show();
          print(json['msg']);
        });
      } else {
        var _error =
            jsonDecode(response.body)['message'] ?? "Unknown Error Occured";
        // _dialog..dismiss();
        // context.loaderOverlay.hide();
        hideLoading();
        awesomeDialog(context, "Error", _error.toString(), true,
            DialogType.error, ChanzoColors.secondary)
          ..show();
        throw _error ?? "Unknown Error Occured";
      }
    } catch (error) {
      hideLoading();
      Fluttertoast.showToast(
          msg: "Something went wrong!",
          toastLength: Toast.LENGTH_LONG,
          gravity: ToastGravity.CENTER,
          timeInSecForIosWeb: 1,
          backgroundColor: Colors.red,
          textColor: Colors.white,
          fontSize: 16.0);
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
                      const SizedBox(height: 30),
                      Image.asset(
                        KiotaPayPngimage.emailsent,
                        width: MediaQuery.of(context).size.width / 3,
                        // height: MediaQuery.of(context).size.height / 3,
                        fit: BoxFit.fill,
                      ),
                      const SizedBox(height: 20),
                      Text(
                        "Reset PIN",
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: const Text(
                          'Tap the button below to request reset PIN link, the link shall be shared via your registered email',
                          textAlign: TextAlign.center,
                        ),
                      ),

                      Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 20),
                            InkWell(
                              splashColor: ChanzoColors.transparent,
                              highlightColor: ChanzoColors.transparent,
                              onTap: () async {
                                resetPin();
                                print('Request PWD btn clicked');
                              },
                              child: Container(
                                height: height / 15,
                                width: width / 1,
                                decoration: BoxDecoration(
                                    color: ChanzoColors.primary,
                                    borderRadius: BorderRadius.circular(50)),
                                child: Center(
                                  child: Text("Request Reset PIN".tr,
                                      style: pbold_md.copyWith(
                                          color: ChanzoColors.white)),
                                ),
                              ),
                            ),
                            SizedBox(
                              height: height / 36,
                            ),
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
                                      Text("Back Home".tr,
                                          style: pmedium_md.copyWith(
                                              color: ChanzoColors.primary)),
                                    ],
                                  ),
                                ),
                              ),
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
