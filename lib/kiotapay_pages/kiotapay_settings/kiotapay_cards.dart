import 'package:kiotapay/globalclass/chanzo_color.dart';
import 'package:kiotapay/globalclass/kiotapay_fontstyle.dart';
import 'package:kiotapay/globalclass/kiotapay_icons.dart';
import 'package:kiotapay/kiotapay_pages/kiotapay_settings/kiotapay_addnewcard.dart';
import 'package:kiotapay/kiotapay_theme/kiotapay_themecontroller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class BankPickCards extends StatefulWidget {
  const BankPickCards({super.key});

  @override
  State<BankPickCards> createState() => _BankPickCardsState();
}

class _BankPickCardsState extends State<BankPickCards> {
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
          "All_Cards".tr,
          style: pmedium.copyWith(
            fontSize: 18,
          ),
        ),
      ),
      body: Padding(
        padding:
            EdgeInsets.symmetric(horizontal: width / 36, vertical: height / 36),
        child: Column(
          children: [
            ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemBuilder: (context, index) {
                  return Image.asset(
                    KiotaPayPngimage.card,
                    width: width / 1,
                    height: height / 4,
                    fit: BoxFit.fill,
                  );
                },
                separatorBuilder: (context, index) {
                  return SizedBox(
                    height: height / 56,
                  );
                },
                itemCount: 2),
            const Spacer(),
            InkWell(
              splashColor: ChanzoColors.transparent,
              highlightColor: ChanzoColors.transparent,
              onTap: () {
                Navigator.push(context, MaterialPageRoute(
                  builder: (context) {
                    return const BankPickAddNewCard();
                  },
                ));
              },
              child: Container(
                height: height / 15,
                width: width / 1,
                decoration: BoxDecoration(
                    color: ChanzoColors.primary,
                    borderRadius: BorderRadius.circular(10)),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text("Add_Card".tr,
                        style: psemibold.copyWith(
                            fontSize: 14, color: ChanzoColors.white)),
                    SizedBox(
                      width: width / 56,
                    ),
                    Icon(
                      Icons.add,
                      size: height / 36,
                      color: ChanzoColors.white,
                    )
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
