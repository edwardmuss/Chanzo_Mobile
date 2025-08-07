import 'package:flutter/material.dart';
import 'package:bootstrap_icons/bootstrap_icons.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:get/get.dart';
import 'package:kiotapay/globalclass/chanzo_color.dart';
import 'package:kiotapay/globalclass/kiotapay_fontstyle.dart';
import 'package:kiotapay/globalclass/kiotapay_global_classes.dart';

import '../globalclass/kiotapay_constants.dart';
import '../globalclass/kiotapay_icons.dart';
import '../kiotapay_pages/kiotapay_authentication/AuthController.dart';

class KiotaPayAppBar extends StatelessWidget implements PreferredSizeWidget {
  final GlobalKey<ScaffoldState> scaffoldKey;
  final AuthController authController = Get.find();

  KiotaPayAppBar({required this.scaffoldKey, Key? key}) : super(key: key);

  String greetUser() {
    final currentTime = DateTime.now();
    final hour = currentTime.hour;
    if (hour < 12) return 'Good morning';
    if (hour < 18) return 'Good afternoon';
    return 'Good evening';
  }

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: ChanzoColors.primary,
      surfaceTintColor: Colors.transparent,
      automaticallyImplyLeading: false,
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Left side menu icon
          InkWell(
            onTap: () => scaffoldKey.currentState?.openDrawer(),
            child: Icon(
              BootstrapIcons.grid,
              size: 30,
              color: ChanzoColors.white,
            ),
          ),

          // Centered greeting and name
          Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    greetUser(),
                    style: pregular_sm.copyWith(
                      color: ChanzoColors.lightSecondary,
                    ),
                  ),
                  Text(
                    authController.userFirstName,
                    style: pmedium_lg.copyWith(
                      color: ChanzoColors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Right side avatar
          Row(
            children: [
              const SizedBox(width: 10),
              InkWell(
                onTap: () => scaffoldKey.currentState?.openDrawer(),
                child: CircleAvatar(
                  radius: 22,
                  backgroundColor: ChanzoColors.lightPrimary,
                  child: CachedNetworkImage(
                    imageUrl: authController.user['avatar'] != null
                        ? '${KiotaPayConstants.webUrl}storage/${authController.user['avatar']}'
                        : '',
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
                      radius: 22,
                      backgroundImage: AssetImage(KiotaPayPngimage.profile),
                    ),
                    errorWidget: (context, url, error) => CircleAvatar(
                      radius: 22,
                      backgroundImage: AssetImage(KiotaPayPngimage.profile),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}