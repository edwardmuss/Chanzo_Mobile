import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shimmer/shimmer.dart';

import '../../globalclass/chanzo_color.dart';
import '../../widgets/custom_appbar.dart';
import '../../widgets/error.dart';
import '../kiotapay_drawer/kiotapay_drawer.dart';
import '../kiotapay_authentication/AuthController.dart';
import 'teacher_dashboard_controller.dart'; // Import your new controller

class TeacherHome extends StatefulWidget {
  const TeacherHome({super.key});

  @override
  State<TeacherHome> createState() => _TeacherHomeState();
}

class _TeacherHomeState extends State<TeacherHome> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final AuthController authController = Get.find<AuthController>();
  final TeacherDashboardController dashboardController = Get.put(TeacherDashboardController());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      drawer: const KiotaPayDrawer(),
      appBar: KiotaPayAppBar(scaffoldKey: _scaffoldKey),
      body: RefreshIndicator(
        onRefresh: dashboardController.fetchDashboard,
        color: ChanzoColors.primary,
        child: Obx(() {
          if (dashboardController.isLoading.value) {
            return _buildShimmerLoader(context);
          }

          if (dashboardController.hasError.value) {
            return SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: SizedBox(
                height: MediaQuery.of(context).size.height * 0.7,
                child: Center(
                  child: ErrorWidgetUniversal(
                    title: "Oops!",
                    description: dashboardController.errorMessage.value,
                    onRetry: dashboardController.fetchDashboard,
                  ),
                ),
              ),
            );
          }

          return SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Welcome Header
                Text(
                  "Welcome, ${authController.userFirstName}",
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                Text(
                  dashboardController.branchName.value,
                  style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                ),
                const SizedBox(height: 24),

                // Class Overview Section
                if (dashboardController.classOverviews.isNotEmpty) ...[
                  const Text(
                    "My Class Overview",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 12),
                  ...dashboardController.classOverviews.map((classData) => _buildClassCard(classData)).toList(),
                  const SizedBox(height: 24),
                ],

                // Subject Performance Section
                if (dashboardController.subjectPerformances.isNotEmpty) ...[
                  const Text(
                    "Subject Performance",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 12),
                  _buildSubjectsGrid(),
                ],

                // Empty state if nothing exists
                if (dashboardController.classOverviews.isEmpty && dashboardController.subjectPerformances.isEmpty)
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 40.0),
                      child: Text(
                        "No performance data available yet.",
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                    ),
                  )
              ],
            ),
          );
        }),
      ),
    );
  }

  // --- WIDGETS ---

  Widget _buildClassCard(dynamic classData) {
    final className = classData['class'] ?? 'Unknown';
    final streamName = classData['stream'] ?? '';
    final studentCount = classData['student_count'] ?? 0;
    final meanScore = classData['mean_score']?.toString() ?? 'N/A';
    final meanGrade = classData['mean_grade']?.toString() ?? 'N/A';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: ChanzoColors.primary,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: ChanzoColors.primary.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "$className $streamName",
                style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  "$studentCount Students",
                  style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          const Text(
            "Mean Score",
            style: TextStyle(color: Colors.white70, fontSize: 14),
          ),
          const SizedBox(height: 4),
          Text(
            "${meanScore} ($meanGrade)",
            style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildSubjectsGrid() {
    // Detect Dark Mode
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.1,
      ),
      itemCount: dashboardController.subjectPerformances.length,
      itemBuilder: (context, index) {
        final subjectData = dashboardController.subjectPerformances[index];
        final subjectName = subjectData['subject'] ?? 'Unknown';
        final className = subjectData['class'] ?? '';
        final streamName = subjectData['stream'] ?? '';
        final meanScore = double.tryParse(subjectData['mean_score']?.toString() ?? '0') ?? 0.0;
        final meanGrade = subjectData['mean_grade']?.toString() ?? 'N/A';

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            // Dynamic Card Background
            color: isDark ? Theme.of(context).cardColor : Colors.white,
            borderRadius: BorderRadius.circular(16),
            // 3. Dynamic Border Color
            border: Border.all(
              color: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
            ),
            // Remove shadows in dark mode for a flatter, cleaner look
            boxShadow: isDark ? [] : [
              BoxShadow(
                color: Colors.grey.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "$className $streamName",
                    style: TextStyle(
                        fontSize: 11,
                        color: isDark ? ChanzoColors.secondary : ChanzoColors.primary, // Orange in dark mode looks great!
                        fontWeight: FontWeight.bold
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subjectName,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, height: 1.2),
                    // Note: Removed hardcoded color here so it auto-switches to White in Dark Mode
                  ),
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    "Score",
                    style: TextStyle(
                        color: isDark ? Colors.white54 : Colors.grey, // Muted text for dark mode
                        fontSize: 12
                    ),
                  ),
                  Text(
                    "${meanScore.toStringAsFixed(1)} ($meanGrade)",
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      // Bright colors like Green/Orange/Red naturally look great in Dark Mode
                      color: meanScore >= 80 ? Colors.green : (meanScore >= 50 ? Colors.orange : Colors.red),
                    ),
                  ),
                ],
              )
            ],
          ),
        );
      },
    );
  }

  Widget _buildShimmerLoader(BuildContext context) {
    // Detect Dark Mode
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    // Define dynamic Shimmer colors
    final Color baseColor = isDark ? Colors.grey.shade800 : Colors.grey.shade300;
    final Color highlightColor = isDark ? Colors.grey.shade700 : Colors.grey.shade100;
    final Color containerColor = isDark ? Colors.grey.shade900 : Colors.white;

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Shimmer.fromColors(
            baseColor: baseColor,
            highlightColor: highlightColor,
            child: Container(width: 150, height: 24, color: containerColor),
          ),
          const SizedBox(height: 24),
          Shimmer.fromColors(
            baseColor: baseColor,
            highlightColor: highlightColor,
            child: Container(
              width: double.infinity,
              height: 140,
              decoration: BoxDecoration(color: containerColor, borderRadius: BorderRadius.circular(16)),
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: Shimmer.fromColors(
                  baseColor: baseColor,
                  highlightColor: highlightColor,
                  child: Container(height: 120, decoration: BoxDecoration(color: containerColor, borderRadius: BorderRadius.circular(16))),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Shimmer.fromColors(
                  baseColor: baseColor,
                  highlightColor: highlightColor,
                  child: Container(height: 120, decoration: BoxDecoration(color: containerColor, borderRadius: BorderRadius.circular(16))),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: Shimmer.fromColors(
                  baseColor: baseColor,
                  highlightColor: highlightColor,
                  child: Container(height: 120, decoration: BoxDecoration(color: containerColor, borderRadius: BorderRadius.circular(16))),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Shimmer.fromColors(
                  baseColor: baseColor,
                  highlightColor: highlightColor,
                  child: Container(height: 120, decoration: BoxDecoration(color: containerColor, borderRadius: BorderRadius.circular(16))),
                ),
              ),
            ],
          )
        ],
      ),
    );
  }
}