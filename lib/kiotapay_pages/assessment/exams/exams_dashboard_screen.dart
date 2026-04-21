import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shimmer/shimmer.dart';

import '../../../globalclass/chanzo_color.dart';
import '../../../globalclass/kiotapay_constants.dart';
import '../../../utils/dio_helper.dart';
import '../../../widgets/error.dart';
import 'exam_paper_screen.dart';

class ExamsDashboardScreen extends StatefulWidget {
  const ExamsDashboardScreen({super.key});

  @override
  State<ExamsDashboardScreen> createState() => _ExamsDashboardScreenState();
}

class _ExamsDashboardScreenState extends State<ExamsDashboardScreen> {
  bool _isLoading = true;
  bool _hasError = false;

  List<dynamic> _sessions = [];
  List<dynamic> _exams = [];
  int? _selectedSessionId;

  @override
  void initState() {
    super.initState();
    _fetchExams();
  }

  Future<void> _fetchExams({int? sessionId}) async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    try {
      final Map<String, dynamic> queryParams = {};
      if (sessionId != null) queryParams['academic_session_id'] = sessionId;

      final response = await DioHelper().get(
        KiotaPayConstants.exams,
        queryParameters: queryParams.isNotEmpty ? queryParams : null,
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        final data = response.data['data'];

        setState(() {
          _sessions = data['academic_sessions'] ?? [];
          _exams = data['exams'] ?? [];

          // Use the API's selected session, or default to the first one if null
          _selectedSessionId = data['selected_academic_session_id'] ??
              (_sessions.isNotEmpty ? _sessions.first['id'] : null);

          _isLoading = false;
        });
      } else {
        setState(() => _hasError = true);
      }
    } catch (e) {
      setState(() => _hasError = true);
    } finally {
      if (mounted && _isLoading) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: const Text("Summative Exams"), elevation: 0),
      body: Column(
        children: [
          // Filter Section
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? Theme.of(context).cardColor : ChanzoColors.primary.withOpacity(0.05),
              border: Border(bottom: BorderSide(color: isDark ? Colors.grey.shade800 : Colors.grey.shade200)),
            ),
            child: DropdownButtonFormField<int>(
              isExpanded: true,
              decoration: InputDecoration(
                labelText: "Academic Session",
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                filled: true,
                fillColor: isDark ? Colors.grey.shade900 : Colors.white,
              ),
              value: _selectedSessionId,
              dropdownColor: isDark ? Colors.grey.shade900 : Colors.white,
              items: _sessions.map<DropdownMenuItem<int>>((session) {
                return DropdownMenuItem<int>(
                  value: session['id'],
                  child: Text(session['title'] ?? 'Unknown Year'),
                );
              }).toList(),
              onChanged: (val) => _fetchExams(sessionId: val),
            ),
          ),

          // Exams List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _hasError
                ? ErrorWidgetUniversal(title: "Error", description: "Failed to load exams.", onRetry: () => _fetchExams(sessionId: _selectedSessionId))
                : _exams.isEmpty
                ? const Center(child: Text("No exams found for this session."))
                : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _exams.length,
              itemBuilder: (context, index) {
                final exam = _exams[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  elevation: isDark ? 0 : 1,
                  color: isDark ? Theme.of(context).cardColor : Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: isDark ? Colors.grey.shade800 : Colors.grey.shade200),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    leading: CircleAvatar(
                      backgroundColor: ChanzoColors.primary.withOpacity(0.1),
                      child: const Icon(Icons.description, color: ChanzoColors.primary),
                    ),
                    title: Text(exam['name'] ?? 'Unknown Exam', style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text("Term ${exam['term']?['term_number'] ?? 'N/A'}"),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      Get.to(() => ExamPapersScreen(examId: exam['id'], examName: exam['name']));
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}