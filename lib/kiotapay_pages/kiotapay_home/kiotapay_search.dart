import 'package:kiotapay/globalclass/chanzo_color.dart';
import 'package:kiotapay/globalclass/kiotapay_fontstyle.dart';
import 'package:kiotapay/globalclass/kiotapay_icons.dart';
import 'package:kiotapay/kiotapay_theme/kiotapay_themecontroller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class BankPickSearch extends StatefulWidget {
  const BankPickSearch({super.key});

  @override
  State<BankPickSearch> createState() => _BankPickSearchState();
}

class _BankPickSearchState extends State<BankPickSearch> {
  dynamic size;
  double height = 0.00;
  double width = 0.00;
  final themedata = Get.put(KiotaPayThemecontroler());

  List img = [
    KiotaPayPngimage.transaction,
    KiotaPayPngimage.transaction1,
    KiotaPayPngimage.transaction2,
    KiotaPayPngimage.transaction3,
    KiotaPayPngimage.transaction4,
    KiotaPayPngimage.transaction2,
    KiotaPayPngimage.transaction,
    KiotaPayPngimage.transaction1,
  ];
  List title = [
    "Apple Store",
    "Spotify",
    "Money Transfer",
    "Grocery",
    "Apple Store",
    "Money Transfer",
    "Apple Store",
    "Spotify",
  ];
  List subtitle = [
    "Entertainment",
    "Music",
    "Transaction",
    "Shopping",
    "Entertainment",
    "Transaction",
    "Entertainment",
    "Music",
  ];
  List price = ["- \$5,99", "- \$12,99", "\$300", "- \$88", "- \$5,99", "\$300", "- \$5,99", "- \$12,99"];

  @override
  Widget build(BuildContext context) {
    size = MediaQuery.of(context).size;
    height = size.height;
    width = size.width;
    return Scaffold(
      appBar: AppBar(
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
              backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
              child: Icon(
                Icons.chevron_left,
                size: 22,
                color: Theme.of(context).colorScheme.onSecondaryContainer,
              ),
            )
          ),
        ),
        centerTitle: true,
        title: Text(
          "Search".tr,
          style: pmedium.copyWith(
            fontSize: 18,
          ),
        ),
        actions: [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: width / 36),
            child: CircleAvatar(
              radius: 18,
              backgroundColor:Theme.of(context).colorScheme.secondaryContainer,
              child: Icon(
                Icons.close,
                size: height / 40,
              ),
            ),
          )
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: width/36, vertical: height/36),
          child: Column(
            children: [
              TextFormField(
                  scrollPadding: EdgeInsets.only(
                      bottom: MediaQuery
                          .of(context)
                          .viewInsets
                          .bottom),
                  style: pregular.copyWith(fontSize: 14),
                  decoration: InputDecoration(
                    hintText: 'Search'.tr,
                    fillColor: Theme.of(context).colorScheme.secondaryContainer,
                    prefixIcon: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Image.asset(
                        KiotaPayPngimage.search,
                        height: height / 36,
                        color: Theme.of(context).colorScheme.secondaryContainer,
                      ),
                    ),
                    suffixIcon: Icon(
                      Icons.close,
                      size: height / 40,
                    ),
                    filled: true,
                    hintStyle: pregular.copyWith(fontSize: 14),
                    enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide.none),
                    focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide.none),
                  )),
              SizedBox(height: height / 36,),
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
            ],
          ),
        ),
      ),
    );
  }
}
