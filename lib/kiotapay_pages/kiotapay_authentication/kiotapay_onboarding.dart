import 'dart:async';

import 'package:kiotapay/globalclass/chanzo_color.dart';
import 'package:kiotapay/globalclass/kiotapay_fontstyle.dart';
import 'package:kiotapay/globalclass/kiotapay_icons.dart';
import 'package:kiotapay/kiotapay_pages/kiotapay_authentication/kiotapay_signin.dart';
import 'package:kiotapay/kiotapay_theme/kiotapay_themecontroller.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:nb_utils/nb_utils.dart';

class KiotaPayOnboarding extends StatefulWidget {
  const KiotaPayOnboarding({Key? key}) : super(key: key);

  @override
  State<KiotaPayOnboarding> createState() => _KiotaPayOnboardingState();
}

class _KiotaPayOnboardingState extends State<KiotaPayOnboarding> {
  dynamic size;
  double height = 0.00;
  double width = 0.00;
  final themedata = Get.put(KiotaPayThemecontroler());

  var pageController = PageController();
  List<Widget> pages = [];
  var selectedIndex = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    // Start auto-swiping when the widget initializes
    _startAutoSwipe();
  }

  @override
  void dispose() {
    // Cancel the timer when the widget is disposed to avoid memory leaks
    _timer?.cancel();
    pageController.dispose();
    super.dispose();
  }

  void _startAutoSwipe() {
    _timer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (selectedIndex < pages.length - 1) {
        pageController.nextPage(
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
        );
      } else {
        // Reset to first page if at the end
        pageController.animateToPage(
          0,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  init() {
    size = MediaQuery.of(context).size;
    height = size.height;
    width = size.width;
    pages = [
      TopCoverContainer(
        coverImage: KiotaPayPngimage.chanzo_kid,
        title: "Your #1 School\nManagement System",
        description: "Our School Management System simplifies administration, enhances communication, and improves student engagement. Manage attendance, grades, schedules, and more—all in one secure platform designed to make school management seamless and efficient.",
        // logoImage: KiotaPayPngimage.logohorizontaldark,
        backgroundColor: ChanzoColors.white,
        titleTopSpacing: 8,
      ),
      TopCoverContainer(
        coverImage: KiotaPayPngimage.chanzo_kid2,
        title: "Empowering Schools \nfor a Smarter Future",
        description: "Transform the way your school operates with our innovative management system. From student records to parent communication, our platform helps educators stay organized, save time, and focus on what truly matters—student success.",
        // logoImage: KiotaPayPngimage.logohorizontaldark,
        backgroundColor: ChanzoColors.white,
        titleTopSpacing: 8,
      ),
      TopCoverContainer(
        coverImage: KiotaPayPngimage.chanzo_kid3,
        title: "Your All-in-One \nManagement Solution",
        description: "Simplify daily administrative tasks with our comprehensive system. Easily track attendance, manage fees, schedule classes, and communicate with parents—all through an intuitive interface designed to support your school's growth and efficiency.",
        // logoImage: KiotaPayPngimage.logohorizontaldark,
        backgroundColor: ChanzoColors.white,
        titleTopSpacing: 8,
      ),
    ];
  }

  @override
  void setState(fn) {
    if (mounted) super.setState(fn);
  }

  @override
  Widget build(BuildContext context) {
    size = MediaQuery.of(context).size;
    height = size.height;
    width = size.width;
    init();
    return Scaffold(
      body: Stack(
        children: [
          PageView(
            controller: pageController,
            children: pages,
            onPageChanged: (index) {
              setState(() {
                selectedIndex = index;
              });
              // Reset timer on manual swipe
              _timer?.cancel();
              _startAutoSwipe();
            },
          ),
          AnimatedPositioned(
            duration: const Duration(seconds: 1),
            bottom: height / 2,
            left: width / 26,
            right: width / 26,
            child: SmoothPageIndicator(
              controller: pageController,
              count: pages.length,
              effect: ExpandingDotsEffect(
                activeDotColor: ChanzoColors.primary,
                dotColor: ChanzoColors.secondary,
                dotHeight: 16,
                dotWidth: 16,
              ),
              // unselectedIndicatorColor: ChanzoColors.lightPrimary,
              // pageController: pageController,
              // pages: pages,
              // dotSize: 8.00,
              // currentDotSize: 10.00,
              // currentDotWidth: 10.00,
              // indicatorColor: ChanzoColors.primary
            ),
          ),
          Positioned(
            bottom: height / 26,
            left: width / 26,
            right: width / 26,
            child: InkWell(
              splashColor: ChanzoColors.transparent,
              highlightColor: ChanzoColors.transparent,
              onTap: () async {
                SharedPreferences prefs = await SharedPreferences.getInstance();
                prefs.setInt('isFirstTime', 0);
                Navigator.push(context, MaterialPageRoute(
                  builder: (context) {
                    return const KiotaPaySignIn();
                  },
                ));
              },
              child: Container(
                height: height / 15,
                width: width / 1,
                decoration: BoxDecoration(
                    color: ChanzoColors.primary,
                    borderRadius: BorderRadius.circular(50)),
                child: Center(
                  child: Text("Get Started".tr,
                      style: psemibold.copyWith(
                          fontSize: 16, color: ChanzoColors.white)),
                ),
              ),
            ),
          )
        ],
      ),
    );
  }
}

class TopCoverContainer extends StatelessWidget {
  final String coverImage;
  final String title;
  final String description;
  final String? logoImage;
  final Color backgroundColor;
  final double imageHeightRatio;
  final EdgeInsetsGeometry contentPadding;
  final double titleTopSpacing;
  final double descriptionTopSpacing;
  final double logoTopSpacing;

  const TopCoverContainer({
    Key? key,
    required this.coverImage,
    required this.title,
    required this.description,
    this.logoImage,
    this.backgroundColor = ChanzoColors.white,
    this.imageHeightRatio = 2.5,
    this.contentPadding = const EdgeInsets.symmetric(horizontal: 36, vertical: 36),
    this.titleTopSpacing = 15,
    this.descriptionTopSpacing = 56,
    this.logoTopSpacing = 35,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.of(context).size.height;
    final width = MediaQuery.of(context).size.width;

    return Container(
      color: backgroundColor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Image.asset(
            coverImage,
            width: double.infinity,
            height: height / imageHeightRatio,
            fit: BoxFit.cover,
          ),
          Padding(
            padding: contentPadding is EdgeInsets
                ? EdgeInsets.symmetric(
              horizontal: width / (contentPadding as EdgeInsets).horizontal,
              vertical: height / (contentPadding as EdgeInsets).vertical,
            )
                : contentPadding,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: height / titleTopSpacing),
                Text(
                  title,
                  style: psemibold.copyWith(
                    fontSize: 26,
                    color: ChanzoColors.primary,
                  ),
                ),
                SizedBox(height: height / descriptionTopSpacing),
                Text(
                  description,
                  textAlign: TextAlign.left,
                  style: pregular.copyWith(
                    fontSize: 14,
                    color: ChanzoColors.black,
                  ),
                ),
                if (logoImage != null) ...[
                  SizedBox(height: height / logoTopSpacing),
                  Center(
                    child: Image.asset(
                      logoImage!,
                      width: width / 2,
                      fit: BoxFit.contain,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
