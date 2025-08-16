import 'package:kiotapay/globalclass/chanzo_color.dart';
import 'package:kiotapay/globalclass/kiotapay_fontstyle.dart';
import 'package:kiotapay/globalclass/kiotapay_icons.dart';
import 'package:kiotapay/kiotapay_theme/kiotapay_themecontroller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class BankPickAddNewCard extends StatefulWidget {
  const BankPickAddNewCard({super.key});

  @override
  State<BankPickAddNewCard> createState() => _BankPickAddNewCardState();
}

class _BankPickAddNewCardState extends State<BankPickAddNewCard> {
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
              radius: 18,
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
          "Add_New_Card".tr,
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
            Image.asset(
              KiotaPayPngimage.card,
              width: width / 1,
              height: height / 4,
              fit: BoxFit.fill,
            ),
            SizedBox(
              height: height / 26,
            ),
            Text(
              "Cardholder_Name".tr,
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
                  hintText: 'Enter_Cardholder_Name'.tr,
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
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Expiry_Date".tr,
                      style: pregular.copyWith(
                          fontSize: 14, color: ChanzoColors.textgrey),
                    ),
                    SizedBox(
                      height: height / 200,
                    ),
                    SizedBox(
                      width: width/2.2,
                      child: TextFormField(
                          scrollPadding: EdgeInsets.only(
                              bottom: MediaQuery.of(context).viewInsets.bottom),
                          style: pregular.copyWith(fontSize: 14),
                          decoration: InputDecoration(
                            hintText: 'Date'.tr,
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
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "4-digit CVV".tr,
                      style: pregular.copyWith(
                          fontSize: 14, color: ChanzoColors.textgrey),
                    ),
                    SizedBox(
                      height: height / 200,
                    ),
                    SizedBox(
                      width: width/2.2,
                      child: TextFormField(
                          scrollPadding: EdgeInsets.only(
                              bottom: MediaQuery.of(context).viewInsets.bottom),
                          style: pregular.copyWith(fontSize: 14),
                          decoration: InputDecoration(
                            hintText: 'CVV'.tr,
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
                    ),
                  ],
                )
              ],
            ),
            SizedBox(
              height: height / 36,
            ),
            Text(
              "Card_Number".tr,
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
                  hintText: 'Enter_Card_Number'.tr,
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
          ],
        ),
      ),
    );
  }
}
