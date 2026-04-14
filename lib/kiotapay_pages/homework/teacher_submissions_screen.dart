import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../globalclass/chanzo_color.dart';
import '../../globalclass/global_methods.dart';
import '../../globalclass/kiotapay_constants.dart';
import '../../utils/dio_helper.dart';

class TeacherSubmissionsScreen extends StatefulWidget {
  final Map<String, dynamic> homework;

  const TeacherSubmissionsScreen({super.key, required this.homework});

  @override
  State<TeacherSubmissionsScreen> createState() => _TeacherSubmissionsScreenState();
}

class _TeacherSubmissionsScreenState extends State<TeacherSubmissionsScreen> {
  bool _isLoading = true;
  List<dynamic> _submissions = [];

  @override
  void initState() {
    super.initState();
    _fetchSubmissions();
  }

  Future<void> _fetchSubmissions() async {
    setState(() => _isLoading = true);
    try {
      final url = "${KiotaPayConstants.getStudentHomeWorkSubmissions}"
          .replaceAll(':homeworkId', widget.homework['id'].toString());

      final response = await DioHelper().get(url);

      if (response.statusCode == 200 && response.data['success'] == true) {
        setState(() {
          _submissions = response.data['data'];
        });
      }
    } catch (e) {
      Get.snackbar('Error', 'Failed to load submissions', snackPosition: SnackPosition.BOTTOM);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showEvaluationSheet(dynamic submission) {
    final scoreController = TextEditingController(text: submission['score'] ?? '');
    final feedbackController = TextEditingController(text: submission['teacher_feedback'] ?? '');
    String selectedStatus = submission['status'] == 'submitted' ? 'evaluated' : (submission['status'] ?? 'evaluated');
    bool isSaving = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (context) {
        return StatefulBuilder(
            builder: (context, setSheetState) {
              return Padding(
                padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 16, right: 16, top: 24),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Evaluate: ${submission['student']['user']['first_name']} ${submission['student']['user']['last_name']}",
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 16),

                      // Show Student's Answer
                      if (submission['text_answer'] != null && submission['text_answer'].isNotEmpty) ...[
                        const Text("Student's Answer:", style: TextStyle(fontWeight: FontWeight.w600)),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          margin: const EdgeInsets.only(top: 6, bottom: 12),
                          decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(8)),
                          child: Text(submission['text_answer']),
                        ),
                      ],

                      if (submission['file_path'] != null)
                        ElevatedButton.icon(
                          onPressed: () => openFile(context, submission['file_path']),
                          icon: const Icon(Icons.download),
                          label: const Text("Download Student File"),
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.grey.shade200, foregroundColor: Colors.black),
                        ),
                      const Divider(height: 32),

                      // Evaluation Form
                      Column(
                        children: [
                          TextFormField(
                            controller: scoreController,
                            decoration: const InputDecoration(
                              labelText: 'Score / Marks (e.g. 8/10)',
                              border: OutlineInputBorder(),
                            ),
                          ),
                          const SizedBox(height: 12),
                          DropdownButtonFormField<String>(
                            value: selectedStatus,
                            decoration: const InputDecoration(
                              labelText: 'Status',
                              border: OutlineInputBorder(),
                            ),
                            items: const [
                              DropdownMenuItem(value: 'evaluated', child: Text('Evaluated')),
                              DropdownMenuItem(value: 'late', child: Text('Late')),
                              DropdownMenuItem(value: 'submitted', child: Text('Submitted')),
                            ],
                            onChanged: (val) => setSheetState(() => selectedStatus = val!),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: feedbackController,
                        maxLines: 3,
                        decoration: const InputDecoration(labelText: 'Teacher Feedback', border: OutlineInputBorder()),
                      ),
                      const SizedBox(height: 24),

                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: isSaving ? null : () async {
                            setSheetState(() => isSaving = true);
                            final url = KiotaPayConstants.evaluateStudentHomeWorkSubmissions.replaceAll(':submissionId', submission['id'].toString()).toString();
                            print(url);
                            try {
                              final response = await DioHelper().post(url,
                                  data: {
                                    'score': scoreController.text,
                                    'teacher_feedback': feedbackController.text,
                                    'status': selectedStatus,
                                  }
                              );
                              if (response.statusCode == 200) {
                                Navigator.pop(context); // Close sheet
                                _fetchSubmissions(); // Refresh list
                                Get.snackbar('Success', 'Evaluation saved.', backgroundColor: Colors.green, colorText: Colors.white);
                              }
                            } catch (e) {
                              debugPrint('Failed to save evaluation. $e');
                              Get.snackbar('Error', 'Failed to save evaluation.');
                            } finally {
                              setSheetState(() => isSaving = false);
                            }
                          },
                          style: ElevatedButton.styleFrom(backgroundColor: ChanzoColors.primary),
                          child: isSaving
                              ? const CircularProgressIndicator(color: Colors.white)
                              : const Text("Save Evaluation", style: TextStyle(color: Colors.white, fontSize: 16)),
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              );
            }
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Submissions')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _submissions.isEmpty
          ? const Center(child: Text("No students have submitted yet."))
          : ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: _submissions.length,
        itemBuilder: (context, index) {
          final sub = _submissions[index];
          final student = sub['student']['user'];
          final isEvaluated = sub['evaluated_by'] != null;

          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: ListTile(
              contentPadding: const EdgeInsets.all(16),
              leading: CircleAvatar(
                backgroundColor: isEvaluated ? Colors.green.withOpacity(0.2) : Colors.orange.withOpacity(0.2),
                child: Icon(
                  isEvaluated ? Icons.check_circle : Icons.pending_actions,
                  color: isEvaluated ? Colors.green : Colors.orange,
                ),
              ),
              title: Text("${student['first_name']} ${student['last_name']}", style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 4),
                  Text("Submitted: ${DateFormat('MMM d, h:mm a').format(DateTime.parse(sub['submission_date']))}"),
                  if (isEvaluated)
                    Text("Score: ${sub['score'] ?? 'N/A'}", style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                ],
              ),
              trailing: ElevatedButton(
                onPressed: () => _showEvaluationSheet(sub),
                style: ElevatedButton.styleFrom(
                  backgroundColor: isEvaluated ? Colors.grey.shade200 : ChanzoColors.secondary,
                  foregroundColor: isEvaluated ? Colors.black : Colors.white,
                ),
                child: Text(isEvaluated ? "Edit" : "Evaluate"),
              ),
            ),
          );
        },
      ),
    );
  }
}