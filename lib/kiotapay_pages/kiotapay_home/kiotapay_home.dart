import 'dart:async';
import 'dart:convert';
import 'dart:ui';
import 'dart:io' show Platform;

import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:gradient_icon/gradient_icon.dart';
import 'package:kiotapay/globalclass/chanzo_color.dart';
import 'package:kiotapay/globalclass/kiotapay_fontstyle.dart';
import 'package:kiotapay/globalclass/kiotapay_global_classes.dart';
import 'package:kiotapay/globalclass/kiotapay_icons.dart';
import 'package:kiotapay/kiotapay_pages/attendance/student_attendance.dart';
import 'package:kiotapay/kiotapay_pages/calendar/calendar_screen.dart';
import 'package:kiotapay/kiotapay_pages/homework/homework_screen.dart';
import 'package:kiotapay/kiotapay_pages/kiotapay_authentication/kiotapay_pincode.dart';
import 'package:kiotapay/kiotapay_pages/kiotapay_drawer/kiotapay_drawer.dart';
import 'package:kiotapay/globalclass/text_icon_button.dart';
import 'package:kiotapay/kiotapay_pages/notice_board/notice_board_screen.dart';
import 'package:kiotapay/kiotapay_pages/resource_center/resource_center_screen.dart';
import 'package:kiotapay/kiotapay_pages/timetable/timetable_screen.dart';
import 'package:kiotapay/kiotapay_theme/kiotapay_themecontroller.dart';
import 'package:bootstrap_icons/bootstrap_icons.dart';
import 'package:flutter_initicon/flutter_initicon.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:nb_utils/nb_utils.dart' hide DialogType;
import 'package:kiotapay/globalclass/kiotapay_constants.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import 'package:simple_gradient_text/simple_gradient_text.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../globalclass/global_methods.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../widgets/RoundedIconButtonWithLabel.dart';
import '../../widgets/custom_appbar.dart';
import '../../widgets/reusable_bottom_sheet.dart';
import '../../widgets/student_performance_dashboard.dart';
import '../Examination/performance_controller.dart';
import '../ai/chat_screen.dart';
import '../fees/fee_structure_screen.dart';
import '../fees/payment_methods_screen.dart';
import '../fees/payment_screen.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';

class KiotaPayHome extends StatefulWidget {
  const KiotaPayHome({super.key});

  @override
  State<KiotaPayHome> createState() => _KiotaPayHomeState();
}

class _KiotaPayHomeState extends State<KiotaPayHome> {
  dynamic size;
  double height = 0.00;
  double width = 0.00;
  final themedata = Get.put(KiotaPayThemecontroler());
  final Future<SharedPreferences> _prefs = SharedPreferences.getInstance();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  bool _isShowBalance = false;
  bool isLoading = false;
  Map<String, dynamic>? _userData;
  List<dynamic> recentTransactions = [];
  final _formKey = GlobalKey<FormState>();
  late final allocationReasonController = TextEditingController();
  late final allocationAmountController = TextEditingController();
  TextEditingController allocationLinkUserController =
      TextEditingController(text: '');

  int _counter = 30;
  late Timer _timer;
  double _userWallet = 0.00;
  RefreshController refreshController =
      RefreshController(initialRefresh: false);

  String userRole = '';

  Map<String, dynamic> mpesaData = {};
  Map<String, dynamic> pesalinkData = {};
  String clientNumber = '';
  bool _showFloatingButton = true;
  final ScrollController _scrollController = ScrollController();
  bool _isFabVisible = true;
  bool _isScrollingDown = false;
  bool _isScrollingUp = false;
  double _scrollPosition = 7;
  bool _isExtended = true; // Controls whether FAB shows label or not

  @override
  initState() {
    super.initState();
    checkForUpdate();
    _loadShowBalancePreference();
    authController.fetchAndCacheFeeBalance();

    Get.put(PerformanceController());
    Get.find<PerformanceController>().loadPerformance();
    // Get.find<PerformanceController>().loadStudentExamTrend();
    // getPermissions();
    isLoginedIn();
    _scrollController.addListener(() {
      if (_scrollController.position.userScrollDirection == ScrollDirection.reverse) {
        if (!_isScrollingDown) {
          _isScrollingDown = true;
          _isScrollingUp = false;
          setState(() {
            _isExtended = false; // Shrink to icon
          });
        }
      }

      if (_scrollController.position.userScrollDirection == ScrollDirection.forward) {
        if (!_isScrollingUp) {
          _isScrollingUp = true;
          _isScrollingDown = false;
          setState(() {
            _isExtended = true; // Extend with label
          });
        }
      }

      _scrollPosition = _scrollController.position.pixels;
    });
  }

  @override
  void dispose() {
    // Dispose the timer to prevent memory leaks
    // _timer.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  Widget _buildFloatingActionButton() {
    return AnimatedContainer(
      duration: Duration(milliseconds: 300),
      constraints: BoxConstraints(
        minWidth: 56,  // Minimum size for FAB
        maxWidth: _isExtended ? 200 : 56,  // Extended width vs circle width
      ),
      height: 56,  // Fixed height matching width when shrunk
      child: _isExtended
          ? FloatingActionButton.extended(
        onPressed: () => Get.to(() => ChatPageScreen()),
        icon: Icon(Icons.auto_awesome),
        label: Text("Chanzo AI"),
        backgroundColor: ChanzoColors.primary,
        foregroundColor: ChanzoColors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(28),  // 28 = 56/2
        ),
      )
          : FloatingActionButton(
        onPressed: () => Get.to(() => ChatPageScreen()),
        child: Icon(Icons.auto_awesome),
        backgroundColor: ChanzoColors.primary,
        shape: CircleBorder(),  // Perfect circle
      ),
    );
  }

  Future<void> _onRefresh() async {
    await isLoginedIn();
    refreshUserProfile(context);
    authController.fetchAndCacheFeeBalance();
    await Get.find<PerformanceController>().refreshData();
    print("Refreshing");
    refreshController.refreshCompleted();
    print("Refreshed Successfull");
  }

  void _onLoading() {
    refreshController.refreshCompleted();
  }

  Future<void> checkForUpdate() async {
    final String installedVersion = await getInstalledVersion();
    final String latestVersion = await fetchLatestVersion();

    if (_compareVersions(installedVersion, latestVersion) < 0) {
      // _showUpdateDialog();
    }
  }

  Future<String> getInstalledVersion() async {
    final PackageInfo packageInfo = await PackageInfo.fromPlatform();
    return packageInfo.version;
  }

  Future<String> fetchLatestVersion() async {
    final response = await http
        .get(Uri.parse('https://cloudrebue.co.ke/latest_version.txt'));
    if (response.statusCode == 200) {
      return response.body.trim();
    } else {
      throw Exception('Failed to fetch version info');
    }
  }

  int _compareVersions(String v1, String v2) {
    final List<int> version1 = v1.split('.').map(int.parse).toList();
    final List<int> version2 = v2.split('.').map(int.parse).toList();

    for (int i = 0; i < version1.length; i++) {
      if (i >= version2.length) return 1;
      if (version1[i] < version2[i]) return -1;
      if (version1[i] > version2[i]) return 1;
    }
    return 0;
  }

  void _showUpdateDialog() {
    showDialog(
      context: context,
      barrierDismissible: true, // Make dialog undismissible by tapping outside
      builder: (BuildContext context) {
        return WillPopScope(
          onWillPop: () async => false, // Prevent back button dismissal
          child: AlertDialog(
            title: Text('Update Available'),
            content: Text(
                'A new version of the app is available. Please update to the latest version.'),
            actions: <Widget>[
              TextButton(
                child: Text('Update'),
                onPressed: () {
                  // Open the appropriate store page
                  if (Platform.isAndroid) {
                    _launchURL(
                        'https://play.google.com/store/apps/details?id=com.chanzo.app');
                  } else if (Platform.isIOS) {
                    _launchURL('https://apps.apple.com/app/id6504042142');
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _launchURL(String url) async {
    final Uri uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      throw 'Could not launch $url';
    }
  }

  Future<void> initiateMpesaExpress(String phone, int amount) async {
    var minutes = await getTokenExpiryMinutes();
    if (minutes < 4) {
      refreshToken();
    }
    var token = await getAccessToken();
    var headers = {
      'Authorization': 'Bearer $token',
      "Content-Type": "application/json"
    };
    var body = {"amount": amount, "phoneNumber": phone};
    showLoading('Initiating...');
    try {
      var url = Uri.parse(KiotaPayConstants.mpesaStkPush);
      http.Response response =
          await http.post(url, body: jsonEncode(body), headers: headers);

      if (response.statusCode == 200 || response.statusCode == 201) {
        final json = jsonDecode(response.body);
        var msg = jsonDecode(response.body)['msg'];
        hideLoading();
        awesomeDialog(
            context,
            "Success",
            "Please check your phone to complete payment",
            true,
            DialogType.info,
            ChanzoColors.primary)
          ..show();
        // _onRefresh();
      } else {
        var _error =
            jsonDecode(response.body)['message'] ?? "Unknown Error Occurred";
        // _dialog..dismiss();
        // context.loaderOverlay.hide();
        hideLoading();
        awesomeDialog(context, "Error", _error.toString(), true,
            DialogType.error, ChanzoColors.secondary)
          ..show();
        throw _error ?? "Unknown Error Occured";
      }
    } catch (error) {
      hideLoading();
    }
  }

  Future<void> _loadShowBalancePreference() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _isShowBalance = prefs.getBool("isShowBalance") ?? false;
    });
  }

  void _toggleBalanceVisibility() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _isShowBalance = !_isShowBalance;
    });
    await prefs.setBool("isShowBalance", _isShowBalance);
  }

  String greetUser() {
    final currentTime = DateTime.now();
    final hour = currentTime.hour;
    if (hour < 12) {
      return 'Good morning';
    } else if (hour < 18) {
      return 'Good afternoon';
    } else {
      return 'Good evening';
    }
  }

  Widget walletCard() => Card(
    color: ChanzoColors.primary80,
    clipBehavior: Clip.antiAlias,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(24),
    ),
    child: Stack(
      alignment: Alignment.center,
      children: [
        Ink.image(
          image: AssetImage(KiotaPayPngimage.card),
          child: InkWell(onTap: () {}),
          height: 100,
          fit: BoxFit.cover,
        ),
        Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ClipOval(
                  child: Material(
                    color: ChanzoColors.lightSecondary,
                    child: InkWell(
                      splashColor: ChanzoColors.primary,
                      onTap: () {},
                      child: const SizedBox(
                        width: 60,
                        height: 60,
                        child: Icon(
                          BootstrapIcons.wallet2,
                          size: 40,
                          color: ChanzoColors.primary,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: 20),
                    Text(
                      'Fee Balance',
                      style: pregular_lg.copyWith(color: Colors.white),
                    ),
                    Row(
                      children: [
                        ImageFiltered(
                          imageFilter: ImageFilter.blur(
                            sigmaX: _isShowBalance ? 0 : 6,
                            sigmaY: _isShowBalance ? 0 : 3,
                          ),
                          child: Obx(() => Text(
                            "${KiotaPayConstants.currency} ${decimalformatedNumber.format(authController.feeBalance.value)}",
                            style: pregular_hsm.copyWith(color: Colors.white),
                          )),
                        ),
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: _toggleBalanceVisibility, // Simplified
                          child: Icon(
                            _isShowBalance ? BootstrapIcons.eye : BootstrapIcons.eye_slash,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ],
    ),
  );

  @override
  Widget build(BuildContext context) {
    size = MediaQuery.of(context).size;
    height = size.height;
    width = size.width;
    return Scaffold(
      key: _scaffoldKey,
      drawer: const KiotaPayDrawer(),
      appBar: KiotaPayAppBar(scaffoldKey: _scaffoldKey),
      floatingActionButton: Padding(
        padding: EdgeInsets.only(bottom: 16),
        child: _buildFloatingActionButton(),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      body: NotificationListener<ScrollNotification>(
        onNotification: (notification) {
          if (notification is ScrollUpdateNotification) {
            if (notification.scrollDelta! > 7 && _isExtended) {
              setState(() => _isExtended = false); // Scrolling down - shrink
            } else if (notification.scrollDelta! < 7 && !_isExtended) {
              setState(() => _isExtended = true); // Scrolling up - extend
            }
          }
          return false;
        },
        child: SmartRefresher(
          controller: refreshController,
          enablePullDown: true,
          header: WaterDropHeader(),
          onRefresh: _onRefresh,
          child: SingleChildScrollView(
            controller: _scrollController,
            child: Column(
              children: [
                Container(
                  decoration: BoxDecoration(
                      borderRadius: BorderRadius.only(
                        bottomLeft: Radius.circular(30),
                        bottomRight: Radius.circular(30),
                      ),
                      color: ChanzoColors.primary),
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                        horizontal: width / 36, vertical: height / 36),
                    child: Column(
                      children: [
                        Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                authController.schoolName,
                                style: pregular_hsm.copyWith(
                                  color: ChanzoColors.lightSecondary,
                                ),
                              ),
                              Text(
                                "Term ${authController.currentAcademicTermName}, ${authController.currentAcademicSessionName}",
                                style: pmedium_lg.copyWith(
                                  color: ChanzoColors.white,
                                ),
                              ),
                              Obx(() => Text(
                                    authController.selectedStudentName,
                                    style: pmedium_lg.copyWith(
                                      color: ChanzoColors.lightSecondary,
                                    ),
                                  ))
                            ],
                          ),
                        ),
                        SizedBox(
                          height: height / 36,
                        ),
                        walletCard(),
                        SizedBox(
                          height: height / 36,
                        ),
                      ],
                    ),
                  ),
                ),
                // Quick Links
                Padding(
                  padding: const EdgeInsets.only(
                      left: 16.0, right: 16.0, top: 16.0, bottom: 0.0),
                  child: Column(
                    children: [
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          "Quick Links".tr,
                          style: pmedium.copyWith(
                            fontSize: 18,
                          ),
                        ),
                      ),
                      SizedBox(
                        height: height / 36,
                      ),
                      SizedBox(
                        height: height / 7,
                        child: ListView(
                          scrollDirection: Axis.horizontal,
                          padding: EdgeInsets.symmetric(horizontal: 16),
                          // Add some side padding
                          children: [
                            // First set of buttons
                            RoundedIconButtonWithLabel(
                              icon: LineIcons.money_check,
                              label: "Finance",
                              onPressed: () {
                                ReusableBottomSheet.show(
                                  context: context,
                                  title: 'Select Option',
                                  buttons: [
                                    BottomSheetButton(
                                      icon: BootstrapIcons.phone,
                                      title: 'Fee Structure',
                                      onTap: () {
                                        Navigator.pop(context);
                                        Get.to(() => FeeStructureScreen());
                                      },
                                    ),
                                    BottomSheetButton(
                                      icon: BootstrapIcons.lightning,
                                      title: 'Payments',
                                      onTap: () {
                                        Navigator.pop(context);
                                        Get.to(() => PaymentsScreen(
                                            studentId: authController
                                                .selectedStudent['id']));
                                      },
                                    ),
                                    BottomSheetButton(
                                      icon: BootstrapIcons.lightning,
                                      title: 'Pay Now',
                                      onTap: () {
                                        Navigator.pop(context);
                                        Get.to(() => PaymentMethodsScreen());
                                      },
                                    ),
                                  ],
                                  cancelText: 'Close',
                                );
                              },
                              size: height / 10,
                              iconSize: height / 30,
                              backgroundColor: ChanzoColors.secondary20,
                              iconColor: ChanzoColors.secondary,
                              splashColor: ChanzoColors.primary,
                              labelColor: ChanzoColors.textgrey,
                              borderRadius: 12,
                              spacing: height / 200,
                            ),
                            SizedBox(width: 16), // Add spacing between buttons

                            RoundedIconButtonWithLabel(
                              icon: LineIcons.newspaper,
                              label: "Exam",
                              onPressed: () => Get.to(() => Placeholder()),
                              size: height / 10,
                              iconSize: height / 30,
                              backgroundColor: ChanzoColors.secondary20,
                              iconColor: ChanzoColors.secondary,
                              splashColor: ChanzoColors.primary,
                              labelColor: ChanzoColors.textgrey,
                              borderRadius: 12,
                              spacing: height / 200,
                            ),
                            SizedBox(width: 16),

                            RoundedIconButtonWithLabel(
                              icon: LineIcons.calendar_check,
                              label: "Timetable",
                              onPressed: () {
                                if (authController
                                        .hasPermission('class_timetable-view') &&
                                    authController.userRole == 'parent')
                                  Get.to(() => TimetableScreen(
                                        classId: authController
                                            .selectedStudent['class_id'],
                                        streamId: authController
                                            .selectedStudent['stream_id'],
                                      ));
                              },
                              size: height / 10,
                              iconSize: height / 30,
                              backgroundColor: ChanzoColors.secondary20,
                              iconColor: ChanzoColors.secondary,
                              splashColor: ChanzoColors.primary,
                              labelColor: ChanzoColors.textgrey,
                              borderRadius: 12,
                              spacing: height / 200,
                            ),
                            SizedBox(width: 16),

                            RoundedIconButtonWithLabel(
                              icon: LineIcons.calendar_check,
                              label: "Attendance",
                              onPressed: () {
                                if (authController
                                        .hasPermission('student_attendance-view') &&
                                    authController.userRole == 'parent')
                                  Get.to(() => StudentAttendanceScreen(
                                      studentId:
                                          authController.selectedStudent['id']));
                              },
                              size: height / 10,
                              iconSize: height / 30,
                              backgroundColor: ChanzoColors.secondary20,
                              iconColor: ChanzoColors.secondary,
                              splashColor: ChanzoColors.primary,
                              labelColor: ChanzoColors.textgrey,
                              borderRadius: 12,
                              spacing: height / 200,
                            ),
                            SizedBox(width: 16),

                            RoundedIconButtonWithLabel(
                              icon: LineIcons.laptop,
                              label: "Resource Center",
                              onPressed: () {
                                if (authController.hasPermission('resource_center-view'))
                                  Get.to(() => ResourceCenterScreen());
                              },
                              size: height / 10,
                              iconSize: height / 30,
                              backgroundColor: ChanzoColors.secondary20,
                              iconColor: ChanzoColors.secondary,
                              splashColor: ChanzoColors.primary,
                              labelColor: ChanzoColors.textgrey,
                              borderRadius: 12,
                              spacing: height / 200,
                            ),
                            SizedBox(width: 16),

                            // Second set of buttons
                            RoundedIconButtonWithLabel(
                              icon: LineIcons.money_check,
                              label: "Homework",
                              onPressed: () => Get.to(() => HomeworkScreen()),
                              size: height / 10,
                              iconSize: height / 30,
                              backgroundColor: ChanzoColors.secondary20,
                              iconColor: ChanzoColors.secondary,
                              splashColor: ChanzoColors.primary,
                              labelColor: ChanzoColors.textgrey,
                              borderRadius: 12,
                              spacing: height / 200,
                            ),
                            SizedBox(width: 16),

                            RoundedIconButtonWithLabel(
                              icon: LineIcons.newspaper,
                              label: "Notice Board",
                              onPressed: () => Get.to(() => NoticesScreen()),
                              size: height / 10,
                              iconSize: height / 30,
                              backgroundColor: ChanzoColors.secondary20,
                              iconColor: ChanzoColors.secondary,
                              splashColor: ChanzoColors.primary,
                              labelColor: ChanzoColors.textgrey,
                              borderRadius: 12,
                              spacing: height / 200,
                            ),
                            SizedBox(width: 16),

                            RoundedIconButtonWithLabel(
                              icon: LineIcons.calendar,
                              label: "Calendar",
                              onPressed: () => Get.to(() => CalendarScreen()),
                              size: height / 10,
                              iconSize: height / 30,
                              backgroundColor: ChanzoColors.secondary20,
                              iconColor: ChanzoColors.secondary,
                              splashColor: ChanzoColors.primary,
                              labelColor: ChanzoColors.textgrey,
                              borderRadius: 12,
                              spacing: height / 200,
                            ),
                            SizedBox(width: 16),

                            RoundedIconButtonWithLabel(
                              icon: LineIcons.laptop,
                              label: "Transport",
                              onPressed: () => Get.to(() => Placeholder()),
                              size: height / 10,
                              iconSize: height / 30,
                              backgroundColor: ChanzoColors.secondary20,
                              iconColor: ChanzoColors.secondary,
                              splashColor: ChanzoColors.primary,
                              labelColor: ChanzoColors.textgrey,
                              borderRadius: 12,
                              spacing: height / 200,
                            ),
                          ],
                        ),
                      )
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(
                      left: 16.0, right: 16.0, top: 0.0, bottom: 16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Analysis".tr,
                        style: pmedium.copyWith(
                          fontSize: 18,
                        ),
                      ),
                      InkWell(
                        splashColor: ChanzoColors.transparent,
                        highlightColor: ChanzoColors.transparent,
                        onTap: () {
                          Navigator.push(context, MaterialPageRoute(
                            builder: (context) {
                              return const Placeholder();
                            },
                          ));
                        },
                        child: Text(
                          "See All".tr,
                          style: pmedium.copyWith(
                              fontSize: 14, color: Theme.of(context).colorScheme.primary),
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 16.0, right: 16.0),
                  child: Column(
                    children: [
                      StudentPerformanceDashboard().buildPerformanceGrid(),
                      StudentPerformanceDashboard().buildSubjectPerformanceChart(),
                      StudentPerformanceDashboard().buildSubjectPerformanceTable(),
                      // StudentPerformanceDashboard().buildExamTrendChart(),
                      SizedBox(height: height / 30,)
                    ],
                  ),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}
