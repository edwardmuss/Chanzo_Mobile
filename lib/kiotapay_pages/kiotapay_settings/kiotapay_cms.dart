import 'package:kiotapay/globalclass/chanzo_color.dart';
import 'package:kiotapay/globalclass/kiotapay_fontstyle.dart';
import 'package:kiotapay/kiotapay_theme/kiotapay_themecontroller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

// ignore: must_be_immutable
class BankPickCms extends StatefulWidget {
  String? type;

  BankPickCms(this.type, {super.key});

  @override
  State<BankPickCms> createState() => _KidsCmsState();
}

class _KidsCmsState extends State<BankPickCms> {
  dynamic size;
  double height = 0.00;
  double width = 0.00;
  final themedata = Get.put(KiotaPayThemecontroler());

  @override
  Widget build(BuildContext context) {
    size = MediaQuery.of(context).size;
    height = size.height;
    width = size.width;
    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        surfaceTintColor: Theme.of(context).colorScheme.onSecondaryContainer,
        leading: Padding(
          padding: EdgeInsets.symmetric(horizontal: width / 36),
          child: InkWell(
            splashColor: ChanzoColors.transparent,
            highlightColor: ChanzoColors.transparent,
            onTap: () {
              Navigator.pop(context);
            },
            child: CircleAvatar(
              radius: 18,
              backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
              child: Icon(
                Icons.chevron_left,
                size: height / 36,
              ),
            ),
          ),
        ),
        centerTitle: true,
        title: Text(
          widget.type == "privacy"
              ? "Privacy_Policy".tr
              : widget.type == "terms"
                  ? "Terms_Condition".tr
                  : "About_Us".tr,
          style: pmedium.copyWith(
            fontSize: 18,
          ),
        ),
      ),
      body: Padding(
        padding:
            EdgeInsets.symmetric(horizontal: width / 36, vertical: height / 36),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Last update: 05/02/2024".tr,
              style:
                  psemibold.copyWith(fontSize: 12, color: ChanzoColors.grey),
            ),
            SizedBox(
              height: height / 96,
            ),
            Text(
              widget.type == "privacy"
                  ? "Please read these privacy policy, carefully before using our app operated by us."
                  : widget.type == "terms"
                      ? "Please read these terms of service, carefully before using our app operated by us."
                      : "Please read these about us, carefully before using our app operated by us.",
              style: psemibold.copyWith(
                fontSize: 14,
              ),
            ),
            SizedBox(
              height: height / 56,
            ),
            Text(
              widget.type == "privacy"
                  ? "Privacy Policy"
                  : widget.type == "terms"
                      ? "Conditions of Uses"
                      : "About Us",
              style: psemibold.copyWith(
                  fontSize: 16, color: ChanzoColors.primary),
            ),
            SizedBox(
              height: height / 96,
            ),
            Text(
              widget.type == "privacy"
                  ? "Chanzo Privacy Policy."
                  : widget.type == "terms"
                      ? "Chanzo Terms"
                      : "Chanzo Other",
              style: pregular.copyWith(fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }
}
