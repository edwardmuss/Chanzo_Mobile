import 'dart:convert';

import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:bootstrap_icons/bootstrap_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_initicon/flutter_initicon.dart';
import 'package:get/get.dart';
import 'package:kiotapay/globalclass/chanzo_color.dart';
import 'package:kiotapay/globalclass/kiotapay_global_classes.dart';
import 'package:kiotapay/globalclass/kiotapay_fontstyle.dart';
import 'package:kiotapay/kiotapay_models/user_model.dart';
import 'package:kiotapay/kiotapay_pages/Examination/parent_results_home_screen.dart';
import 'package:kiotapay/kiotapay_pages/calendar/calendar_screen.dart';
import 'package:kiotapay/kiotapay_pages/homework/homework_screen.dart';
import 'package:kiotapay/kiotapay_pages/kiota_categories/list.dart';
import 'package:kiotapay/globalclass/text_icon_button.dart';
import 'package:kiotapay/kiotapay_pages/kiotapay_dahsboard/kiotapay_dahsboard.dart';
import 'package:kiotapay/kiotapay_pages/kiotapay_settings/kiotapay_settings.dart';
import 'package:kiotapay/kiotapay_pages/notice_board/notice_board_screen.dart';
import 'package:kiotapay/kiotapay_pages/timetable/timetable_screen.dart';
import 'package:kiotapay/kiotapay_theme/kiotapay_themecontroller.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:nb_utils/nb_utils.dart' hide DialogType;
import 'package:shared_preferences/shared_preferences.dart';

import '../../globalclass/global_methods.dart';
import '../../globalclass/kiotapay_constants.dart';
import '../../globalclass/kiotapay_icons.dart';
import '../Examination/performance_controller.dart';
import '../attendance/student_attendance.dart';
import '../finance/parent_dashboard.dart';
import '../kiota_teams/list.dart';
import 'package:http/http.dart' as http;

import '../kiotapay_authentication/AuthController.dart';
import '../resource_center/resource_center_screen.dart';

class KiotaPayDrawer extends StatefulWidget {
  const KiotaPayDrawer({super.key});

  @override
  State<KiotaPayDrawer> createState() => _KiotaPayDrawerState();
}

class _KiotaPayDrawerState extends State<KiotaPayDrawer> {
  dynamic size;
  double height = 0.00;
  double width = 0.00;
  final themedata = Get.put(KiotaPayThemecontroler());
  final Future<SharedPreferences> _prefs = SharedPreferences.getInstance();
  late User _userData;
  Map<String, dynamic>? _userDataLocal;
  bool _isLoading = true;
  String userRole = '';
  String _appVersion = '';
  final _formKey = GlobalKey<FormState>();
  late final allocationReasonController = TextEditingController();
  late final allocationAmountController = TextEditingController();
  TextEditingController allocationLinkUserController =
      TextEditingController(text: '');
  double _orgBalance = 0.00;

  // bool isSwitchedFT = false;

  bool isdark = false;
  bool isdark1 = true;

  @override
  initState() {
    super.initState();
    getAppVersion();
  }

  getAppVersion() async {
    final String installedVersion = await getInstalledVersion();
    setState(() {
      _appVersion = installedVersion;
    });
  }

  @override
  Widget build(BuildContext context) {
    final authController = Get.find<AuthController>();
    return Drawer(
      child: Stack(
        children: [
          // Main scrollable content
          SingleChildScrollView(
            child: Column(
              children: [
                // Header section
                _buildHeader(authController),

                // Spacer for the student list (when expanded)
                Obx(() => SizedBox(
                      height: authController.isStudentListExpanded.value
                          ? _calculateStudentListHeight(
                              authController.allStudents.length)
                          : 0,
                    )),

                // Drawer menu items
                _buildMenuItems(context, authController),
              ],
            ),
          ),

          // Student list overlay (positioned absolutely)
          if (authController.userRole == 'parent')
            Obx(() => AnimatedPositioned(
                  duration: const Duration(milliseconds: 300),
                  top: authController.isStudentListExpanded.value
                      ? _getHeaderHeight()
                      : -_calculateStudentListHeight(
                          authController.allStudents.length),
                  left: 0,
                  right: 0,
                  child: _buildStudentList(authController),
                )),
        ],
      ),
    );
  }

  Widget _buildHeader(AuthController authController) {
    return InkWell(
      onTap: () {
        if (authController.userRole == 'parent') {
          authController.isStudentListExpanded.toggle();
        }
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.only(top: 40, bottom: 20),
        decoration: BoxDecoration(
          image: DecorationImage(
            image: NetworkImage(
              authController.user['cover_image'] != null
                  ? '${KiotaPayConstants.webUrl}storage/${authController.user['cover_image']}'
                  : KiotaPayPngimage.card,
            ),
            fit: BoxFit.cover,
          ),
        ),
        child: Container(
          color: Colors.black.withOpacity(0.4),
          child: Column(
            children: [
              const SizedBox(height: 10),
              Stack(
                alignment: Alignment.bottomRight,
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundImage: NetworkImage(
                      authController.user['avatar'] != null
                          ? '${KiotaPayConstants.webUrl}storage/${authController.user['avatar']}'
                          : KiotaPayPngimage.profile,
                    ),
                  ),
                  if (authController.userRole == 'parent' &&
                      authController.selectedStudent.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: ChanzoColors.primary,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white,
                          width: 2,
                        ),
                      ),
                      child: CircleAvatar(
                        radius: 12,
                        backgroundImage: NetworkImage(
                          authController.selectedStudent['user']?['avatar'] !=
                                  null
                              ? '${KiotaPayConstants.webUrl}storage/${authController.selectedStudent['user']['avatar']}'
                              : KiotaPayPngimage.profile,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                authController.userFullName,
                style: pbold_hsm.copyWith(color: Colors.white),
              ),
              const SizedBox(height: 5),
              Text(
                authController.userRole == 'parent'
                    ? 'Parent'
                    : authController.userRole,
                style: pmedium_md.copyWith(color: Colors.white),
              ),
              const SizedBox(height: 10),
              Text(
                authController.school['name'] ?? 'No School',
                style: pmedium_md.copyWith(color: Colors.white),
              ),
              if (authController.userRole == 'parent') ...[
                const SizedBox(height: 10),
                Obx(() => Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          authController.selectedStudent['user']
                                  ?['first_name'] ??
                              '',
                          style: pmedium_md.copyWith(color: Colors.white),
                        ),
                        const SizedBox(width: 8),
                        Icon(
                          authController.isStudentListExpanded.value
                              ? Icons.expand_less
                              : Icons.expand_more,
                          color: Colors.white,
                        ),
                      ],
                    )),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStudentList(AuthController authController) {
    return Material(
      elevation: 8,
      child: Container(
        color: Colors.white,
        child: Column(
          children: authController.allStudents.map((student) {
            final user = student['user'];
            final isSelected =
                authController.selectedStudent['id'] == student['id'];

            return ListTile(
              onTap: () async {
                authController.setSelectedStudent(student);
                authController.isStudentListExpanded.value = false;
                await refreshUserProfile(context);
                await Get.find<PerformanceController>().refreshData();

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Switched to ${user['first_name']} ${user['last_name']}',
                      style: const TextStyle(color: Colors.white),
                    ),
                    backgroundColor: ChanzoColors.primary,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                );
              },
              leading: CircleAvatar(
                backgroundImage: NetworkImage(
                  user?['avatar'] != null
                      ? '${KiotaPayConstants.webUrl}storage/${user['avatar']}'
                      : KiotaPayPngimage.profile,
                ),
              ),
              title: Text(
                "${user?['first_name']} ${user?['last_name']}",
                style: TextStyle(
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color:
                      isSelected ? ChanzoColors.primary : Colors.grey.shade800,
                ),
              ),
              subtitle: Text(
                student['class']?['name'] ?? 'No class',
                style: pregular_sm.copyWith(
                  color:
                      isSelected ? ChanzoColors.primary : Colors.grey.shade600,
                ),
              ),
              trailing: isSelected
                  ? const Icon(Icons.check, color: ChanzoColors.primary)
                  : null,
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildMenuItems(BuildContext context, AuthController authController) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // if (authController.hasPermission('student-view'))
          TextIconButton(
            onPressed: () {
              Navigator.of(context).pop(); // close drawer
              Get.offAll(() => KiotaPayDashboard('1'));
            },
            icon: LucideIcons.dollarSign,
            label: 'Finance',
          ),
          // if (authController.hasPermission('class_timetable-view'))
          // if (authController.hasRole('Branch Admin') || authController.hasRole('DOS') || authController.hasRole('Teacher') || authController.hasRole('Parent'))
          if (authController.hasRole('Parent'))
            TextIconButton(
              onPressed: () {
                if (Navigator.canPop(context)) {
                  Navigator.pop(context);
                }
                Get.offAll(() => KiotaPayDashboard('2'));
              },
              // onPressed: () => Get.to(() => ParentResultsHomeScreen()),
              icon: Icons.book,
              label: 'Academics',
            ),
          // if (authController.hasPermission('student-view'))
          TextIconButton(
            onPressed: () {
              Navigator.of(context).pop(); // close drawer
              // optional small delay
              Future.delayed(Duration(milliseconds: 100), () {
                Get.off(() => KiotaPayDashboard('1'));
              });
            },
            icon: LucideIcons.dollarSign,
            label: 'Finance',
          ),
          if (authController.hasPermission('notice_board-view'))
            TextIconButton(
              onPressed: () => Get.to(() => NoticesScreen()),
              icon: Icons.notifications,
              label: 'Notice Board',
            ),
          if (authController.hasPermission('calendar-view'))
            TextIconButton(
              onPressed: () => Get.to(() => CalendarScreen()),
              icon: Icons.calendar_month,
              label: 'Calendar',
            ),
          if (authController.hasPermission('class_timetable-view'))
            TextIconButton(
              onPressed: () {
                if (authController.hasRole('Parent')) {
                  Get.to(() => TimetableScreen(
                      classId: authController.selectedStudentClassId,
                      streamId: authController.selectedStudentStreamId));
                }
              },
              icon: Icons.history,
              label: 'Timetable',
            ),
          if (authController.hasPermission('class_timetable-view'))
            TextIconButton(
              onPressed: () => Get.to(() => StudentAttendanceScreen(
                  studentId: authController.selectedStudentId)),
              icon: Icons.watch,
              label: 'Attendance',
            ),
          if (authController.hasPermission('resource_center-view'))
            TextIconButton(
              onPressed: () {
                Get.to(() => ResourceCenterScreen());
              },
              icon: Icons.file_present,
              label: 'Resources',
            ),
          if (authController.hasPermission('homework-view'))
            TextIconButton(
              onPressed: () {
                Get.to(() => HomeworkScreen());
              },
              icon: Icons.assessment,
              label: 'Homework',
            ),
          if (authController.hasPermission('transport-view'))
            TextIconButton(
              onPressed: () => Get.to(() => KiotaPayCategories()),
              icon: Icons.bus_alert,
              label: 'Transport',
            ),
          ListTile(
            leading: ClipOval(
              child: Material(
                color: ChanzoColors.primary20,
                child: InkWell(
                  splashColor: ChanzoColors.primary,
                  onTap: () {},
                  child: const SizedBox(
                    width: 40,
                    height: 40,
                    child: Icon(Icons.dark_mode,
                        size: 20, color: ChanzoColors.primary),
                  ),
                ),
              ),
            ),
            title: Text("Dark_Mode".tr,
                style: pregular_md.copyWith(color: ChanzoColors.textgrey)),
            trailing: Obx(() => Switch(
                  activeColor: ChanzoColors.primary,
                  onChanged: (state) =>
                      Get.find<KiotaPayThemecontroler>().toggleTheme(),
                  value: Get.find<KiotaPayThemecontroler>().isdark.value,
                )),
          ),
          const Divider(height: 50, color: ChanzoColors.primary, thickness: 1),
          TextIconButton(
            onPressed: () => logout(context),
            icon: Icons.logout,
            label: 'Log out',
          ),
          TextIconButton(
            onPressed: () => Scaffold.of(context).closeDrawer(),
            icon: Icons.close,
            label: 'Close',
          ),
          Padding(
            padding: const EdgeInsets.only(left: 30.0, top: 30.0),
            child: Text(
              "App Version: $_appVersion",
              style: pregular_sm.copyWith(color: ChanzoColors.textgrey),
            ),
          ),
        ],
      ),
    );
  }

  double _calculateStudentListHeight(int studentCount) {
    const itemHeight = 72.0; // Approximate height per student item
    return studentCount * itemHeight;
  }

  double _getHeaderHeight() {
    return 260.0; // Adjust based on your actual header height
  }
}
