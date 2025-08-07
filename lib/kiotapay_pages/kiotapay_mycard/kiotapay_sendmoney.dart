import 'package:kiotapay/globalclass/chanzo_color.dart';
import 'package:kiotapay/globalclass/kiotapay_fontstyle.dart';
import 'package:kiotapay/globalclass/kiotapay_icons.dart';
import 'package:kiotapay/kiotapay_pages/kiotapay_mycard/kiotapay_requestmoney.dart';
import 'package:kiotapay/kiotapay_theme/kiotapay_themecontroller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class KiotaPaySendMoney2 extends StatefulWidget {
  const KiotaPaySendMoney2({super.key});

  @override
  State<KiotaPaySendMoney2> createState() => _KiotaPaySendMoney2State();
}

class _KiotaPaySendMoney2State extends State<KiotaPaySendMoney2> {
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
          "Send_Money".tr,
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
            SizedBox(
              height: height / 4,
              child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemBuilder: (context, index) {
                    return Image.asset(
                      KiotaPayPngimage.card,
                      width: width / 1.2,
                      height: height / 4,
                      fit: BoxFit.fill,
                    );
                  },
                  separatorBuilder: (context, index) {
                    return SizedBox(
                      width: width / 36,
                    );
                  },
                  itemCount: 3),
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
                padding: EdgeInsets.symmetric(
                    horizontal: width / 36, vertical: height / 56),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Send to".tr,
                      style: pregular.copyWith(
                        fontSize: 14,
                      ),
                    ),
                    SizedBox(
                      height: height / 96,
                    ),
                    Image.asset(
                      KiotaPayPngimage.addcircle,
                      height: height / 16,
                    ),
                    SizedBox(
                      height: height / 200,
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "Add",
                          style: pregular.copyWith(
                            fontSize: 11,
                          ),
                        ),
                        Text(
                          "Yamilet",
                          style: pregular.copyWith(
                            fontSize: 11,
                          ),
                        ),
                        Text(
                          "Alexa",
                          style: pregular.copyWith(
                            fontSize: 11,
                          ),
                        ),
                        Text(
                          "Yakub",
                          style: pregular.copyWith(
                            fontSize: 11,
                          ),
                        ),
                        Text(
                          "Krishna",
                          style: pregular.copyWith(
                            fontSize: 11,
                          ),
                        ),
                      ],
                    )
                  ],
                ),
              ),
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
                                hintText: '36.00'.tr,
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
            InkWell(
              splashColor: ChanzoColors.transparent,
              highlightColor: ChanzoColors.transparent,
              onTap: () {
                Navigator.push(context, MaterialPageRoute(
                  builder: (context) {
                    return const BankPickRequestMoney();
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
                  child: Text("Send_Money".tr,
                      style: psemibold.copyWith(
                          fontSize: 14, color: ChanzoColors.white)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
