import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shimmer/shimmer.dart';

import '../../../globalclass/chanzo_color.dart';
import '../../../globalclass/kiotapay_constants.dart';
import '../../../utils/dio_helper.dart';
import '../../../widgets/error.dart';

class FormativeAssessmentScreen extends StatefulWidget {
  final int activityId;

  const FormativeAssessmentScreen({super.key, required this.activityId});

  @override
  State<FormativeAssessmentScreen> createState() => _FormativeAssessmentScreenState();
}

class _FormativeAssessmentScreenState extends State<FormativeAssessmentScreen> {
  bool _isLoading = true;
  bool _isSaving = false;
  bool _hasError = false;

  Map<String, dynamic> _activityInfo = {};
  List<dynamic> _streams = [];
  List<dynamic> _students = [];

  int? _selectedStreamId;

  // State maps to hold input data per student ID
  final Map<int, int?> _studentScores = {};
  final Map<int, TextEditingController> _studentComments = {};

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  @override
  void dispose() {
    // Dispose all dynamic controllers to prevent memory leaks
    for (var controller in _studentComments.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _fetchData({int? streamId}) async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    try {
      final Map<String, dynamic> queryParams = {};
      if (streamId != null) queryParams['stream_id'] = streamId;

      final response = await DioHelper().get(
        KiotaPayConstants.formativeCreateResults(widget.activityId),
        queryParameters: queryParams.isNotEmpty ? queryParams : null,
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        final data = response.data['data'];

        setState(() {
          _activityInfo = data['activity'] ?? {};
          _streams = data['streams'] ?? [];
          _students = data['students'] ?? [];
          _selectedStreamId = data['selected_stream_id'];

          // Initialize controllers and pre-fill existing marks!
          for (var student in _students) {
            final sId = student['id'];

            // Pre-fill the score dropdown (or null if they haven't been graded yet)
            _studentScores[sId] = student['score'];

            // Pre-fill the comment text field
            if (!_studentComments.containsKey(sId)) {
              _studentComments[sId] = TextEditingController(text: student['comments'] ?? '');
            } else {
              _studentComments[sId]!.text = student['comments'] ?? '';
            }
          }

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

  Future<void> _submitMarks() async {
    if (_selectedStreamId == null) {
      Get.snackbar('Error', 'Please select a stream first.');
      return;
    }

    setState(() => _isSaving = true);

    // Build the nested marks payload
    Map<String, dynamic> marksPayload = {};

    for (var student in _students) {
      int sId = student['id'];
      int? score = _studentScores[sId];
      String comments = _studentComments[sId]?.text.trim() ?? '';

      // Only include students where the teacher actually entered data
      if (score != null || comments.isNotEmpty) {
        marksPayload[sId.toString()] = {
          "score": score,
          "comments": comments,
        };
      }
    }

    if (marksPayload.isEmpty) {
      setState(() => _isSaving = false);
      Get.snackbar('Notice', 'No marks or comments entered yet.');
      return;
    }

    final payload = {
      "stream_id": _selectedStreamId,
      "marks": marksPayload,
    };

    try {
      final response = await DioHelper().post(
        KiotaPayConstants.formativeStoreResults(widget.activityId),
        data: payload,
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        Get.back(result: true);
        Get.snackbar('Success', 'Marks saved successfully!', backgroundColor: Colors.green, colorText: Colors.white);
      }
    } catch (e) {
      Get.snackbar('Error', 'Failed to save marks. Please try again.', backgroundColor: Colors.red, colorText: Colors.white);
    } finally {
      setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Enter Results"),
        elevation: 0,
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: ElevatedButton(
            onPressed: (_isSaving || _students.isEmpty) ? null : _submitMarks,
            style: ElevatedButton.styleFrom(
                backgroundColor: ChanzoColors.primary,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))
            ),
            child: _isSaving
                ? const CircularProgressIndicator(color: Colors.white)
                : const Text("Save Results", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ),
        ),
      ),
      body: Column(
        children: [
          // Header: Activity Info & Stream Selector
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? Theme.of(context).cardColor : ChanzoColors.primary.withOpacity(0.05),
              border: Border(bottom: BorderSide(color: isDark ? Colors.grey.shade800 : Colors.grey.shade200)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_activityInfo.isNotEmpty) ...[
                  Text(
                    _activityInfo['name'] ?? 'Unknown Activity',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: isDark ? Colors.white : ChanzoColors.primary),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "${_activityInfo['strand']} • ${_activityInfo['sub_strand']}",
                    style: TextStyle(fontSize: 13, color: isDark ? Colors.grey.shade400 : Colors.grey.shade700),
                  ),
                  const SizedBox(height: 16),
                ],

                // Stream Dropdown
                DropdownButtonFormField<int>(
                  isExpanded: true,
                  decoration: InputDecoration(
                    labelText: "Select Stream",
                    labelStyle: TextStyle(color: isDark ? Colors.grey.shade400 : Colors.grey.shade600),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    filled: true,
                    fillColor: isDark ? Colors.grey.shade900 : Colors.white,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                  value: _selectedStreamId,
                  dropdownColor: isDark ? Colors.grey.shade900 : Colors.white,
                  items: _streams.map<DropdownMenuItem<int>>((stream) {
                    return DropdownMenuItem<int>(
                      value: stream['id'],
                      child: Text(stream['name'] ?? 'Unknown'),
                    );
                  }).toList(),
                  onChanged: (val) {
                    _fetchData(streamId: val); // Trigger fetch for selected stream
                  },
                ),
              ],
            ),
          ),

          // Students List
          Expanded(
            child: _isLoading
                ? _buildShimmerLoader(context)
                : _hasError
                ? ErrorWidgetUniversal(title: "Failed to load", description: "Couldn't fetch data.", onRetry: () => _fetchData(streamId: _selectedStreamId))
                : _students.isEmpty
                ? _buildEmptyState(isDark)
                : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _students.length,
              itemBuilder: (context, index) {
                final student = _students[index];
                return _buildStudentMarkCard(student, isDark);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStudentMarkCard(Map<String, dynamic> student, bool isDark) {
    final int sId = student['id'];

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
            // Student Info
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
                  radius: 16,
                  child: const Icon(Icons.person, size: 18, color: Colors.grey),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(student['name'] ?? 'Unknown', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      Text("Adm No: ${student['admission_no'] ?? 'N/A'}", style: TextStyle(color: isDark ? Colors.grey.shade400 : Colors.grey.shade600, fontSize: 12)),
                    ],
                  ),
                ),
              ],
            ),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12.0),
              child: Divider(height: 1),
            ),

            // Score Dropdown
            DropdownButtonFormField<int>(
              isExpanded: true,
              decoration: InputDecoration(
                labelText: "Score Rating",
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                isDense: true,
              ),
              value: _studentScores[sId],
              dropdownColor: isDark ? Colors.grey.shade900 : Colors.white,
              items: const [
                DropdownMenuItem(value: 4, child: Text("4 - Exceeding Expectation")),
                DropdownMenuItem(value: 3, child: Text("3 - Meeting Expectation")),
                DropdownMenuItem(value: 2, child: Text("2 - Approaching Expectation")),
                DropdownMenuItem(value: 1, child: Text("1 - Below Expectation")),
              ],
              onChanged: (val) {
                setState(() => _studentScores[sId] = val);
              },
            ),
            const SizedBox(height: 12),

            // Comment Box
            TextField(
              controller: _studentComments[sId],
              maxLines: 2,
              decoration: InputDecoration(
                labelText: "Teacher's Comment (Optional)",
                alignLabelWithHint: true,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.group_off_outlined, size: 64, color: isDark ? Colors.grey.shade700 : Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(
            _selectedStreamId == null ? "Select a Stream" : "No Students Found",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.grey.shade800),
          ),
          const SizedBox(height: 8),
          Text(
            _selectedStreamId == null
                ? "Please select a stream above to begin grading."
                : "There are no students registered in this stream.",
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
      itemCount: 3,
      itemBuilder: (_, __) => Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: Shimmer.fromColors(
          baseColor: isDark ? Colors.grey.shade800 : Colors.grey.shade300,
          highlightColor: isDark ? Colors.grey.shade700 : Colors.grey.shade100,
          child: Container(
            height: 200,
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