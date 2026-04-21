import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart' hide Response;
import 'package:shimmer/shimmer.dart';

import '../../../globalclass/chanzo_color.dart';
import '../../../globalclass/kiotapay_constants.dart';
import '../../../utils/dio_helper.dart';
import '../../../widgets/error.dart';

class SummativeResultsScreen extends StatefulWidget {
  final int examId;
  final int paperId;

  const SummativeResultsScreen({super.key, required this.examId, required this.paperId});

  @override
  State<SummativeResultsScreen> createState() => _SummativeResultsScreenState();
}

class _SummativeResultsScreenState extends State<SummativeResultsScreen> {
  bool _isLoading = true;
  bool _isSaving = false;
  bool _hasError = false;

  Map<String, dynamic> _examInfo = {};
  Map<String, dynamic> _paperInfo = {};
  List<dynamic> _streams = [];
  List<dynamic> _students = [];

  String _subject= '';
  String _class= '';

  int? _selectedStreamId;
  int _maxScore = 100;

  // Controllers for dynamically generated TextFields
  final Map<int, TextEditingController> _studentScores = {};
  final Map<int, TextEditingController> _studentComments = {};

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  @override
  void dispose() {
    for (var controller in _studentScores.values) { controller.dispose(); }
    for (var controller in _studentComments.values) { controller.dispose(); }
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
        KiotaPayConstants.examPaperResults(widget.examId, widget.paperId),
        queryParameters: queryParams.isNotEmpty ? queryParams : null,
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        final data = response.data['data'];

        setState(() {
          _examInfo = data['exam'] ?? {};
          _paperInfo = data['exam_paper'] ?? {};
          _streams = data['streams'] ?? [];
          _students = data['students'] ?? [];
          _selectedStreamId = data['selected_stream_id'];
          _subject = data['subject'];
          _class = data['class'];

          // Parse max score safely
          _maxScore = int.tryParse(_paperInfo['max_marks']?.toString() ?? '100') ?? 100;

          // Initialize controllers and PRE-FILL existing marks!
          for (var student in _students) {
            final sId = student['id'];
            final existingScore = student['score']?.toString() ?? '';
            final existingComment = student['comments'] ?? '';

            if (!_studentScores.containsKey(sId)) {
              _studentScores[sId] = TextEditingController(text: existingScore);
            } else {
              _studentScores[sId]!.text = existingScore;
            }

            if (!_studentComments.containsKey(sId)) {
              _studentComments[sId] = TextEditingController(text: existingComment);
            } else {
              _studentComments[sId]!.text = existingComment;
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

    // Validate max scores before submitting
    for (var student in _students) {
      int sId = student['id'];
      String scoreText = _studentScores[sId]?.text.trim() ?? '';
      if (scoreText.isNotEmpty) {
        double? scoreValue = double.tryParse(scoreText);
        if (scoreValue != null && scoreValue > _maxScore) {
          Get.snackbar('Validation Error', '${student['name']} has a score higher than the maximum allowed ($_maxScore).', backgroundColor: Colors.red, colorText: Colors.white);
          return;
        }
      }
    }

    setState(() => _isSaving = true);

    Map<String, dynamic> marksPayload = {};

    for (var student in _students) {
      int sId = student['id'];
      String scoreText = _studentScores[sId]?.text.trim() ?? '';
      String comments = _studentComments[sId]?.text.trim() ?? '';

      if (scoreText.isNotEmpty || comments.isNotEmpty) {
        marksPayload[sId.toString()] = {
          "score": scoreText.isNotEmpty ? double.tryParse(scoreText) : null,
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
        KiotaPayConstants.examPaperResults(widget.examId, widget.paperId),
        data: payload,
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        Get.back(result: true);
        Get.snackbar('Success', 'Exam marks saved successfully!', backgroundColor: Colors.green, colorText: Colors.white);
      } else if (response.data['success'] == false) {
        Get.snackbar('Error', response.data['message'] ?? 'Failed to save marks.', backgroundColor: Colors.red, colorText: Colors.white);
      }
    } on DioException catch (e) {
      // Safely extract API error message
      String errorMsg = 'Failed to save marks. Please try again.';
      if (e.response != null && e.response?.data != null && e.response?.data is Map) {
        errorMsg = e.response!.data['message'] ?? errorMsg;
      }
      Get.snackbar('Error', errorMsg, backgroundColor: Colors.red, colorText: Colors.white);
    } catch (e) {
      Get.snackbar('Error', 'An unexpected error occurred.', backgroundColor: Colors.red, colorText: Colors.white);
    } finally {
      setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: const Text("Enter Exam Marks"), elevation: 0),
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
          // Header Info
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? Theme.of(context).cardColor : ChanzoColors.primary.withOpacity(0.05),
              border: Border(bottom: BorderSide(color: isDark ? Colors.grey.shade800 : Colors.grey.shade200)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_paperInfo.isNotEmpty) ...[
                  Text(
                    "${_class} • ${_paperInfo['name'] ?? 'Unknown Paper'} • ${_subject}",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: isDark ? Colors.white : ChanzoColors.primary),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "${_examInfo['name']} • Max Marks: $_maxScore",
                    style: TextStyle(fontSize: 13, color: isDark ? Colors.grey.shade400 : Colors.grey.shade700),
                  ),
                  const SizedBox(height: 16),
                ],
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
                  onChanged: (val) => _fetchData(streamId: val),
                ),
              ],
            ),
          ),

          // Students List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _hasError
                ? ErrorWidgetUniversal(title: "Failed to load", description: "Couldn't fetch data.", onRetry: () => _fetchData(streamId: _selectedStreamId))
                : _students.isEmpty
                ? Center(child: Text(_selectedStreamId == null ? "Select a stream above" : "No students found"))
                : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _students.length,
              itemBuilder: (context, index) {
                final student = _students[index];
                final sId = student['id'];
                return Card(
                  margin: const EdgeInsets.only(bottom: 16),
                  elevation: isDark ? 0 : 1,
                  color: isDark ? Theme.of(context).cardColor : Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: isDark ? Colors.grey.shade800 : Colors.grey.shade200),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(student['name'] ?? 'Unknown', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        const SizedBox(height: 2),
                        Text("Adm No: ${student['admission_no'] ?? 'N/A'}", style: const TextStyle(fontSize: 13, color: Colors.grey)),
                        const SizedBox(height: 16),
                        // Score Field - Full Width
                        TextFormField(
                          controller: _studentScores[sId],
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          decoration: InputDecoration(
                            labelText: "Score (/$_maxScore)",
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                            isDense: true,
                          ),
                        ),
                        const SizedBox(height: 12),
                        // Remarks Field - Full Width
                        TextFormField(
                          controller: _studentComments[sId],
                          maxLines: 2,
                          decoration: InputDecoration(
                            labelText: "Remarks",
                            alignLabelWithHint: true,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                            isDense: true,
                          ),
                        ),
                      ],
                    ),
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