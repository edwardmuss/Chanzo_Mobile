import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../../globalclass/chanzo_color.dart';
import '../../../globalclass/kiotapay_constants.dart';
import '../../../utils/dio_helper.dart';

class ShowLessonPlanScreen extends StatefulWidget {
  final int teacherId;
  final int lessonPlanId;

  const ShowLessonPlanScreen({super.key, required this.teacherId, required this.lessonPlanId});

  @override
  State<ShowLessonPlanScreen> createState() => _ShowLessonPlanScreenState();
}

class _ShowLessonPlanScreenState extends State<ShowLessonPlanScreen> {
  bool _isLoading = true;
  Map<String, dynamic>? _lessonPlan;

  @override
  void initState() {
    super.initState();
    _fetchLessonPlan();
  }

  Future<void> _fetchLessonPlan() async {
    try {
      final response = await DioHelper().get('${KiotaPayConstants.lessonPlan}/${widget.lessonPlanId}');

      if (response.statusCode == 200 && response.data['success'] == true) {
        setState(() {
          _lessonPlan = response.data['data'];
        });
      } else {
        Get.snackbar('Error', response.data['message'] ?? 'Failed to load lesson plan details.');
      }
    } catch (e) {
      Get.snackbar('Error', 'Failed to load lesson plan details.');
    } finally {
      // FIX 1: Ensure loading always stops, preventing the infinite spinner
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // FIX 2: Added Date Formatter
  String _formatDate(String? dateStr) {
    if (dateStr == null) return 'N/A';
    try {
      return DateFormat('MMM d, yyyy').format(DateTime.parse(dateStr));
    } catch (e) {
      return dateStr;
    }
  }

  String _formatTime(dynamic timeObj) {
    if (timeObj is Map && timeObj['start_time'] != null) {
      return "${timeObj['start_time']} - ${timeObj['stop_time']}";
    }
    return "N/A";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Lesson Plan Details"),
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _lessonPlan == null
          ? const Center(child: Text("Lesson plan not found."))
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Card
            Card(
              elevation: 0,
              color: ChanzoColors.primary.withOpacity(0.05),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: ChanzoColors.primary.withOpacity(0.2))),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_lessonPlan!['subject'] ?? 'Unknown Subject', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: ChanzoColors.primary)),
                    const SizedBox(height: 12),

                    _buildMetaRow(Icons.class_, "Class", "${_lessonPlan!['class']} (${_lessonPlan!['stream']})"),
                    _buildMetaRow(Icons.calendar_today, "Date", _formatDate(_lessonPlan!['date'])),
                    _buildMetaRow(Icons.access_time, "Time", _formatTime(_lessonPlan!['time'])),
                    _buildMetaRow(Icons.groups, "Roll", _lessonPlan!['roll']?.toString() ?? 'N/A'),

                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8.0),
                      child: Divider(height: 1),
                    ),

                    _buildMetaRow(Icons.book, "Strand", _lessonPlan!['strand'] ?? 'N/A'),
                    // FIX 3: Added missing Sub-Strand
                    _buildMetaRow(Icons.bookmark_border, "Sub-Strand", _lessonPlan!['sub_strand'] ?? 'N/A'),
                    _buildMetaRow(Icons.local_activity, "Activity", _lessonPlan!['activity'] ?? 'N/A'),

                    const SizedBox(height: 8),
                    // FIX 4: Added Status Indicator
                    _buildMetaRow(Icons.info_outline, "Status", (_lessonPlan!['status'] ?? 'Draft').toString().toUpperCase(), isStatus: true),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            _buildSection("Specific Learning Outcome", _lessonPlan!['specific_learning_outcome']),
            _buildSection("Key Inquiry Question", _lessonPlan!['key_inquiry_question']),
            _buildSection("Learning Resources", _lessonPlan!['learning_resources']),
            _buildSection("Introduction", _lessonPlan!['introduction']),

            // FIX 5: Added the missing fields we put in the payload earlier
            _buildSection("Organisation of Learning", _lessonPlan!['organisation_of_learning']),
            _buildSection("Pertinent & Contemporary Issues (PCIs)", _lessonPlan!['pcis']),
            _buildSection("Core Values", _lessonPlan!['values']),

            // Lesson Development (Dynamic Steps)
            const Text("Lesson Development", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: ChanzoColors.primary)),
            const SizedBox(height: 8),
            if (_lessonPlan!['lesson_development'] is Map && (_lessonPlan!['lesson_development'] as Map).isNotEmpty)
              ...(_lessonPlan!['lesson_development'] as Map).entries.map((entry) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.check_circle, size: 16, color: Colors.green),
                      const SizedBox(width: 8),
                      Expanded(child: Text(entry.value.toString(), style: const TextStyle(fontSize: 14, height: 1.4))),
                    ],
                  ),
                );
              })
            else
              const Padding(
                padding: EdgeInsets.only(bottom: 16.0),
                child: Text("No steps provided.", style: TextStyle(fontSize: 14, color: Colors.grey, fontStyle: FontStyle.italic)),
              ),
            const SizedBox(height: 16),

            _buildSection("Conclusion", _lessonPlan!['conclusion']),
            _buildSection("Summary", _lessonPlan!['summary']),
            _buildSection("Reflection", _lessonPlan!['reflection']),
          ],
        ),
      ),
    );
  }

  // FIX 6: Updated Meta Row to support colored status and wrap long text
  Widget _buildMetaRow(IconData icon, String label, String value, {bool isStatus = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: Colors.grey.shade600),
          const SizedBox(width: 8),
          Text("$label: ", style: TextStyle(color: Colors.grey.shade700, fontWeight: FontWeight.w600)),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontWeight: isStatus ? FontWeight.bold : FontWeight.w500,
                color: isStatus
                    ? (value.toLowerCase() == 'approved' ? Colors.green : value.toLowerCase() == 'rejected' ? Colors.red : Colors.orange)
                    : Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(String title, String? content) {
    if (content == null || content.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: ChanzoColors.primary)),
          const SizedBox(height: 6),
          Text(content, style: const TextStyle(fontSize: 14, height: 1.5, color: Colors.black87)),
        ],
      ),
    );
  }
}