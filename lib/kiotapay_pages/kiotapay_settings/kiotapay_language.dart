import 'package:kiotapay/globalclass/chanzo_color.dart';
import 'package:kiotapay/globalclass/kiotapay_fontstyle.dart';
import 'package:kiotapay/globalclass/kiotapay_icons.dart';
import 'package:kiotapay/kiotapay_theme/kiotapay_themecontroller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class BankPickLanguage extends StatefulWidget {
  const BankPickLanguage({super.key});

  @override
  State<BankPickLanguage> createState() => _BankPickLanguageState();
}

class _BankPickLanguageState extends State<BankPickLanguage> {
  dynamic size;
  double height = 0.00;
  double width = 0.00;
  final themedata = Get.put(KiotaPayThemecontroler());

  List img = [
    KiotaPayPngimage.language,
    KiotaPayPngimage.language1,
    KiotaPayPngimage.language2,
    KiotaPayPngimage.language3,
    KiotaPayPngimage.language4,
    KiotaPayPngimage.language5
  ];
  List title = [
    "English",
    "Australia",
    "Franch",
    "Spanish",
    "America",
    "Vietnam"
  ];
  int selected = 0;

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
          "Language".tr,
          style: pregular.copyWith(
            fontSize: 18,
          ),
        ),
      ),
      body: Padding(
        padding: EdgeInsets.symmetric(
            horizontal: width / 36, vertical: height / 36),
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
                  hintText: 'Search Language'.tr,
                  fillColor: Theme.of(context).colorScheme.secondaryContainer,
                  prefixIcon: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Image.asset(
                      KiotaPayPngimage.search,
                      height: height / 36,
                      color: Theme.of(context).colorScheme.secondaryContainer,
                    ),
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
                  return InkWell(
                    splashColor: ChanzoColors.transparent,
                    highlightColor: ChanzoColors.transparent,
                    onTap: () {
                      setState(() {
                        selected = index;
                      });
                    },
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 22,
                          backgroundColor: ChanzoColors.transparent,
                          backgroundImage: AssetImage(img[index]),
                        ),
                        SizedBox(
                          width: width / 36,
                        ),
                        Text(
                          title[index],
                          style: pmedium.copyWith(
                            fontSize: 16,
                          ),
                        ),
                        const Spacer(),
                        Icon(selected == index ? Icons.check_circle : null,
                          size: height / 36,
                          color: selected == index
                              ? ChanzoColors.primary
                              : null,)
                      ],
                    ),
                  );
                },
                separatorBuilder: (context, index) {
                  return Column(
                    children: [
                      SizedBox(height: height / 96,),
                      const Divider(),
                      SizedBox(height: height / 96,),
                    ],
                  );
                },
                itemCount: img.length)
          ],
        ),
      ),
    );
  }
}
