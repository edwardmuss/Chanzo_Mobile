
import 'dart:async';
import 'dart:io';

import 'package:bootstrap_icons/bootstrap_icons.dart';
import 'package:kiotapay/globalclass/global_methods.dart';

// import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:kiotapay/globalclass/chanzo_color.dart';
import 'package:kiotapay/globalclass/kiotapay_fontstyle.dart';
import 'package:kiotapay/globalclass/text_icon_button.dart';
import 'package:kiotapay/kiotapay_pages/kiotapay_home/kiotapay_home.dart';
import 'package:kiotapay/kiotapay_pages/kiotapay_settings/kiotapay_settings.dart';
import 'package:kiotapay/kiotapay_pages/kiotapay_statistics/kiotapay_statistics.dart';
import 'package:kiotapay/kiotapay_theme/kiotapay_themecontroller.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../globalclass/biometric_auth.dart';
import '../Examination/parent_results_home_screen.dart';
import '../finance/parent_dashboard.dart';
import '../kiotapay_authentication/change_password_new_user.dart';

// ignore: must_be_immutable
class KiotaPayDashboard extends StatefulWidget {
  final String initialTab;

  KiotaPayDashboard(this.initialTab, {super.key});

  @override
  State<KiotaPayDashboard> createState() => _KiotaPayDashboardState();
}

class _KiotaPayDashboardState extends State<KiotaPayDashboard> with WidgetsBindingObserver {
  dynamic size;
  double height = 0.00;
  double width = 0.00;
  final themedata = Get.put(KiotaPayThemecontroler());

  PageController pageController = PageController();
  int _selectedItemIndex = 0;
  bool _isAuthenticating = false;
  DateTime? _lastActiveTime;
  DateTime? _lastAuthTime;
  Timer? _inactivityTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _selectedItemIndex = int.tryParse(widget.initialTab) ?? 0; // Safe parsing
    pageController = PageController(initialPage: _selectedItemIndex); // Initialize controller with initial page
    _requirePasswordChange();
    _checkBiometricAuth();
    // _startInactivityTimer();
  }

  @override
  void didUpdateWidget(KiotaPayDashboard oldWidget) {
    print('Dashboard updated from tab ${oldWidget.initialTab} to ${widget.initialTab}');
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialTab != widget.initialTab) {
      final newIndex = int.tryParse(widget.initialTab) ?? 0;
      if (newIndex != _selectedItemIndex) {
        setState(() {
          _selectedItemIndex = newIndex;
        });
        pageController.jumpToPage(newIndex);
      }
    }
  }

  void _onTap(int index) {
    print('Tab tapped: $index, current index: $_selectedItemIndex');
    setState(() {
      _selectedItemIndex = index;
    });
    pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this); // Clean up
    _inactivityTimer?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) async {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.paused) {
      print('App resumed, checking biometrics...');
      await _saveLastActiveTime();
    } else if (state == AppLifecycleState.resumed) {
      final lastActive = await _getLastActiveTime();
      if (lastActive != null &&
          DateTime.now().difference(lastActive) > const Duration(minutes: 1)) {
        // _checkBiometricAuth();
      }
      _checkBiometricAuth();
      refreshUserProfile(context);
    }
  }

  Future<void> _saveLastActiveTime() async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setInt('lastActiveTime', DateTime.now().millisecondsSinceEpoch);
  }

  Future<DateTime?> _getLastActiveTime() async {
    final prefs = await SharedPreferences.getInstance();
    final millis = prefs.getInt('lastActiveTime');
    if (millis == null) return null;
    return DateTime.fromMillisecondsSinceEpoch(millis);
  }

  void _startInactivityTimer() {
    _inactivityTimer?.cancel();
    _inactivityTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      if (_lastActiveTime != null &&
          DateTime.now().difference(_lastActiveTime!) > const Duration(minutes: 1)) {
        _requireBiometricAuth();
      }
    });
  }

  Future<void> _checkBiometricAuth() async {
    if (_isAuthenticating) return;

    // Skip if last authentication was recent (< 1 min ago)
    if (_lastAuthTime != null &&
        DateTime.now().difference(_lastAuthTime!) < const Duration(minutes: 1)) {
      return;
    }

    _isAuthenticating = true;

    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('uuid');

      if (userId != null) {
        final isBiometricEnabled =
            prefs.getBool('BiometricSwitchState_$userId') ?? false;
        if (isBiometricEnabled) {
          final success = await _requireBiometricAuth();
          if (success) {
            _lastAuthTime = DateTime.now(); // mark successful auth time
          }
        }
      }
    } finally {
      _isAuthenticating = false;
    }
  }

  Future<bool> _requireBiometricAuth() async {
    final isAuthenticated = await KiotaPayBiometricAuth.authenticateUser();
    if (!isAuthenticated) {
      SystemNavigator.pop(); // Close the app if biometric fails
      return false;
    }
    return true;
  }

  void _requirePasswordChange(){
    // Handle first login user
    if(authController.user['password_change_required']){
      // Show modal/page to Change Password
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Get.off(() => ChangePasswordNewUserScreen());
      });
    }
  }

  final List<Widget> _pages = const [
    KiotaPayHome(),
    FinanceScreen(),
    ParentResultsHomeScreen(),
    KiotaPaySettings(),
  ];

  @override
  void setState(fn) {
    if (mounted) super.setState(fn);
  }

  Future<bool> onbackpressed() async {
    return await showDialog(
        context: context,
        builder: (context) => AlertDialog(
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
              surfaceTintColor: Theme.of(context).dialogBackgroundColor,
              title: Center(
                child: Text("Logout App".tr,
                    textAlign: TextAlign.end,
                    style: pbold.copyWith(fontSize: 18)),
              ),
              content: Text(
                "Are you sure you want to logout from the application?".tr,
                style: pregular.copyWith(fontSize: 12),
              ),
              actionsAlignment: MainAxisAlignment.end,
              actions: [
                ElevatedButton(
                    style: ElevatedButton.styleFrom(
                        backgroundColor: ChanzoColors.primary),
                    onPressed: () {
                      forceLogout();
                      // SystemNavigator.pop();
                      // SystemNavigator.pop(animated: true);
                      // If you are on Android, use exit(0). On iOS, use SystemNavigator.pop
                      // if (Platform.isAndroid) {
                      //   exit(0); // terminate the app completely
                      // } else {
                      //   SystemNavigator.pop(animated: true); // or use exit(0)
                      // }
                    },
                    child: Text(
                      "Logout",
                      style: pregular.copyWith(color: ChanzoColors.white),
                    )),
                ElevatedButton(
                  onPressed: () async {
                    Get.back();
                  },
                  style: ElevatedButton.styleFrom(
                      backgroundColor: ChanzoColors.primary),
                  child: Text("No",
                      style: pregular.copyWith(color: ChanzoColors.white)),
                ),
              ],
            ));
  }

  Widget _bottomTabBar() {
    return BottomNavigationBar(
      currentIndex: _selectedItemIndex,
      onTap: _onTap,
      elevation: 0,
      type: BottomNavigationBarType.fixed,
      backgroundColor:Theme.of(context).scaffoldBackgroundColor,
      selectedLabelStyle: pregular.copyWith(fontSize: 12),
      unselectedLabelStyle: pregular.copyWith(fontSize: 12),
      unselectedItemColor: ChanzoColors.textgrey,
      selectedItemColor: ChanzoColors.primary,
      items: <BottomNavigationBarItem>[
        BottomNavigationBarItem(
          icon: Icon(BootstrapIcons.house,
              color: ChanzoColors.textgrey, size: 16),
          activeIcon: Icon(BootstrapIcons.house, color: ChanzoColors.primary),
          label: 'Home',
        ),
        BottomNavigationBarItem(
          icon: Icon(BootstrapIcons.bar_chart, color: ChanzoColors.textgrey),
          activeIcon:
              Icon(BootstrapIcons.bar_chart, color: ChanzoColors.primary),
          label: 'Finance',
        ),
        BottomNavigationBarItem(
          backgroundColor: ChanzoColors.primary,
          icon: Icon(BootstrapIcons.arrow_left_right,
              color: ChanzoColors.primary),
          activeIcon: Icon(BootstrapIcons.arrow_left_right,
              color: ChanzoColors.primary),
          label: '',
        ),
        BottomNavigationBarItem(
          icon: Icon(BootstrapIcons.clock_history,
              color: ChanzoColors.textgrey),
          activeIcon:
              Icon(BootstrapIcons.clock_history, color: ChanzoColors.primary),
          label: 'Academics',
        ),
        BottomNavigationBarItem(
          icon: Icon(BootstrapIcons.person, color: ChanzoColors.textgrey),
          activeIcon:
              Icon(BootstrapIcons.person, color: ChanzoColors.primary),
          label: 'Settings',
        ),
      ],
    );
  }

  Widget _bottomTabBar2() {
    return Material(
      elevation: 1.0,
      borderRadius: BorderRadius.all(Radius.circular(25)),
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 3),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            MaterialButton(
              onPressed: () {
                _onTap(0);
              },
              shape: CircleBorder(),
              minWidth: 0,
              padding: EdgeInsets.all(5),
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              child: Icon(Icons.refresh),
            ),
            MaterialButton(
              onPressed: () {
                _onTap(1);
              },
              shape: CircleBorder(),
              minWidth: 0,
              padding: EdgeInsets.all(5),
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              child: Icon(Icons.mic),
            ),
            MaterialButton(
              onPressed: () {},
              shape: CircleBorder(),
              minWidth: 0,
              padding: EdgeInsets.all(5),
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              child: Icon(Icons.camera),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomBar(BuildContext context) {
    height:
    MediaQuery.of(context).size.height;
    // return Obx(() {
    return BottomAppBar(
      padding: EdgeInsets.zero,
      height: height / 13,
      color: ChanzoColors.transparent,
      elevation: 0.0,
      notchMargin: 0.0,
      // shape: CircularNotchedRectangle(),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          ItemBottomBar(
            icon: Icons.home_outlined,
            selected: _selectedItemIndex == 0,
            label: "Home",
            onPressed: () {
              _onTap(0);
            },
          ),
          ItemBottomBar(
            icon: BootstrapIcons.bar_chart_line,
            selected: _selectedItemIndex == 1,
            label: "Finance",
            onPressed: () {
              _onTap(1);
            },
          ),
          SizedBox(
            width: 50,
          ),
          ItemBottomBar(
            icon: BootstrapIcons.book_half,
            selected: _selectedItemIndex == 2,
            label: "Academics",
            onPressed: () {
              _onTap(2);
            },
          ),
          ItemBottomBar(
            icon: BootstrapIcons.person,
            selected: _selectedItemIndex == 3,
            label: "Account",
            onPressed: () {
              _onTap(3);
            },
          ),
        ],
      ),
    );
    // });
  }

  @override
  Widget build(BuildContext context) {
    size = MediaQuery.of(context).size;
    height = size.height;
    width = size.width;
    return WillPopScope(
      onWillPop: onbackpressed,
      child: GetBuilder<KiotaPayThemecontroler>(builder: (controller) {
        return Scaffold(
          floatingActionButtonLocation:
              FloatingActionButtonLocation.centerDocked,
          floatingActionButton: Container(
            margin: const EdgeInsets.only(top: 10),
            height: 70,
            width: 70,
            child: FloatingActionButton(
              backgroundColor: ChanzoColors.primary,
              elevation: 0,
              onPressed: () {
                print('All Transaction button clicked');
              },
              shape: RoundedRectangleBorder(
                side: const BorderSide(width: 3, color: ChanzoColors.white),
                borderRadius: BorderRadius.circular(100),
              ),
              child: const Icon(
                BootstrapIcons.arrow_left_right,
                color: ChanzoColors.white,
              ),
            ),
          ),
          bottomNavigationBar: _buildBottomBar(context),
          body: PageView(
            controller: pageController,
            physics: const NeverScrollableScrollPhysics(), // Disable swipe
            children: _pages,
            onPageChanged: (index) {
              setState(() {
                _selectedItemIndex = index;
              });
            },
          ),
        );
      }),
    );
  }
}

class ItemBottomBar extends StatelessWidget {
  final IconData icon;
  final bool selected;
  final bool showBadge;
  final int badgeValue;
  final String label;
  final VoidCallback onPressed;

  ItemBottomBar({
    required this.icon,
    this.selected = false,
    this.showBadge = false,
    this.badgeValue = 0,
    this.label = '',
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    Widget _tabIcon = Column(
      children: [
        IconButton(
          padding: EdgeInsets.zero,
          // constraints: BoxConstraints(),
          onPressed: onPressed,
          iconSize: MediaQuery.of(context).size.width / 15,
          icon: Icon(icon,
              color:
                  selected ? ChanzoColors.primary : ChanzoColors.textgrey),
        ),
        Text(
          label,
          style: pregular_sm.copyWith(
            color: selected ? ChanzoColors.primary : ChanzoColors.textgrey,
            height: 0.001,
          ),
        ),
      ],
    );

    // if (showBadge) {
    //   return badges.Badge(
    //     position: badges.BadgePosition.topEnd(top: 10, end: 10),
    //     badgeAnimation: const badges.BadgeAnimation.scale(
    //       animationDuration: Duration(milliseconds: 300),
    //       colorChangeAnimationDuration: Duration(seconds: 1),
    //     ),
    //     badgeStyle: const badges.BadgeStyle(badgeColor: Colors.pinkAccent),
    //     showBadge: false,
    //     badgeContent: Text(
    //       '$badgeValue',
    //       style: TextStyle(
    //           fontSize: 32, color: Colors.white, fontWeight: FontWeight.w700),
    //     ),
    //     child: _tabIcon,
    //   );
    // }

    return _tabIcon;
  }
}
