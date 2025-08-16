import 'package:kiotapay/globalclass/chanzo_color.dart';
import 'package:kiotapay/globalclass/kiotapay_fontstyle.dart';
import 'package:kiotapay/globalclass/kiotapay_icons.dart';
import 'package:kiotapay/kiotapay_pages/kiotapay_mycard/kiotapay_sendmoney.dart';
import 'package:kiotapay/kiotapay_theme/kiotapay_themecontroller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class BankPickMyCards extends StatefulWidget {
  const BankPickMyCards({super.key});

  @override
  State<BankPickMyCards> createState() => _BankPickMyCardsState();
}

class _BankPickMyCardsState extends State<BankPickMyCards> {
  dynamic size;
  double height = 0.00;
  double width = 0.00;
  final themedata = Get.put(KiotaPayThemecontroler());

  List img = [
    KiotaPayPngimage.transaction,
    KiotaPayPngimage.transaction1,
    KiotaPayPngimage.transaction3,
  ];
  List title = [
    "MPESA",
    "Spotify",
    "Grocery",
  ];
  List subtitle = [
    "Business",
    "Music",
    "Shopping",
  ];
  List price = ["- \KSh 5,99", "- \Ksh12,99", "- \Ksh88"];

  RangeValues _currentRangeValues = const RangeValues(40, 80);

  @override
  Widget build(BuildContext context) {
    size = MediaQuery.of(context).size;
    height = size.height;
    width = size.width;
    return Scaffold(
      appBar: AppBar(
        surfaceTintColor:
        Theme.of(context).colorScheme.onSecondaryContainer,
        automaticallyImplyLeading: false,
        centerTitle: true,
        title: Text(
          "My_Account".tr,
          style: pmedium.copyWith(
            fontSize: 18,
          ),
        ),
        actions: [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: width / 36),
            child: InkWell(
              splashColor: ChanzoColors.transparent,
              highlightColor: ChanzoColors.transparent,
              onTap: () {
                Navigator.push(context, MaterialPageRoute(
                  builder: (context) {
                    return const KiotaPaySendMoney2();
                  },
                ));
              },
              child: CircleAvatar(
                radius: 18,
                backgroundColor:Theme.of(context).colorScheme.secondaryContainer,
                child: Icon(
                  Icons.add,
                  size: height / 36,
                ),
              ),
            ),
          )
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.symmetric(
              horizontal: width / 36, vertical: height / 36),
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
                height: height / 36,
              ),
              ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemBuilder: (context, index) {
                    return Row(
                      children: [
                        CircleAvatar(
                          radius: 22,
                          backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
                          child: Image.asset(
                            img[index],
                            height: height / 36,
                          ),
                        ),
                        SizedBox(
                          width: width / 36,
                        ),
                        Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title[index],
                              style: pmedium.copyWith(
                                fontSize: 16,
                              ),
                            ),
                            Text(
                              subtitle[index],
                              style: pregular.copyWith(
                                  fontSize: 12, color: ChanzoColors.textgrey),
                            ),
                          ],
                        ),
                        const Spacer(),
                        Text(
                          price[index],
                          style: pmedium.copyWith(
                            fontSize: 16,
                          ),
                        ),
                      ],
                    );
                  },
                  separatorBuilder: (context, index) {
                    return SizedBox(
                      height: height / 46,
                    );
                  },
                  itemCount: img.length),
              SizedBox(
                height: height / 36,
              ),
              Text(
                "Monthly spending limit".tr,
                style: pmedium.copyWith(
                  fontSize: 18,
                ),
              ),
              SizedBox(
                height: height / 56,
              ),
              Container(
                width: width / 1,
                decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    color: Theme.of(context).colorScheme.secondaryContainer),
                child: Padding(
                  padding: EdgeInsets.symmetric(
                      horizontal: width / 36, vertical: height / 56),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Amount: \Ksh8,545.00",
                        style: pregular.copyWith(
                          fontSize: 13,
                        ),
                      ),
                      RangeSlider(
                        values: _currentRangeValues,
                        max: 100,
                        activeColor: ChanzoColors.primary,
                        inactiveColor: ChanzoColors.lightPrimary,
                        labels: RangeLabels(
                          _currentRangeValues.start.round().toString(),
                          _currentRangeValues.end.round().toString(),
                        ),
                        onChanged: (RangeValues values) {
                          setState(() {
                            _currentRangeValues = values;
                          });
                        },
                      )
                    ],
                  ),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
