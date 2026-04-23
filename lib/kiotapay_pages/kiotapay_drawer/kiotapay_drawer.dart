import 'dart:convert';

import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:bootstrap_icons/bootstrap_icons.dart';
import 'package:chanzo/kiotapay_pages/assessment/formative/formative_dashboard_screen.dart';
import 'package:chanzo/kiotapay_pages/assessment/reports/class_exam_performance_screen.dart';
import 'package:chanzo/kiotapay_pages/assessment/reports/class_stream_performance_screen.dart';
import 'package:chanzo/kiotapay_pages/assessment/reports/subject_performance_screen.dart';
import 'package:chanzo/kiotapay_pages/homework/teacher_homework_screen.dart';
import 'package:chanzo/kiotapay_pages/students/student_list_screen.dart';
import 'package:chanzo/kiotapay_pages/teachers/scheme_of_work/scheme_of_work_screen.dart';
import 'package:chanzo/kiotapay_pages/subjects/teacher_classes_subjects_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_initicon/flutter_initicon.dart';
import 'package:get/get.dart';
import 'package:chanzo/globalclass/chanzo_color.dart';
import 'package:chanzo/globalclass/kiotapay_global_classes.dart';
import 'package:chanzo/globalclass/kiotapay_fontstyle.dart';
import 'package:chanzo/kiotapay_models/user_model.dart';
import 'package:chanzo/kiotapay_pages/Examination/parent_results_home_screen.dart';
import 'package:chanzo/kiotapay_pages/calendar/calendar_screen.dart';
import 'package:chanzo/kiotapay_pages/homework/homework_screen.dart';
import 'package:chanzo/kiotapay_pages/kiota_categories/list.dart';
import 'package:chanzo/globalclass/text_icon_button.dart';
import 'package:chanzo/kiotapay_pages/kiotapay_dahsboard/kiotapay_dahsboard.dart';
import 'package:chanzo/kiotapay_pages/kiotapay_settings/kiotapay_settings.dart';
import 'package:chanzo/kiotapay_pages/notice_board/notice_board_screen.dart';
import 'package:chanzo/kiotapay_pages/timetable/timetable_screen.dart';
import 'package:chanzo/kiotapay_theme/kiotapay_themecontroller.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:nb_utils/nb_utils.dart' hide DialogType;
import 'package:shared_preferences/shared_preferences.dart';

import '../../globalclass/global_methods.dart';
import '../../globalclass/kiotapay_constants.dart';
import '../../globalclass/kiotapay_icons.dart';
import '../Examination/performance_controller.dart';
import '../assessment/exams/exams_dashboard_screen.dart';
import '../attendance/class_attendance_screen.dart';
import '../attendance/student_attendance.dart';
import '../finance/parent_dashboard.dart';
import '../kiota_teams/list.dart';
import 'package:http/http.dart' as http;

import '../kiotapay_authentication/AuthController.dart';
import '../resource_center/resource_center_screen.dart';
import '../teachers/lesson_plan/lesson_plan_screen.dart';
import '../timetable/timetable_filter_screen.dart';

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
                            authController.studentsInActiveBranch.length)
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
      // Wrap the entire UI inside Obx so it updates instantly when switching schools
      child: Obx(() {
        // Extract variables for cleaner code
        final coverImage = authController.user['cover_image'];
        final avatar = authController.user['avatar'];
        final schoolName = authController.schoolName;
        final isParent = authController.userRole == 'parent';
        final studentAvatar = authController.selectedStudent['user']?['avatar'];

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.only(top: 40, bottom: 20),
          decoration: BoxDecoration(
            // 2. Safely toggle between NetworkImage and AssetImage
            image: DecorationImage(
              image: (coverImage != null && coverImage.toString().isNotEmpty)
                  ? NetworkImage('${KiotaPayConstants.webUrl}storage/$coverImage')
                  : AssetImage(KiotaPayPngimage.card) as ImageProvider,
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
                      backgroundColor: Colors.grey.shade300,
                      backgroundImage: (avatar != null && avatar.toString().isNotEmpty)
                          ? NetworkImage('${KiotaPayConstants.webUrl}storage/$avatar')
                          : AssetImage(KiotaPayPngimage.profile) as ImageProvider,
                    ),
                    if (isParent && authController.selectedStudent.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.all(4), // Slightly smaller padding looks better
                        decoration: BoxDecoration(
                          color: ChanzoColors.primary,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white,
                            width: 2,
                          ),
                        ),
                        child: CircleAvatar(
                          radius: 14, // Slightly larger radius for the nested avatar
                          backgroundColor: Colors.grey.shade300,
                          backgroundImage: (studentAvatar != null && studentAvatar.toString().isNotEmpty)
                              ? NetworkImage('${KiotaPayConstants.webUrl}storage/$studentAvatar')
                              : AssetImage(KiotaPayPngimage.profile) as ImageProvider,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 10),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Text(
                    authController.userFullName,
                    textAlign: TextAlign.center,
                    style: pbold_hsm.copyWith(color: Colors.white),
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  isParent ? 'Parent' : authController.userRole,
                  textAlign: TextAlign.center,
                  style: pmedium_md.copyWith(color: Colors.white),
                ),
                const SizedBox(height: 10),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Text(
                    schoolName,
                    textAlign: TextAlign.center,
                    style: pmedium_md.copyWith(color: Colors.white),
                  ),
                ),
                if (isParent) ...[
                  const SizedBox(height: 10),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // 3. Flexible prevents long names from pushing the icon off-screen
                        Flexible(
                          child: Text(
                            authController.selectedStudentName,
                            textAlign: TextAlign.center,
                            overflow: TextOverflow.ellipsis,
                            style: pmedium_md.copyWith(color: Colors.white),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Icon(
                          authController.isStudentListExpanded.value
                              ? Icons.expand_less
                              : Icons.expand_more,
                          color: Colors.white,
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      }),
    );
  }

  Widget _buildStudentList(AuthController authController) {
    return Material(
      elevation: 8,
      child: Container(
        color: Colors.white,
        child: Column(
          children: authController.studentsInActiveBranch.map((student) {
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
    final isParent = authController.userRole == 'parent';
    final isTeacher = authController.userRole == 'teacher';
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    // Set dynamic default colors based on the theme
    final Color defaultIconBg = isDark ? Colors.white12 : ChanzoColors.primary20;
    // Orange for dark mode, Primary for light mode
    final Color defaultIconColor = isDark ? ChanzoColors.secondary : ChanzoColors.primary;
    final Color defaultChevronColor = isDark ? Colors.white54 : ChanzoColors.primary;
    final Color defaultTextColor = isDark ? Colors.white : ChanzoColors.textgrey;
    final Color defaultSplashColor = isDark ? ChanzoColors.secondary.withOpacity(0.3) : ChanzoColors.primary;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ==========================================
          // UNIVERSAL TOP MENU (Everyone sees this)
          // ==========================================
          if (authController.shouldShowSwitcherButton)
            TextIconButton(
              onPressed: () async {
                await openContextSwitcher(
                  context,
                  onContextChanged: () async {
                    authController.isStudentListExpanded.value = false;
                    authController.ensureSelectedStudentInActiveBranch();
                    await refreshUserProfile(context);
                    await Get.find<PerformanceController>().refreshData();
                  },
                  onStudentChanged: () async {
                    authController.isStudentListExpanded.value = false;
                    await refreshUserProfile(context);
                    await Get.find<PerformanceController>().refreshData();
                  },
                );
                if (Navigator.canPop(context)) Navigator.pop(context);
              },
              icon: Icons.swap_horiz,
              label: 'Switch Account',
            ),

          // ==========================================
          // PARENT SPECIFIC MENU
          // ==========================================
          if (isParent) ...[
            TextIconButton(
              onPressed: () {
                Navigator.of(context).pop();
                Get.offAll(() => KiotaPayDashboard('1'));
              },
              icon: LucideIcons.dollarSign,
              label: 'Finance',
            ),
            TextIconButton(
              onPressed: () {
                Navigator.of(context).pop();
                Get.offAll(() => KiotaPayDashboard('2'));
              },
              icon: Icons.book,
              label: 'Academics',
            ),
          ],

          // ==========================================
          // TEACHER SPECIFIC MENU
          // ==========================================
          if (isTeacher) ...[
            TextIconButton(
              onPressed: () {
                Navigator.of(context).pop();
                Get.to(() => TeacherClassesSubjectsScreen());
              },
              icon: BootstrapIcons.people,
              label: 'My Classes & Subjects',
            ),

            TextIconButton(
              onPressed: () {
                Navigator.of(context).pop();
                Get.to(() => StudentListScreen());
              },
              icon: BootstrapIcons.people,
              label: 'My Students',
            ),

            Theme(
              data: Theme.of(context).copyWith(
                dividerTheme: const DividerThemeData(
                  thickness: 0.5,
                  space: 0, // removes extra spacing
                ),
              ),
              child: ExpansionTile(
                shape: Border(),              // removes top/bottom border
                collapsedShape: Border(),     // removes collapsed border
                // tilePadding: EdgeInsets.zero, // prevents double padding
                leading: ClipOval(
                  child: Container(
                    color: defaultIconBg,
                    width: 40,
                    height: 40,
                    child: Icon(Icons.assessment_outlined, size: 20, color: defaultIconColor),
                  ),
                ),
                title: Text('Assessments', style: pregular_md.copyWith(color: defaultTextColor)),
                childrenPadding: const EdgeInsets.only(left: 16),
                children: [
              
                  /// --- Assessment Types ---
                  ExpansionTile(
                    title: Text('Assessment Types', style: pregular_md.copyWith(color: defaultTextColor)),
                    childrenPadding: const EdgeInsets.only(left: 40),
                    children: [
                      ListTile(
                        title: Text('Formative Assessments', style: pregular_md.copyWith(color: defaultTextColor)),
                        onTap: () => Get.to(() => const FormativeDashboardScreen()),
                      ),
                      ListTile(
                        title: Text('Summative Exams', style: pregular_md.copyWith(color: defaultTextColor)),
                        onTap: () => Get.to(() => const ExamsDashboardScreen()),
                      ),
                    ],
                  ),
              
                  /// --- Performance Reports ---
                  ExpansionTile(
                    title: Text('Performance Reports', style: pregular_md.copyWith(color: defaultTextColor)),
                    childrenPadding: const EdgeInsets.only(left: 40),
                    children: [
                      ListTile(
                        title: Text('Class Performance', style: pregular_md.copyWith(color: defaultTextColor)),
                        onTap: () => Get.to(() => const ClassExamPerformanceScreen()),
                      ),
                      ListTile(
                        title: Text('Subject Performance', style: pregular_md.copyWith(color: defaultTextColor)),
                        onTap: () => Get.to(() => const SubjectPerformanceScreen()),
                      ),
                      ListTile(
                        title: Text('Class Stream Report', style: pregular_md.copyWith(color: defaultTextColor)),
                        onTap: () => Get.to(() => const ClassStreamPerformanceScreen()),
                      ),
                    ],
                  ),
                ],
              ),
            )
            // Add more teacher-specific quick links here
          ],

          // ==========================================
          // PERMISSION-BASED MENU (Shared modules)
          // ==========================================
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

          // --- TIMETABLE MENU ---
          if (authController.hasPermission('class_timetable-view'))
            if (isParent)
              TextIconButton(
                onPressed: () {
                  Navigator.pop(context);
                  Get.to(() => TimetableScreen(
                    classId: authController.selectedStudentClassId,
                    streamId: authController.selectedStudentStreamId,
                    isTeacherTimetable: false,
                  ));
                },
                icon: Icons.history,
                label: 'Timetable',
              )
            else if (isTeacher)
              Theme(
                data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                child: ExpansionTile(
                  leading: ClipOval(
                    child: Container(
                      color: defaultIconBg,
                      width: 40,
                      height: 40,
                      child: Icon(Icons.history, size: 20, color: defaultIconColor),
                    ),
                  ),
                  title: Text(
                    'Timetables',
                    style: pregular_md.copyWith(color: defaultTextColor),
                  ),
                  childrenPadding: const EdgeInsets.only(left: 56), // Indent sub-items
                  children: [
                    ListTile(
                      dense: true,
                      title: Text('My Timetable', style: pregular_md.copyWith(color: defaultTextColor)),
                      onTap: () {
                        Navigator.pop(context); // Close Drawer
                        Get.to(() => const TimetableScreen(
                          isTeacherTimetable: true, // Flag for personal timetable
                        ));
                      },
                    ),
                    ListTile(
                      dense: true,
                      title: Text('Class Timetables', style: pregular_md.copyWith(color: defaultTextColor),),
                      onTap: () {
                        Navigator.pop(context); // Close Drawer
                        Get.to(() => const TimetableFilterScreen()); // Go to filter screen
                      },
                    ),
                  ],
                ),
              ),

          if (authController.hasPermission('student_attendance-view'))
            TextIconButton(
              onPressed: () {
                if (isParent) {
                  // Parents view their specific child's history
                  Get.to(() => StudentAttendanceScreen(
                      studentId: authController.selectedStudentId));
                } else if (isTeacher) {
                  // Teachers view/mark attendance for a whole class
                  Get.to(() => const ClassAttendanceScreen());
                }
              },
              icon: Icons.watch, // Or Icons.checklist
              label: 'Attendance',
            ),

          if (authController.hasPermission('resource_center-view'))
            TextIconButton(
              onPressed: () => Get.to(() => ResourceCenterScreen()),
              icon: Icons.file_present,
              label: 'Resources',
            ),

          if (authController.hasPermission('homework-view'))
            TextIconButton(
              onPressed: () {
                if (isParent) {
                  Get.to(() => HomeworkScreen());
                } else if (isTeacher) {
                  Get.to(() => TeacherHomeworkScreen());
                }
              },
              icon: Icons.assessment,
              label: 'Homework',
            ),

          if (authController.hasPermission('lesson_plan-view'))
            TextIconButton(
              onPressed: () {
                Get.to(() => LessonPlanScreen());
              },
              icon: Icons.dialpad_rounded,
              label: 'Lesson Plan',
            ),

          if (authController.hasPermission('record_of_work-view'))
            TextIconButton(
              onPressed: () {
                Get.to(() => SchemeOfWorkScreen());
              },
              icon: Icons.speed,
              label: 'Scheme of Work',
            ),

          // ==========================================
          // UNIVERSAL BOTTOM MENU (Settings/Logout)
          // ==========================================
          const Divider(height: 30, color: ChanzoColors.primary, thickness: 1),

          ListTile(
            leading: ClipOval(
              child: Material(
                color: defaultIconBg,
                child: InkWell(
                  splashColor: defaultSplashColor,
                  onTap: () {},
                  child: SizedBox(
                    width: 40,
                    height: 40,
                    child: Icon(Icons.dark_mode, size: 20, color: defaultIconColor),
                  ),
                ),
              ),
            ),
            title: Text("Dark Mode", style: pregular_md.copyWith(color: defaultTextColor)),
            trailing: Obx(() => Switch(
              activeColor: ChanzoColors.primary,
              onChanged: (state) => Get.find<KiotaPayThemecontroler>().toggleTheme(),
              value: Get.find<KiotaPayThemecontroler>().isdark.value,
            )),
          ),

          TextIconButton(
            onPressed: () => logout(context),
            icon: Icons.logout,
            label: 'Log out',
          ),

          Padding(
            padding: const EdgeInsets.only(left: 30.0, top: 20.0),
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
