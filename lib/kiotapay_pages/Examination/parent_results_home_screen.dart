import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:kiotapay/globalclass/kiotapay_global_classes.dart';
import 'package:kiotapay/kiotapay_pages/Examination/student_analytics.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../globalclass/chanzo_color.dart';
import '../../globalclass/global_methods.dart';
import '../../globalclass/kiotapay_fontstyle.dart';
import '../../widgets/academic_sessions_filter_widget.dart';
import '../../widgets/custom_appbar.dart';
import '../../widgets/student_performance_dashboard.dart';
import '../academic_sessions/filter_controller.dart';
import '../kiotapay_drawer/kiotapay_drawer.dart';
import 'performance_controller.dart';

class ParentResultsHomeScreen extends StatefulWidget {
  const ParentResultsHomeScreen({super.key});

  @override
  State<ParentResultsHomeScreen> createState() =>
      _ParentResultsHomeScreenState();
}

class _ParentResultsHomeScreenState extends State<ParentResultsHomeScreen> {
  String? _selectedFilter;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    Get.put(PerformanceController());
    Get.find<PerformanceController>().loadPerformance();

    Get.put(FilterController());
    Get.find<FilterController>()
        .fetchSessions(authController.selectedStudentId);
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _onRefresh() async {
    await Get.find<PerformanceController>().refreshData();
    Get.find<FilterController>()
        .fetchSessions(authController.selectedStudentId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        key: _scaffoldKey,
        drawer: const KiotaPayDrawer(),
        appBar: KiotaPayAppBar(scaffoldKey: _scaffoldKey),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: RefreshIndicator(
          onRefresh: _onRefresh,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: 10),
                Text(
                  'Student Reports',
                  style: pmedium.copyWith(),
                ),
                SizedBox(height: 20),
                buildDownloadReportGrid(),
                SizedBox(height: 10),
                Text(
                  'Performance Summary',
                  style: pmedium.copyWith(),
                ),
                SizedBox(height: 10),
                StudentPerformanceDashboard().buildPerformanceGrid(),
                StudentPerformanceDashboard().buildSubjectPerformanceTable(),
                StudentPerformanceDashboard().buildSubjectPerformanceChart(),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () => Get.to(StudentAnalyticsScreen()),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: ChanzoColors.primary,
                    minimumSize: const Size(double.infinity, 50),
                  ),
                  child: const Text(
                    'Analytics',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(height: 20)
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Performance Summary Grid (2x2)
  Widget buildDownloadReportGrid() {
    return GridView.count(
      shrinkWrap: true,
      crossAxisCount: 2,
      childAspectRatio: 2.5,
      // Adjusted for horizontal layout
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      children: [
        _buildStatCard('Summative', 'summative', Icons.assessment),
        _buildStatCard('Formative', 'formative', Icons.assignment),
        _buildStatCard('Combined', 'combined', Icons.merge),
        _buildStatCard('Analytics', 'analytics', LucideIcons.lineChart),
      ],
    );
  }

  Widget _buildStatCard(String title, String param, IconData icon) {
    final isSelected = _selectedFilter == param;

    return InkWell(
      onTap: () {
        setState(() => _selectedFilter = param);
        if(param == 'analytics'){
          Get.to(StudentAnalyticsScreen());
          return;
        }

        _showFilterBottomSheet(title, param);
      },
      child: Container(
        decoration: BoxDecoration(
          color: isSelected ? ChanzoColors.primary : Theme.of(context).colorScheme.surface,
          border: Border.all(
            color: isSelected ? ChanzoColors.primary : Theme.of(context).colorScheme.onSurface,
            width: 1.5,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Icon(
                icon,
                size: 24,
                color: isSelected ? Colors.white : Theme.of(context).colorScheme.onSurface,
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: isSelected ? Colors.white : Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showFilterBottomSheet(String title, String param) {
    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(16.0),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'View $title Results',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            AcademicFilterWidget(),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                if(param == 'analytics')
                  Get.to(StudentAnalyticsScreen());
                _onContinuePressed(param);
                },
              style: ElevatedButton.styleFrom(
                backgroundColor: ChanzoColors.primary,
                minimumSize: const Size(double.infinity, 50),
              ),
              child: const Text(
                'Continue',
                style: TextStyle(color: Colors.white),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
      isScrollControlled: true,
    );
  }

  void _onContinuePressed(String param) {
    Get.back();
    _processSelectedFilter(param);
  }

  void _processSelectedFilter(String filterType) {
    final filter = Get.find<FilterController>();

    final termId = filter.selectedTerm.value?.id;
    final sessionId = filter.selectedSession.value!.academicSessionId;
    print('Selected filter: $filterType');
    print('Selected SessionID: $sessionId');
    print('Selected TermID: $termId');
    // return;

    if (sessionId < 0) {
      awesomeDialog(
          context,
          "Select Academic Session",
          "Please select academic session",
          true,
          DialogType.info,
          ChanzoColors.secondary)
        ..show();
    };

    Get.find<PerformanceController>().downloadExamReports(context,
        studentId: authController.selectedStudentId,
        reportType: filterType,
    termId:termId, academicSessionId: sessionId);
  }
}
