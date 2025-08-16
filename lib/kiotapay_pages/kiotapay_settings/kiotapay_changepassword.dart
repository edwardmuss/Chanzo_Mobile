import 'package:kiotapay/globalclass/chanzo_color.dart';
import 'package:kiotapay/globalclass/kiotapay_fontstyle.dart';
import 'package:kiotapay/globalclass/kiotapay_icons.dart';
import 'package:kiotapay/kiotapay_theme/kiotapay_themecontroller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class BankPickChangePassword extends StatefulWidget {
  const BankPickChangePassword({super.key});

  @override
  State<BankPickChangePassword> createState() => _BankPickChangePasswordState();
}

class _BankPickChangePasswordState extends State<BankPickChangePassword> {
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

  bool _obscureText1 = true;

  void _togglePasswordStatus1() {
    setState(() {
      _obscureText1 = !_obscureText1;
    });
  }

  bool _obscureText2 = true;

  void _togglePasswordStatus2() {
    setState(() {
      _obscureText2 = !_obscureText2;
    });
  }

  @override
  Widget build(BuildContext context) {
    size = MediaQuery
        .of(context)
        .size;
    height = size.height;
    width = size.width;
    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        surfaceTintColor:
        Theme.of(context).colorScheme.onSecondaryContainer,
        leading: Padding(
          padding: EdgeInsets.symmetric(horizontal: width / 36),
          child: InkWell(
            splashColor: ChanzoColors.transparent,
            highlightColor: ChanzoColors.transparent,
            onTap: () {
              Navigator.pop(context);
            },
            child: CircleAvatar(
              radius: 22,
              backgroundColor:
              Theme.of(context).colorScheme.secondaryContainer,
              child: Icon(
                Icons.chevron_left,
                size: height / 36,
              ),
            ),
          ),
        ),
        centerTitle: true,
        title: Text(
          "Change_Password".tr,
          style: pmedium.copyWith(
            fontSize: 18,
          ),
        ),
      ),
      body: Padding(
        padding: EdgeInsets.symmetric(horizontal: width/36, vertical: height/36),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Current_Password".tr,
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
                  hintText: 'Enter_Current_Password'.tr,
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
              height: height / 36,
            ),
            Text(
              "New_Password".tr,
              style: pregular.copyWith(
                  fontSize: 14, color: ChanzoColors.textgrey),
            ),
            SizedBox(
              height: height / 200,
            ),
            TextFormField(
                obscureText: _obscureText1,
                scrollPadding: EdgeInsets.only(
                    bottom: MediaQuery.of(context).viewInsets.bottom),
                style: pregular.copyWith(fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'Enter_New_Password'.tr,
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
                      _obscureText1
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                      size: height / 36,
                      color: ChanzoColors.textgrey,
                    ),
                    onPressed: _togglePasswordStatus1,
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
              height: height / 36,
            ),
            Text(
              "Confirm_New_Password".tr,
              style: pregular.copyWith(
                  fontSize: 14, color: ChanzoColors.textgrey),
            ),
            SizedBox(
              height: height / 200,
            ),
            TextFormField(
                obscureText: _obscureText2,
                scrollPadding: EdgeInsets.only(
                    bottom: MediaQuery.of(context).viewInsets.bottom),
                style: pregular.copyWith(fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'Enter_New_Confirm_Password'.tr,
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
                      _obscureText2
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                      size: height / 36,
                      color: ChanzoColors.textgrey,
                    ),
                    onPressed: _togglePasswordStatus2,
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
            Container(
              height: height / 15,
              width: width / 1,
              decoration: BoxDecoration(
                  color: ChanzoColors.primary,
                  borderRadius: BorderRadius.circular(10)),
              child: Center(
                child: Text("Change_Password".tr,
                    style: psemibold.copyWith(
                        fontSize: 14, color: ChanzoColors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
