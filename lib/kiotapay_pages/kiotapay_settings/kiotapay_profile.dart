import 'package:cached_network_image/cached_network_image.dart';
import 'package:kiotapay/globalclass/chanzo_color.dart';
import 'package:kiotapay/globalclass/kiotapay_fontstyle.dart';
import 'package:kiotapay/globalclass/kiotapay_icons.dart';
import 'package:kiotapay/kiotapay_pages/kiotapay_settings/kiotapay_cards.dart';
import 'package:kiotapay/kiotapay_theme/kiotapay_themecontroller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../globalclass/global_methods.dart';
import '../../globalclass/kiotapay_constants.dart';

class BankPickProfile extends StatefulWidget {
  const BankPickProfile({super.key});

  @override
  State<BankPickProfile> createState() => _BankPickProfileState();
}

class _BankPickProfileState extends State<BankPickProfile> {
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
          "Profile".tr,
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
                // Navigator.push(context, MaterialPageRoute(
                //   builder: (context) {
                //     return KiotaPayEditProfile(userData: _userData);
                //   },
                // ));
              },
              child: CircleAvatar(
                radius: 18,
                backgroundColor: ChanzoColors.lightPrimary,
                child: CachedNetworkImage(
                  imageUrl: authController.user['avatar'] != null
                      ? '${KiotaPayConstants.webUrl}storage/${authController.user['avatar']}'
                      : '', // Empty string will trigger errorWidget
                  imageBuilder: (context, imageProvider) => Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      image: DecorationImage(
                        image: imageProvider,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  placeholder: (context, url) => CircleAvatar(
                    radius: 50,
                    backgroundImage: AssetImage(KiotaPayPngimage.profile),
                  ),
                  errorWidget: (context, url, error) => CircleAvatar(
                    radius: 50,
                    backgroundImage: AssetImage(KiotaPayPngimage.profile),
                  ),
                ),
              ),
            ),
          )
        ],
      ),
      body: Padding(
        padding:
            EdgeInsets.symmetric(horizontal: width / 36, vertical: height / 36),
        child: Column(
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: ChanzoColors.transparent,
                  backgroundImage: AssetImage(KiotaPayPngimage.p1),
                ),
                SizedBox(
                  width: width / 36,
                ),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Edward Muss".tr,
                      style: pmedium.copyWith(
                        fontSize: 17,
                      ),
                    ),
                    SizedBox(
                      height: height / 200,
                    ),
                    Text(
                      "Senior Designer".tr,
                      style: pregular.copyWith(
                          fontSize: 12, color: ChanzoColors.textgrey),
                    ),
                  ],
                ),
              ],
            ),
            SizedBox(
              height: height / 20,
            ),
            Row(
              children: [
                Image.asset(
                  KiotaPayPngimage.userprofile,
                  height: height / 36,
                  color: ChanzoColors.textgrey,
                ),
                SizedBox(
                  width: width / 56,
                ),
                Text(
                  "Personal_Information".tr,
                  style: pregular.copyWith(
                    fontSize: 14,
                  ),
                ),
                const Spacer(),
                Icon(Icons.chevron_right,
                    size: height / 36, color: ChanzoColors.textgrey)
              ],
            ),
            SizedBox(
              height: height / 96,
            ),
            const Divider(),
            SizedBox(
              height: height / 96,
            ),
            Row(
              children: [
                Image.asset(
                  KiotaPayPngimage.creditcard,
                  height: height / 36,
                  color: ChanzoColors.textgrey,
                ),
                SizedBox(
                  width: width / 56,
                ),
                Text(
                  "Payment_Preferences".tr,
                  style: pregular.copyWith(
                    fontSize: 14,
                  ),
                ),
                const Spacer(),
                Icon(Icons.chevron_right,
                    size: height / 36, color: ChanzoColors.textgrey)
              ],
            ),
            SizedBox(
              height: height / 96,
            ),
            const Divider(),
            SizedBox(
              height: height / 96,
            ),
            InkWell(
              splashColor: ChanzoColors.transparent,
              highlightColor: ChanzoColors.transparent,
              onTap: () {
                Navigator.push(context, MaterialPageRoute(
                  builder: (context) {
                    return const BankPickCards();
                  },
                ));
              },
              child: Row(
                children: [
                  Image.asset(
                    KiotaPayPngimage.creditcardedit,
                    height: height / 36,
                    color: ChanzoColors.textgrey,
                  ),
                  SizedBox(
                    width: width / 56,
                  ),
                  Text(
                    "Banks_and_Cards".tr,
                    style: pregular.copyWith(
                      fontSize: 14,
                    ),
                  ),
                  const Spacer(),
                  Icon(Icons.chevron_right,
                      size: height / 36, color: ChanzoColors.textgrey)
                ],
              ),
            ),
            SizedBox(
              height: height / 96,
            ),
            const Divider(),
            SizedBox(
              height: height / 96,
            ),
            Row(
              children: [
                Image.asset(
                  KiotaPayPngimage.notification,
                  height: height / 36,
                  color: ChanzoColors.textgrey,
                ),
                SizedBox(
                  width: width / 56,
                ),
                Text(
                  "Notifications".tr,
                  style: pregular.copyWith(
                    fontSize: 14,
                  ),
                ),
                const Spacer(),
                Icon(Icons.chevron_right,
                    size: height / 36, color: ChanzoColors.textgrey)
              ],
            ),
            SizedBox(
              height: height / 96,
            ),
            const Divider(),
            SizedBox(
              height: height / 96,
            ),
            Row(
              children: [
                Image.asset(
                  KiotaPayPngimage.message,
                  height: height / 36,
                  color: ChanzoColors.textgrey,
                ),
                SizedBox(
                  width: width / 56,
                ),
                Text(
                  "Message_Center".tr,
                  style: pregular.copyWith(
                    fontSize: 14,
                  ),
                ),
                const Spacer(),
                Icon(Icons.chevron_right,
                    size: height / 36, color: ChanzoColors.textgrey)
              ],
            ),
            SizedBox(
              height: height / 96,
            ),
            const Divider(),
            SizedBox(
              height: height / 96,
            ),
            Row(
              children: [
                Image.asset(
                  KiotaPayPngimage.location,
                  height: height / 36,
                  color: ChanzoColors.textgrey,
                ),
                SizedBox(
                  width: width / 56,
                ),
                Text(
                  "Address".tr,
                  style: pregular.copyWith(
                    fontSize: 14,
                  ),
                ),
                const Spacer(),
                Icon(Icons.chevron_right,
                    size: height / 36, color: ChanzoColors.textgrey)
              ],
            ),
            SizedBox(
              height: height / 96,
            ),
            const Divider(),
            SizedBox(
              height: height / 96,
            ),
          ],
        ),
      ),
    );
  }
}
