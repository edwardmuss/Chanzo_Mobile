import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shimmer/shimmer.dart';

import '../../../globalclass/chanzo_color.dart';
import '../../../globalclass/kiotapay_constants.dart';
import '../../../utils/dio_helper.dart';
import '../../../widgets/error.dart';
import 'formative_assessment_screen.dart';

class FormativeDashboardScreen extends StatefulWidget {
  const FormativeDashboardScreen({super.key});

  @override
  State<FormativeDashboardScreen> createState() => _FormativeDashboardScreenState();
}

class _FormativeDashboardScreenState extends State<FormativeDashboardScreen> {
  bool _isLoading = true;
  bool _hasError = false;

  List<dynamic> _classSubjects = [];
  List<dynamic> _currentSubjects = [];
  List<dynamic> _activities = [];

  int? _selectedClassId;
  int? _selectedSubjectId;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData({int? classId, int? subjectId}) async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    try {
      final Map<String, dynamic> queryParams = {};
      if (classId != null) queryParams['class_id'] = classId;
      if (subjectId != null) queryParams['subject_id'] = subjectId;

      final response = await DioHelper().get(
        KiotaPayConstants.formativeDashboard,
        queryParameters: queryParams.isNotEmpty ? queryParams : null,
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        final data = response.data['data'];

        setState(() {
          _classSubjects = data['class_subjects'] ?? [];
          _activities = data['activities'] ?? [];

          // Sync selections from API
          _selectedClassId = data['selected_class_id'];
          _selectedSubjectId = data['selected_subject_id'];

          // If a class is selected, populate the subjects dropdown
          if (_selectedClassId != null) {
            _populateSubjectsForClass(_selectedClassId!);
          } else {
            _currentSubjects = [];
          }

          _isLoading = false;
        });
      } else {
        setState(() {
          _hasError = true;
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _hasError = true;
        _isLoading = false;
      });
    }
  }

  void _populateSubjectsForClass(int classId) {
    final classObj = _classSubjects.firstWhere((c) => c['id'] == classId, orElse: () => null);
    if (classObj != null) {
      _currentSubjects = classObj['subjects'] ?? [];
    } else {
      _currentSubjects = [];
    }
  }

  void _onClassSelected(int? classId) {
    if (classId == null) return;

    setState(() {
      _selectedClassId = classId;
      _selectedSubjectId = null; // Reset subject when class changes
      _activities = []; // Clear activities until a new subject is selected
      _populateSubjectsForClass(classId);
    });
  }

  void _onSubjectSelected(int? subjectId) {
    if (subjectId == null) return;

    setState(() {
      _selectedSubjectId = subjectId;
    });

    // Fetch the activities for this specific class and subject!
    _fetchData(classId: _selectedClassId, subjectId: _selectedSubjectId);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Formative Assessments"),
        elevation: 0,
      ),
      body: Column(
        children: [
          // Top Filter Section
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? Theme.of(context).cardColor : ChanzoColors.primary.withOpacity(0.05),
              border: Border(bottom: BorderSide(color: isDark ? Colors.grey.shade800 : Colors.grey.shade200)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Select Class & Subject",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    // Class Dropdown
                    Expanded(
                      child: _buildDropdown(
                        label: "Class",
                        items: _classSubjects,
                        value: _selectedClassId,
                        onChanged: _onClassSelected,
                        isDark: isDark,
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Subject Dropdown
                    Expanded(
                      child: _buildDropdown(
                        label: "Subject",
                        items: _currentSubjects,
                        value: _selectedSubjectId,
                        onChanged: _currentSubjects.isEmpty ? null : _onSubjectSelected,
                        isDark: isDark,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Main Content Area
          Expanded(
            child: _isLoading
                ? _buildShimmerLoader(context)
                : _hasError
                ? ErrorWidgetUniversal(
              title: "Failed to load data",
              description: "Check your connection and try again.",
              onRetry: () => _fetchData(classId: _selectedClassId, subjectId: _selectedSubjectId),
            )
                : _selectedClassId == null || _selectedSubjectId == null
                ? _buildInitialEmptyState(isDark)
                : _activities.isEmpty
                ? _buildNoActivitiesState(isDark)
                : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _activities.length,
              itemBuilder: (context, index) {
                final activity = _activities[index];
                return _buildActivityCard(activity, isDark);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDropdown({
    required String label,
    required List<dynamic> items,
    required int? value,
    required Function(int?)? onChanged,
    required bool isDark,
  }) {
    return DropdownButtonFormField<int>(
      isExpanded: true,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: isDark ? Colors.grey.shade400 : Colors.grey.shade600),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: isDark ? Colors.grey.shade900 : Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      ),
      value: value,
      dropdownColor: isDark ? Colors.grey.shade900 : Colors.white,
      items: items.map<DropdownMenuItem<int>>((item) {
        return DropdownMenuItem<int>(
          value: item['id'],
          child: Text(item['name'] ?? '', overflow: TextOverflow.ellipsis),
        );
      }).toList(),
      onChanged: onChanged,
    );
  }

  Widget _buildActivityCard(Map<String, dynamic> activity, bool isDark) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: isDark ? 0 : 2,
      color: isDark ? Theme.of(context).cardColor : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: isDark ? Colors.grey.shade800 : Colors.transparent),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          // Navigate to the grading screen and pass the activity ID!
          Get.to(() => FormativeAssessmentScreen(activityId: activity['id']));
        },
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: ChanzoColors.secondary.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.local_activity_outlined, color: ChanzoColors.secondary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      activity['name'] ?? 'Unknown Activity',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      "Strand: ${activity['strand'] ?? 'N/A'}",
                      style: TextStyle(fontSize: 13, color: isDark ? Colors.grey.shade400 : Colors.grey.shade600),
                    ),
                    Text(
                      "Sub-strand: ${activity['sub_strand'] ?? 'N/A'}",
                      style: TextStyle(fontSize: 13, color: isDark ? Colors.grey.shade400 : Colors.grey.shade600),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.chevron_right, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInitialEmptyState(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.rule_outlined, size: 64, color: isDark ? Colors.grey.shade700 : Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(
            "Select to Begin",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.grey.shade800),
          ),
          const SizedBox(height: 8),
          Text(
            "Please select a Class and Subject\nfrom the dropdowns above.",
            textAlign: TextAlign.center,
            style: TextStyle(color: isDark ? Colors.grey.shade400 : Colors.grey.shade600),
          ),
        ],
      ),
    );
  }

  Widget _buildNoActivitiesState(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inventory_2_outlined, size: 64, color: isDark ? Colors.grey.shade700 : Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(
            "No Activities Found",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.grey.shade800),
          ),
          const SizedBox(height: 8),
          Text(
            "There are no formative activities\navailable for this subject.",
            textAlign: TextAlign.center,
            style: TextStyle(color: isDark ? Colors.grey.shade400 : Colors.grey.shade600),
          ),
        ],
      ),
    );
  }

  Widget _buildShimmerLoader(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 5,
      itemBuilder: (_, __) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Shimmer.fromColors(
          baseColor: isDark ? Colors.grey.shade800 : Colors.grey.shade300,
          highlightColor: isDark ? Colors.grey.shade700 : Colors.grey.shade100,
          child: Container(
            height: 100,
            decoration: BoxDecoration(
                color: isDark ? Colors.grey.shade900 : Colors.white,
                borderRadius: BorderRadius.circular(16)
            ),
          ),
        ),
      ),
    );
  }
}