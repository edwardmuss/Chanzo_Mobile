import 'package:chanzo/globalclass/global_methods.dart';
import 'package:chanzo/kiotapay_pages/subjects/manage_subject_screen.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shimmer/shimmer.dart';

import '../../globalclass/chanzo_color.dart';
import '../../globalclass/kiotapay_constants.dart';
import '../../utils/dio_helper.dart';
import '../../widgets/error.dart';
import '../kiotapay_authentication/AuthController.dart'; // Ensure this is imported

class TeacherClassesSubjectsScreen extends StatefulWidget {
  const TeacherClassesSubjectsScreen({super.key});

  @override
  State<TeacherClassesSubjectsScreen> createState() => _TeacherClassesSubjectsScreenState();
}

class _TeacherClassesSubjectsScreenState extends State<TeacherClassesSubjectsScreen> {
  // Initialize your AuthController to access the school/curriculum details safely
  final AuthController authController = Get.find<AuthController>();

  bool _isLoading = true;
  bool _hasError = false;
  List<dynamic> _assignments = [];
  int? _curriculumId;

  @override
  void initState() {
    super.initState();
    // Safely extract the curriculum ID once during init
    _curriculumId = authController.school['curriculum_id'];
    _fetchAssignments();
  }

  Future<void> _fetchAssignments() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    try {
      final response = await DioHelper().get(KiotaPayConstants.getClassesStreamSubject);

      if (response.statusCode == 200 && response.data['success'] == true) {
        setState(() {
          _assignments = response.data['data'] ?? [];
          _isLoading = false;
        });
      } else {
        setState(() {
          _hasError = true;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Error fetching teacher assignments: $e");
      setState(() {
        _hasError = true;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("My Classes & Subjects"),
        elevation: 0,
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return _buildShimmerLoader();
    }

    if (_hasError) {
      return Center(
        child: ErrorWidgetUniversal(
          title: "Oops! Something went wrong.",
          description: "Failed to load your assigned classes and subjects.\nPlease try again.",
          onRetry: _fetchAssignments,
        ),
      );
    }

    if (_assignments.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.class_outlined, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              "No Assignments Found",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey.shade800),
            ),
            const SizedBox(height: 8),
            Text(
              "You have not been assigned to any classes yet.",
              style: TextStyle(color: Colors.grey.shade600),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _fetchAssignments,
              icon: const Icon(Icons.refresh),
              label: const Text("Refresh"),
              style: ElevatedButton.styleFrom(
                backgroundColor: ChanzoColors.primary,
                foregroundColor: Colors.white,
              ),
            )
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _fetchAssignments,
      color: ChanzoColors.primary,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: _assignments.length,
        itemBuilder: (context, index) {
          final assignment = _assignments[index];
          return _buildAssignmentCard(assignment);
        },
      ),
    );
  }

  Widget _buildAssignmentCard(Map<String, dynamic> assignment) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final classId = assignment['class_id'];
    final className = assignment['class_name'] ?? 'Unknown Class';
    final streamName = assignment['stream_name'] ?? 'Unknown Stream';
    final subjects = (assignment['subjects'] as List<dynamic>?) ?? [];

    // Check if the curriculum is 1
    final bool isCBC = _curriculumId == 1;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: isDark ? 0 : 2,
      color: isDark ? Theme.of(context).cardColor : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: isDark ? Colors.grey.shade800 : Colors.transparent),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Class and Stream Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: ChanzoColors.primary.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.meeting_room, color: ChanzoColors.primary),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "$className ($streamName)",
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "${subjects.length} Subjects Assigned",
                        style: TextStyle(
                          fontSize: 13,
                          color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Divider(height: 1, color: isDark ? Colors.grey.shade800 : Colors.grey.shade200),
            const SizedBox(height: 16),

            // Subjects List (Wrap for chips)
            if (subjects.isEmpty)
              Text("No subjects assigned for this class.", style: TextStyle(color: Colors.grey.shade500, fontStyle: FontStyle.italic))
            else
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: subjects.map((subject) {
                  final subjectName = subject['subject_name'] ?? 'Unknown Subject';
                  final subjectId = subject['subject_id'];

                  return Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(8),
                      // Only allow tapping if curriculum_id is 1
                      onTap: isCBC ? () {
                        // TODO: Navigate to the Curriculum Management Screen for this specific subject
                        Get.to(() => ManageSubjectScreen(
                          classId: classId,
                          subjectId: subjectId,
                          subjectName: subjectName,
                        ));
                      } : null,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: isDark ? Colors.grey.shade900 : Colors.grey.shade50,
                          border: Border.all(
                              color: isCBC
                                  ? ChanzoColors.primary.withOpacity(0.5) // Highlight border if clickable
                                  : (isDark ? Colors.grey.shade700 : Colors.grey.shade200)
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.book_outlined, size: 14, color: ChanzoColors.secondary),
                            const SizedBox(width: 6),
                            Text(
                              subjectName,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: isDark ? Colors.white : Colors.grey.shade800,
                              ),
                            ),
                            // Show a tiny gear/edit icon so the teacher knows they can click it
                            if (isCBC) ...[
                              const SizedBox(width: 6),
                              Icon(Icons.settings_suggest, size: 14, color: ChanzoColors.primary.withOpacity(0.8)),
                            ]
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildShimmerLoader() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 4,
      itemBuilder: (_, __) => Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: Shimmer.fromColors(
          baseColor: isDark ? Colors.grey.shade800 : Colors.grey.shade300,
          highlightColor: isDark ? Colors.grey.shade700 : Colors.grey.shade100,
          child: Container(
            height: 140,
            decoration: BoxDecoration(
              color: isDark ? Colors.grey.shade900 : Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ),
      ),
    );
  }
}