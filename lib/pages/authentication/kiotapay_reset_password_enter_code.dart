import 'dart:async';
import 'dart:convert';

import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:chanzo/globalclass/global_methods.dart';
import 'package:chanzo/globalclass/chanzo_color.dart';
import 'package:chanzo/globalclass/fontstyle.dart';
import 'package:chanzo/globalclass/global_classes.dart';
import 'package:chanzo/globalclass/kiotapay_icons.dart';
import 'package:chanzo/pages/authentication/kiotapay_reset_password_validate.dart';
import 'package:chanzo/pages/authentication/sign_in.dart';
import 'package:chanzo/theme/theme_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class KiotaPayResetPasswordEnterCode extends StatefulWidget {
  const KiotaPayResetPasswordEnterCode({super.key, required this.username});

  final String username;

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
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    isLoginedIn();
    isInternetConnected();
  }

  @override
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

  void proceedToResetPassword() {
    if (_formKey.currentState!.validate()) {
      Get.to(() => KiotaPayResetPasswordValidate(
        username: widget.username,
        otp: otpCodeController.text.trim(),
      ));
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
            const SizedBox(height: 80),
            SizedBox(height: height / 8),
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: themedata.isdark == false
                      ? ChanzoColors.bgcolor
                      : ChanzoColors.bgdark,
                  borderRadius: const BorderRadius.only(
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
                        "Enter the OTP sent to your phone or email".tr,
                        style: Theme.of(context).textTheme.bodyMedium,
                        textAlign: TextAlign.center,
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
                            SizedBox(height: height / 200),
                            // 🔥 Autofill Group to capture SMS natively
                            AutofillGroup(
                              child: TextFormField(
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'One Time Password (OTP) is required';
                                  }
                                  if (value.length < 4) {
                                    return 'Please enter a valid OTP';
                                  }
                                  return null;
                                },
                                controller: otpCodeController,
                                keyboardType: TextInputType.number,
                                // This single line tells iOS/Android to suggest codes from SMS
                                autofillHints: const [AutofillHints.oneTimeCode],
                                scrollPadding: EdgeInsets.only(
                                    bottom: MediaQuery.of(context).viewInsets.bottom),
                                style: pregular.copyWith(fontSize: 14),
                                decoration: InputDecoration(
                                  contentPadding: const EdgeInsets.all(8.0),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(50),
                                  ),
                                  hintText: 'Enter 6-digit OTP'.tr,
                                  hintStyle: pregular.copyWith(fontSize: 14),
                                  prefixIcon: Padding(
                                    padding: const EdgeInsets.all(14),
                                    child: Image.asset(
                                      KiotaPayPngimage.lock, // Used a lock icon instead of user profile
                                      height: height / 36,
                                      color: ChanzoColors.textgrey,
                                    ),
                                  ),
                                  focusedBorder: UnderlineInputBorder(
                                    borderRadius: BorderRadius.circular(0),
                                    borderSide: const BorderSide(
                                        color: ChanzoColors.primary),
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(height: height / 36),
                            const SizedBox(height: 30),
                            InkWell(
                              splashColor: ChanzoColors.transparent,
                              highlightColor: ChanzoColors.transparent,
                              onTap: proceedToResetPassword,
                              child: Container(
                                height: height / 15,
                                width: width / 1,
                                decoration: BoxDecoration(
                                    color: ChanzoColors.primary,
                                    borderRadius: BorderRadius.circular(50)),
                                child: Center(
                                  child: Text("Verify OTP".tr,
                                      style: pbold_md.copyWith(
                                          color: ChanzoColors.white)),
                                ),
                              ),
                            ),
                            SizedBox(height: height / 36),
                            Row(children: const <Widget>[
                              Expanded(child: Divider()),
                              Text(" OR "),
                              Expanded(child: Divider()),
                            ]),
                            SizedBox(height: height / 36),
                            InkWell(
                              splashColor: ChanzoColors.transparent,
                              highlightColor: ChanzoColors.transparent,
                              onTap: () {
                                Get.offAll(() => const SignIn());
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
                                      const Icon(
                                        Icons.arrow_back,
                                        color: ChanzoColors.primary,
                                        size: 24.0,
                                      ),
                                      SizedBox(width: width / 96),
                                      Text("Back to Login".tr,
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