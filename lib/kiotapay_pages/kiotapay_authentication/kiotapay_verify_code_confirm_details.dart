import 'dart:async';
import 'dart:convert';

import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:bootstrap_icons/bootstrap_icons.dart';
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

class KiotaPayCodeVerifyConfirmDetails extends StatefulWidget {
  const KiotaPayCodeVerifyConfirmDetails({super.key, required this.data});

  final Map<String, dynamic> data;

  @override
  State<KiotaPayCodeVerifyConfirmDetails> createState() =>
      _KiotaPayCodeVerifyConfirmDetailsState();
}

class _KiotaPayCodeVerifyConfirmDetailsState
    extends State<KiotaPayCodeVerifyConfirmDetails> {
  dynamic size;
  double height = 0.00;
  double width = 0.00;
  final themedata = Get.put(KiotaPayThemecontroler());
  late bool isBioMetricEnabled = false;
  final verifyCodeController = TextEditingController(text: '');
  final Future<SharedPreferences> _prefs = SharedPreferences.getInstance();
  bool _obscureText = true;
  final _formKey = GlobalKey<FormState>();
  var confirmPass;
  late TextEditingController fullNameController =
      TextEditingController(text: widget.data['full_name']);
  late TextEditingController userNameController =
      TextEditingController(text: widget.data['username']);
  late TextEditingController phoneController =
      TextEditingController(text: widget.data['primary_phone']);
  late TextEditingController primaryEmailController =
      TextEditingController(text: widget.data['primary_email']);
  late TextEditingController primaryPhoneController =
      TextEditingController(text: widget.data['primary_phone']);
  late TextEditingController passwordController =
      TextEditingController(text: '');
  late TextEditingController confirmPasswordController =
      TextEditingController(text: '');
  late TextEditingController nationalIdController =
      TextEditingController(text: '');

  @override
  void initState() {
    super.initState();
    isInternetConnected();
    print(widget.data);
  }

  void dispose() {
    super.dispose();
    verifyCodeController.dispose();
  }

  isInternetConnected() async {
    bool isConnected = await checkNetwork();
    if (!isConnected) {
      showSnackBar(context, "No internet connection", Colors.red, 2.00, 2, 10);
      return;
    }
  }
  void _togglePasswordStatus() {
    setState(() {
      _obscureText = !_obscureText;
    });
  }

  Future<void> submitOnboarding() async {
    isInternetConnected();
    showLoading('Working...');
    var headers = {'Content-Type': 'application/json'};
    var body = {
      "code": widget.data['uniqueCode'],
      "phone_number": phoneController.text,
      "full_name": fullNameController.text,
      "username": userNameController.text,
      "national_id": nationalIdController.text,
      "email": primaryEmailController.text,
      "password": passwordController.text,
      "confirm_password": confirmPasswordController.text,
    };
    try {
      var url = Uri.parse(KiotaPayConstants.selfOnboard);
      http.Response response =
          await http.post(url, body: jsonEncode(body), headers: headers);
      print("Response body is: " +
          response.body.toString() +
          " and Code is " +
          response.statusCode.toString());
      if (response.statusCode == 200 || response.statusCode == 201) {
        final json = jsonDecode(response.body);
        var msg = jsonDecode(response.body)['msg'];
        showLoading("Success, redirecting to login...");
        Future.delayed(Duration(seconds: 6), () {
          verifyCodeController.clear();
          Get.to(() => KiotaPaySignIn());
          print(json['data']);
        });
        // hideLoading();
        // awesomeDialog(context, "Success", msg.toString(), true, DialogType.info,
        //     ChanzoColors.primary)
        //   ..show();
        // Navigator.of(context).pop();
      } else {
        var _error =
            jsonDecode(response.body)['message'] ?? "Unknown Error Occurred";
        hideLoading();

        awesomeDialog(context, "Error", _error.toString(), true,
            DialogType.error, ChanzoColors.secondary)
          ..show();
        throw _error ?? "Unknown Error Occured";
      }
    } catch (error) {
      // Get.back();
      // context.loaderOverlay.hide();
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
                child: SingleChildScrollView(
                  reverse: true,
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                        horizontal: width / 36, vertical: height / 36),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          "Confirm Details".tr,
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        Text(
                          "Finish Filling in your details".tr,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SizedBox(
                                height: height / 26,
                              ),
                              Text(
                                "Full_Name".tr,
                                style: pregular_md.copyWith(
                                    color: ChanzoColors.textgrey),
                              ),
                              SizedBox(
                                height: height / 200,
                              ),
                              TextFormField(
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Full Name is required';
                                    }
                                    return null;
                                  },
                                  controller: fullNameController,
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
                                    hintText: 'Enter Unique Code'.tr,
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
                                "Username".tr,
                                style: pregular_md.copyWith(
                                    color: ChanzoColors.textgrey),
                              ),
                              SizedBox(
                                height: height / 200,
                              ),
                              TextFormField(
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Username is required';
                                  }
                                  return null;
                                },
                                controller: userNameController,
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
                                  hintText: 'Enter Username'.tr,
                                  hintStyle: pregular.copyWith(fontSize: 14),
                                  prefixIcon: Padding(
                                      padding: const EdgeInsets.all(14),
                                      child: Icon(
                                        BootstrapIcons.at,
                                        color: ChanzoColors.textgrey,
                                      )),
                                  focusedBorder: UnderlineInputBorder(
                                      borderRadius: BorderRadius.circular(0),
                                      borderSide: const BorderSide(
                                          color: ChanzoColors.primary)),
                                ),
                              ),
                              SizedBox(
                                height: height / 36,
                              ),
                              Text(
                                "Email_Address".tr,
                                style: pregular_md.copyWith(
                                    color: ChanzoColors.textgrey),
                              ),
                              SizedBox(
                                height: height / 200,
                              ),
                              TextFormField(
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Email is required';
                                    }else if(!value.contains("@")) {
                                      return "Please enter valid email";
                                    }
                                    return null;
                                  },
                                  controller: primaryEmailController,
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
                                    hintText: 'Enter Email Address'.tr,
                                    hintStyle: pregular.copyWith(fontSize: 14),
                                    prefixIcon: Padding(
                                        padding: const EdgeInsets.all(14),
                                        child: Image.asset(
                                          KiotaPayPngimage.email,
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
                                "Primary Phone Number".tr,
                                style: pregular_md.copyWith(
                                    color: ChanzoColors.textgrey),
                              ),
                              SizedBox(
                                height: height / 200,
                              ),
                              TextFormField(
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Primary Phone Number is required';
                                    }
                                    return null;
                                  },
                                  controller: primaryPhoneController,
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
                                    hintText: 'Primary Phone'.tr,
                                    hintStyle: pregular.copyWith(fontSize: 14),
                                    prefixIcon: Padding(
                                        padding: const EdgeInsets.all(14),
                                        child: Image.asset(
                                          KiotaPayPngimage.call,
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
                                "National ID/Passport".tr,
                                style: pregular_md.copyWith(
                                    color: ChanzoColors.textgrey),
                              ),
                              SizedBox(
                                height: height / 200,
                              ),
                              TextFormField(
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'National ID/Passport is required';
                                    }
                                    return null;
                                  },
                                  controller: nationalIdController,
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
                                    hintText: 'National ID/Passport'.tr,
                                    hintStyle: pregular.copyWith(fontSize: 14),
                                    prefixIcon: Padding(
                                        padding: const EdgeInsets.all(14),
                                        child: Image.asset(
                                          KiotaPayPngimage.call,
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
                                style: pregular_md.copyWith(
                                    color: ChanzoColors.textgrey),
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
                                      return "Password must be at least 8 characters long";
                                    } else {
                                      return null;
                                    }
                                  },
                                  obscureText: _obscureText,
                                  controller: passwordController,
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
                                    hintText: 'Password'.tr,
                                    hintStyle: pregular.copyWith(fontSize: 14),
                                    prefixIcon: Padding(
                                      padding: const EdgeInsets.all(14),
                                      child: Icon(
                                        BootstrapIcons.key,
                                        color: ChanzoColors.textgrey,
                                      ),
                                    ),
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
                                  )),
                              SizedBox(
                                height: height / 36,
                              ),
                              Text(
                                "Confirm Password".tr,
                                style: pregular_md.copyWith(
                                    color: ChanzoColors.textgrey),
                              ),
                              SizedBox(
                                height: height / 200,
                              ),
                              TextFormField(
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return "Please Re-Enter New Password";
                                    } else if (value.length < 8) {
                                      return "Password must be at least 8 characters long";
                                    } else if (value != confirmPass) {
                                      return "Password and confirm password did not match";
                                    } else {
                                      return null;
                                    }
                                  },
                                  obscureText: _obscureText,
                                  controller: confirmPasswordController,
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
                                    hintText: 'Confirm Password'.tr,
                                    hintStyle: pregular.copyWith(fontSize: 14),
                                    prefixIcon: Padding(
                                      padding: const EdgeInsets.all(14),
                                      child: Icon(
                                        BootstrapIcons.key,
                                        color: ChanzoColors.textgrey,
                                      ),
                                    ),
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
                                  )),
                              SizedBox(
                                height: height / 36,
                              ),

                              InkWell(
                                splashColor: ChanzoColors.transparent,
                                highlightColor: ChanzoColors.transparent,
                                onTap: () async {
                                  if (_formKey.currentState!.validate()) {
                                    submitOnboarding();
                                    print('Verify onboard btn clicked');
                                  }

                                },
                                child: Container(
                                  height: height / 15,
                                  width: width / 1,
                                  decoration: BoxDecoration(
                                      color: ChanzoColors.primary,
                                      borderRadius: BorderRadius.circular(50)),
                                  child: Center(
                                    child: Text("Submit and Finish".tr,
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
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
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
            ),
          ],
        ),
      ),
    );
  }
}
