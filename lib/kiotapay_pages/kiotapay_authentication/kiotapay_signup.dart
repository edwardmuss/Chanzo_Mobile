import 'package:kiotapay/globalclass/chanzo_color.dart';
import 'package:kiotapay/globalclass/kiotapay_fontstyle.dart';
import 'package:kiotapay/globalclass/kiotapay_icons.dart';
import 'package:kiotapay/kiotapay_pages/kiotapay_authentication/kiotapay_signin.dart';
import 'package:kiotapay/kiotapay_pages/kiotapay_dahsboard/kiotapay_dahsboard.dart';
import 'package:kiotapay/kiotapay_theme/kiotapay_themecontroller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class BankPickSignUp extends StatefulWidget {
  const BankPickSignUp({super.key});

  @override
  State<BankPickSignUp> createState() => _BankPickSignUpState();
}

class _BankPickSignUpState extends State<BankPickSignUp> {
  dynamic size;
  double height = 0.00;
  double width = 0.00;
  final themedata = Get.put(KiotaPayThemecontroler());

  bool _obscureText = true;

  void _togglePasswordStatus() {
    setState(() {
      _obscureText = !_obscureText;
    });
  }

  @override
  Widget build(BuildContext context) {
    size = MediaQuery.of(context).size;
    height = size.height;
    width = size.width;
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: Padding(
        padding:
        EdgeInsets.symmetric(horizontal: width / 36, vertical: height / 36),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: height / 10,
            ),
            Text(
              "Sign_Up".tr,
              style: pmedium.copyWith(fontSize: 32),
            ),
            SizedBox(
              height: height / 26,
            ),
            Text(
              "Full_Name".tr,
              style: pregular.copyWith(
                  fontSize: 14, color: ChanzoColors.textgrey),
            ),
            SizedBox(
              height: height / 200,
            ),
            TextFormField(
                scrollPadding: EdgeInsets.only(
                    bottom: MediaQuery.of(context).viewInsets.bottom),
                style: pregular.copyWith(fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'Enter_Full_Name'.tr,
                  hintStyle: pregular.copyWith(fontSize: 14),
                  prefixIcon: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Image.asset(
                        KiotaPayPngimage.profile,
                        height: height / 36,
                        color: ChanzoColors.textgrey,
                      )),
                  enabledBorder: UnderlineInputBorder(
                      borderRadius: BorderRadius.circular(0),
                      borderSide:
                      const BorderSide(color: ChanzoColors.textfield)),
                  focusedBorder: UnderlineInputBorder(
                      borderRadius: BorderRadius.circular(0),
                      borderSide:
                      const BorderSide(color: ChanzoColors.primary)),
                )),
            SizedBox(
              height: height / 36,
            ),
            Text(
              "Phone_Number".tr,
              style: pregular.copyWith(
                  fontSize: 14, color: ChanzoColors.textgrey),
            ),
            SizedBox(
              height: height / 200,
            ),
            TextFormField(
                scrollPadding: EdgeInsets.only(
                    bottom: MediaQuery.of(context).viewInsets.bottom),
                style: pregular.copyWith(fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'Enter_Phone_Number'.tr,
                  hintStyle: pregular.copyWith(fontSize: 14),
                  prefixIcon: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Image.asset(
                        KiotaPayPngimage.call,
                        height: height / 36,
                        color: ChanzoColors.textgrey,
                      )),
                  enabledBorder: UnderlineInputBorder(
                      borderRadius: BorderRadius.circular(0),
                      borderSide:
                      const BorderSide(color: ChanzoColors.textfield)),
                  focusedBorder: UnderlineInputBorder(
                      borderRadius: BorderRadius.circular(0),
                      borderSide:
                      const BorderSide(color: ChanzoColors.primary)),
                )),
            SizedBox(
              height: height / 36,
            ),
            Text(
              "Email_Address".tr,
              style: pregular.copyWith(
                  fontSize: 14, color: ChanzoColors.textgrey),
            ),
            SizedBox(
              height: height / 200,
            ),
            TextFormField(
                scrollPadding: EdgeInsets.only(
                    bottom: MediaQuery.of(context).viewInsets.bottom),
                style: pregular.copyWith(fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'Enter_Email_Address'.tr,
                  hintStyle: pregular.copyWith(fontSize: 14),
                  prefixIcon: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Image.asset(
                        KiotaPayPngimage.email,
                        height: height / 36,
                        color: ChanzoColors.textgrey,
                      )),
                  enabledBorder: UnderlineInputBorder(
                      borderRadius: BorderRadius.circular(0),
                      borderSide:
                      const BorderSide(color: ChanzoColors.textfield)),
                  focusedBorder: UnderlineInputBorder(
                      borderRadius: BorderRadius.circular(0),
                      borderSide:
                      const BorderSide(color: ChanzoColors.primary)),
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
                obscureText: _obscureText,
                scrollPadding: EdgeInsets.only(
                    bottom: MediaQuery.of(context).viewInsets.bottom),
                style: pregular.copyWith(fontSize: 14),
                decoration: InputDecoration(
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
                  enabledBorder: UnderlineInputBorder(
                      borderRadius: BorderRadius.circular(0),
                      borderSide:
                      const BorderSide(color: ChanzoColors.textfield)),
                  focusedBorder: UnderlineInputBorder(
                      borderRadius: BorderRadius.circular(0),
                      borderSide:
                      const BorderSide(color: ChanzoColors.primary)),
                )),
            SizedBox(
              height: height / 16,
            ),
            InkWell(
              splashColor: ChanzoColors.transparent,
              highlightColor: ChanzoColors.transparent,
              onTap: () {
                Navigator.push(context, MaterialPageRoute(
                  builder: (context) {
                    return KiotaPayDashboard("0");
                  },
                ));
              },
              child: Container(
                height: height / 15,
                width: width / 1,
                decoration: BoxDecoration(
                    color: ChanzoColors.primary,
                    borderRadius: BorderRadius.circular(10)),
                child: Center(
                  child: Text("Sign_Up".tr,
                      style: psemibold.copyWith(
                          fontSize: 14, color: ChanzoColors.white)),
                ),
              ),
            ),
            SizedBox(
              height: height / 36,
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text("Already_have_an_account".tr,
                    style: pregular.copyWith(
                        fontSize: 14, color: ChanzoColors.textgrey)),
                SizedBox(
                  width: width / 96,
                ),
                InkWell(
                  splashColor: ChanzoColors.transparent,
                  highlightColor: ChanzoColors.transparent,
                  onTap: () {
                    Navigator.push(context, MaterialPageRoute(
                      builder: (context) {
                        return const KiotaPaySignIn();
                      },
                    ));
                  },
                  child: Text("Sign_In".tr,
                      style: pmedium.copyWith(
                          fontSize: 14, color: ChanzoColors.primary)),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}
