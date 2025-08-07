import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:kiotapay/globalclass/kiotapay_global_classes.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../globalclass/chanzo_color.dart';
import '../../globalclass/global_methods.dart';
import '../../globalclass/kiotapay_fontstyle.dart';
import '../../widgets/academic_sessions_filter_widget.dart';
import '../../widgets/grid_card.dart';
import '../../widgets/student_performance_dashboard.dart';
import '../academic_sessions/filter_controller.dart';
import 'performance_controller.dart';

class StudentAnalyticsScreen extends StatefulWidget {
  const StudentAnalyticsScreen({super.key});

  @override
  State<StudentAnalyticsScreen> createState() =>
      _StudentAnalyticsScreenState();
}

class _StudentAnalyticsScreenState extends State<StudentAnalyticsScreen> {
  String? _selectedFilter;

  @override
  void initState() {
    super.initState();
    Get.put(PerformanceController());
    Get.find<PerformanceController>().loadStudentExamTrend();

    // Get.put(FilterController());
    // Get.find<FilterController>()
    //     .fetchSessions(authController.selectedStudentId);
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
      appBar: AppBar(
        title: const Text('Analytics'),
        centerTitle: false,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: RefreshIndicator(
          onRefresh: _onRefresh,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: 20),
                buildDownloadReportGrid(),
                SizedBox(height: 10),
                StudentPerformanceDashboard().buildExamTrendChart(),
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
        GridCard(
          title: 'Subjects',
          param: 'subjects',
          icon: LucideIcons.book,
          isSelected: _selectedFilter == 'subjects',
          onTap: () {
            setState(() {
              _selectedFilter = 'subjects';
            });
          },
        ),
        GridCard(
          title: 'Trends',
          param: 'trends',
          icon: LucideIcons.barChart,
          isSelected: _selectedFilter == 'trends',
          onTap: () {
            setState(() {
              _selectedFilter = 'trends';
            });
          },
        ),
        GridCard(
          title: 'Best',
          param: 'best',
          icon: LucideIcons.arrowBigUp,
          isSelected: _selectedFilter == 'best',
          onTap: () {
            setState(() {
              _selectedFilter = 'best';
            });
          },
        ),
        GridCard(
          title: 'Poor',
          param: 'poor',
          icon: LucideIcons.arrowBigDown,
          isSelected: _selectedFilter == 'poor',
          onTap: () {
            setState(() {
              _selectedFilter = 'poor';
            });
          },
        ),
      ],
    );
  }

  Widget _buildGridCard(String title, String param, IconData icon) {
    final isSelected = _selectedFilter == param;

    return InkWell(
      onTap: () {
        print("clicked");
      },
      child: Container(
        decoration: BoxDecoration(
          color: isSelected ? ChanzoColors.primary : Colors.white,
          border: Border.all(
            color: isSelected ? ChanzoColors.primary : Colors.grey.shade300,
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
                color: isSelected ? Colors.white : ChanzoColors.primary,
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: isSelected ? Colors.white : Colors.black,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
