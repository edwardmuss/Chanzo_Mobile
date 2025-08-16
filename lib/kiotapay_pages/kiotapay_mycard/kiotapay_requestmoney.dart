import 'package:kiotapay/globalclass/chanzo_color.dart';
import 'package:kiotapay/globalclass/kiotapay_fontstyle.dart';
import 'package:kiotapay/globalclass/kiotapay_icons.dart';
import 'package:kiotapay/kiotapay_theme/kiotapay_themecontroller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class BankPickRequestMoney extends StatefulWidget {
  const BankPickRequestMoney({super.key});

  @override
  State<BankPickRequestMoney> createState() => _BankPickRequestMoneyState();
}

class _BankPickRequestMoneyState extends State<BankPickRequestMoney> {
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
        surfaceTintColor:Theme.of(context).colorScheme.onSecondaryContainer,
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
              backgroundColor:Theme.of(context).colorScheme.secondaryContainer,
              child: Icon(
                Icons.chevron_left,
                size: height / 36,
              ),
            ),
          ),
        ),
        centerTitle: true,
        title: Text(
          "Request_Money".tr,
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
              "Payer_Name".tr,
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
                  hintText: 'Enter_Payer_Name'.tr,
                  hintStyle: pregular.copyWith(fontSize: 14),
                  prefixIcon: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Image.asset(
                        KiotaPayPngimage.userprofile,
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
              "Description".tr,
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
                  hintText: 'Enter_Description'.tr,
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
              "Monthly_Due_By".tr,
              style: pregular.copyWith(
                  fontSize: 14, color: ChanzoColors.textgrey),
            ),
            SizedBox(
              height: height / 200,
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                SizedBox(
                  width: width / 3.5,
                  child: TextFormField(
                      scrollPadding: EdgeInsets.only(
                          bottom: MediaQuery.of(context).viewInsets.bottom),
                      style: pregular.copyWith(fontSize: 14),
                      textAlign: TextAlign.center,
                      decoration: InputDecoration(
                        hintText: 'Date'.tr,
                        hintStyle: pregular.copyWith(fontSize: 14),
                        enabledBorder: UnderlineInputBorder(
                            borderRadius: BorderRadius.circular(0),
                            borderSide: const BorderSide(
                                color: ChanzoColors.textfield)),
                        focusedBorder: UnderlineInputBorder(
                            borderRadius: BorderRadius.circular(0),
                            borderSide:
                            const BorderSide(color: ChanzoColors.primary)),
                      )),
                ),
                SizedBox(
                  width: width / 3.5,
                  child: TextFormField(
                      scrollPadding: EdgeInsets.only(
                          bottom: MediaQuery.of(context).viewInsets.bottom),
                      style: pregular.copyWith(fontSize: 14),
                      textAlign: TextAlign.center,
                      decoration: InputDecoration(
                        hintText: 'Month'.tr,
                        hintStyle: pregular.copyWith(fontSize: 14),
                        enabledBorder: UnderlineInputBorder(
                            borderRadius: BorderRadius.circular(0),
                            borderSide: const BorderSide(
                                color: ChanzoColors.textfield)),
                        focusedBorder: UnderlineInputBorder(
                            borderRadius: BorderRadius.circular(0),
                            borderSide:
                            const BorderSide(color: ChanzoColors.primary)),
                      )),
                ),
                SizedBox(
                  width: width / 3.5,
                  child: TextFormField(
                      scrollPadding: EdgeInsets.only(
                          bottom: MediaQuery.of(context).viewInsets.bottom),
                      style: pregular.copyWith(fontSize: 14),
                      textAlign: TextAlign.center,
                      decoration: InputDecoration(
                        hintText: 'Year'.tr,
                        hintStyle: pregular.copyWith(fontSize: 14),
                        enabledBorder: UnderlineInputBorder(
                            borderRadius: BorderRadius.circular(0),
                            borderSide: const BorderSide(
                                color: ChanzoColors.textfield)),
                        focusedBorder: UnderlineInputBorder(
                            borderRadius: BorderRadius.circular(0),
                            borderSide:
                            const BorderSide(color: ChanzoColors.primary)),
                      )),
                ),
              ],
            ),
            SizedBox(
              height: height / 36,
            ),
            Container(
              width: width / 1,
              decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                      color: Theme.of(context).colorScheme.secondaryContainer)),
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: width / 36),
                child: Column(
                  children: [
                    SizedBox(
                      height: height / 56,
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "Enter Your Amount",
                          style: pregular.copyWith(
                            fontSize: 11,
                          ),
                        ),
                        Text(
                          "Change Currency?",
                          style: pregular.copyWith(
                              fontSize: 11, color: Colors.red),
                        ),
                      ],
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "USD",
                          style: psemibold.copyWith(
                              fontSize: 24, color: ChanzoColors.textgrey),
                        ),
                        SizedBox(
                          width: width / 1.4,
                          child: TextFormField(
                              scrollPadding: EdgeInsets.only(
                                  bottom:
                                  MediaQuery.of(context).viewInsets.bottom),
                              style: psemibold.copyWith(
                                fontSize: 24,
                              ),
                              decoration: InputDecoration(
                                hintText: '26.00.00'.tr,
                                hintStyle: psemibold.copyWith(
                                    fontSize: 24,
                                    color: Theme.of(context).colorScheme.secondaryContainer),
                                enabledBorder: UnderlineInputBorder(
                                    borderRadius: BorderRadius.circular(0),
                                    borderSide: BorderSide.none),
                                focusedBorder: UnderlineInputBorder(
                                    borderRadius: BorderRadius.circular(0),
                                    borderSide: BorderSide.none),
                              )),
                        ),
                      ],
                    )
                  ],
                ),
              ),
            ),
            const Spacer(),
            Container(
              height: height / 15,
              width: width / 1,
              decoration: BoxDecoration(
                  color: ChanzoColors.primary,
                  borderRadius: BorderRadius.circular(10)),
              child: Center(
                child: Text("Send_Money".tr,
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
