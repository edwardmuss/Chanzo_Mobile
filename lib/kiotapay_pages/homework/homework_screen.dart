import 'dart:convert';
import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:kiotapay/globalclass/chanzo_color.dart';
import 'package:kiotapay/globalclass/kiotapay_constants.dart';
import 'package:kiotapay/globalclass/kiotapay_fontstyle.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:get/get.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';

import '../../globalclass/global_methods.dart';
import '../../globalclass/kiotapay_global_classes.dart';
import '../../widgets/shimmer_widget.dart';

class HomeworkScreen extends StatefulWidget {
  const HomeworkScreen({super.key});

  @override
  State<HomeworkScreen> createState() => _HomeworkScreenState();
}

class _HomeworkScreenState extends State<HomeworkScreen> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  final class_id = authController.selectedStudentClassId;
  final stream_id = authController.selectedStudentStreamId;
  final student_id = authController.selectedStudentId;

  List<dynamic> homeworks = [];
  List<dynamic> filteredHomeworks = [];
  Map<String, dynamic> submissions = {};

  bool isLoading = true;
  bool isLoadingMore = false;
  bool hasError = false;
  int currentPage = 1;
  int lastPage = 1;

  @override
  void initState() {
    super.initState();
    fetchHomework();
    _scrollController.addListener(_scrollListener);
    _searchController.addListener(() {
      setState(() {
        filterHomeworks();
      });
    });
  }

  Future<void> fetchHomework({bool refresh = false}) async {
    if (refresh) {
      currentPage = 1;
      homeworks.clear();
      submissions.clear();
    }

    try {
      setState(() {
        if (!refresh && currentPage > 1) {
          isLoadingMore = true;
        } else {
          isLoading = true;
        }
      });

      final token = await storage.read(key: 'token');
      final response = await http.get(
        Uri.parse(
            "${KiotaPayConstants.getStudentHomeWork}/${class_id}/${stream_id}?page=$currentPage"),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        final data = decoded['data'];
        final pagination = decoded['pagination'];

        homeworks.addAll(data);
        currentPage++;
        lastPage = pagination['last_page'];
        filterHomeworks();

        await _fetchSubmissionsForHomeworks(data);
      } else {
        hasError = true;
        final decoded = jsonDecode(response.body);
        final errorMessage = decoded['message'] ?? 'Failed to load homework';
        awesomeDialog(
          context,
          "Error",
          errorMessage,
          true,
          DialogType.error,
          ChanzoColors.secondary,
        ).show();
      }
    } catch (e) {
      hasError = true;
      awesomeDialog(
        context,
        "Error",
        "Network error: ${e.toString()}",
        true,
        DialogType.error,
        ChanzoColors.secondary,
      ).show();
    } finally {
      setState(() {
        isLoading = false;
        isLoadingMore = false;
      });
    }
  }

  Future<void> _fetchSubmissionsForHomeworks(List<dynamic> homeworksList) async {
    for (var homework in homeworksList) {
      await _fetchHomeworkSubmissions(homework['id']);
    }
  }

  Future<void> _fetchHomeworkSubmissions(dynamic homeworkId) async {
    try {
      final token = await storage.read(key: 'token');
      final url = "${KiotaPayConstants.getStudentHomeWorkSubmissions}"
          .replaceAll(':homeworkId', homeworkId.toString()); // Convert to string

      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        setState(() {
          submissions[homeworkId.toString()] = decoded['data']; // Use string key
        });
      } else {
        final decoded = jsonDecode(response.body);
        final errorMessage = decoded['message'] ?? 'Failed to load submissions';
        awesomeDialog(
          context,
          "Error",
          errorMessage,
          true,
          DialogType.error,
          ChanzoColors.secondary,
        ).show();
      }
    } catch (e) {
      print('Error fetching submissions for homework $homeworkId: $e');
    }
  }

  void _scrollListener() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 100 &&
        !isLoadingMore &&
        currentPage <= lastPage) {
      fetchHomework();
    }
  }

  void filterHomeworks() {
    final query = _searchController.text.trim().toLowerCase();
    if (query.isEmpty) {
      filteredHomeworks = homeworks;
    } else {
      filteredHomeworks = homeworks.where((hw) {
        final subject = hw['subject']['name']?.toLowerCase() ?? '';
        final desc = hw['description']?.toLowerCase() ?? '';
        return subject.contains(query) || desc.contains(query);
      }).toList();
    }
  }

  void _showHomeworkDetails(dynamic homework) {
    final homeworkId = homework['id'].toString();
    final studentSubmissions = submissions[homeworkId] ?? [];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(16),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Homework Details
                Text(
                  homework['subject']['name'] ?? 'No Subject',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "Class: ${homework['class']['name']}, Stream: ${homework['stream']['name']}",
                  style: const TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 8),
                Text(
                  "Created By: ${homework['created_by']['first_name']} ${homework['created_by']['last_name']}",
                ),
                const SizedBox(height: 12),
                Text(
                  "Description:",
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 6),
                Text(
                  homework['description']
                      ?.replaceAll(RegExp(r'<[^>]*>|&[^;]+;'), ''),
                ),
                const SizedBox(height: 12),

                // Download Homework File
                if (homework['file'] != null)
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.of(context).pop();
                      openFile(context, homework['file']);
                    },
                    icon: const Icon(Icons.download),
                    label: const Text("Download Homework File"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: ChanzoColors.primary,
                      foregroundColor: ChanzoColors.white,
                      minimumSize: const Size(double.infinity, 50),
                    ),
                  ),

                const SizedBox(height: 12),

                // Submit Homework Button
                ElevatedButton.icon(
                  onPressed: () => _showSubmitHomeworkDialog(homework),
                  icon: const Icon(Icons.upload_file),
                  label: const Text("Submit Homework"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: ChanzoColors.secondary,
                    foregroundColor: ChanzoColors.white,
                    minimumSize: const Size(double.infinity, 50),
                  ),
                ),

                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 8),

                // Submissions Section
                Text(
                  "My Submissions (${studentSubmissions.length})",
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 8),

                if (studentSubmissions.isEmpty)
                  const Text(
                    "No submissions yet",
                    style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic),
                  )
                else
                  ...studentSubmissions.map((submission) => _buildSubmissionCard(submission)).toList(),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSubmissionCard(dynamic submission) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Submitted: ${_formatDate(submission['submission_date'])}",
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getStatusColor(submission['status']),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    submission['status']?.toString().toUpperCase() ?? 'UNKNOWN',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            if (submission['text_answer'] != null && submission['text_answer'].isNotEmpty)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Text Answer:",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(submission['text_answer']),
                  const SizedBox(height: 8),
                ],
              ),

            if (submission['file_path'] != null)
              ElevatedButton.icon(
                onPressed: () => openFile(context, submission['file_path']),
                icon: const Icon(Icons.download, size: 16),
                label: Text("Download ${submission['file_type']?.toUpperCase() ?? 'File'}"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey[200],
                  foregroundColor: Colors.black87,
                  minimumSize: const Size(double.infinity, 40),
                ),
              ),

            if (submission['score'] != null)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 8),
                  Text(
                    "Score: ${submission['score']}",
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                ],
              ),

            if (submission['teacher_feedback'] != null)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 8),
                  const Text(
                    "Teacher Feedback:",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(submission['teacher_feedback']),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(String? status) {
    switch (status?.toLowerCase()) {
      case 'submitted':
        return Colors.blue;
      case 'graded':
        return Colors.green;
      case 'late':
        return Colors.orange;
      case 'missing':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _formatDate(String? dateString) {
    if (dateString == null) return 'Unknown date';
    try {
      final date = DateTime.parse(dateString);
      final formatter = DateFormat('MMM d yyyy'); // e.g., Oct 25 2025
      return formatter.format(date);
    } catch (e) {
      return 'Invalid date';
    }
  }

  void _showSubmitHomeworkDialog(dynamic homework) {
    final textController = TextEditingController();
    File? selectedFile;
    bool isPickingFile = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: const Text("Submit Homework"),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    homework['subject']['name'] ?? 'No Subject',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),

                  // Text Answer
                  const Text("Text Answer (Optional):"),
                  const SizedBox(height: 8),
                  TextField(
                    controller: textController,
                    maxLines: 4,
                    decoration: InputDecoration(
                      hintText: "Enter your answer here...",
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // File Upload
                  const Text("Upload File (Optional):"),
                  const SizedBox(height: 8),
                  Stack(
                    children: [
                      ElevatedButton.icon(
                        onPressed: isPickingFile
                            ? null
                            : () async {
                          setDialogState(() {
                            isPickingFile = true;
                          });
                          final file = await _pickFile();
                          setDialogState(() {
                            isPickingFile = false;
                            selectedFile = file;
                          });
                        },
                        icon: const Icon(Icons.attach_file),
                        label: Text(selectedFile == null ? "Choose File" : "Change File"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.grey[200],
                          foregroundColor: Colors.black87,
                          minimumSize: const Size(double.infinity, 50),
                        ),
                      ),
                      if (isPickingFile)
                        Positioned.fill(
                          child: Container(
                            color: Colors.black54,
                            child: const Center(
                              child: CircularProgressIndicator(),
                            ),
                          ),
                        ),
                    ],
                  ),

                  if (selectedFile != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        "Selected: ${selectedFile!.path.split('/').last}",
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.green,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text("Cancel"),
              ),
              ElevatedButton(
                onPressed: () => _submitHomework(
                  homework,
                  textController.text,
                  selectedFile,
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: ChanzoColors.secondary,
                  foregroundColor: ChanzoColors.white,
                ),
                child: const Text("Submit"),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<File?> _pickFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'doc', 'docx', 'jpg', 'jpeg', 'png', 'txt'],
        allowMultiple: false,
      );

      if (result != null && result.files.single.path != null) {
        return File(result.files.single.path!);
      }
      return null;
    } catch (e) {
      // Don't show error dialog here, just return null
      print("File picking error: $e");
      return null;
    }
  }

  Future<void> _submitHomework(
      dynamic homework,
      String textAnswer,
      File? file,
      ) async {
    showLoading("Submitting homework...");

    try {
      final token = await storage.read(key: 'token');
      final url = "${KiotaPayConstants.submitStudentHomeWork}"
          .replaceAll(':homeworkId', homework['id'].toString());

      // Create multipart request
      var request = http.MultipartRequest('POST', Uri.parse(url));

      // Add headers
      request.headers['Authorization'] = 'Bearer $token';
      request.headers['Accept'] = 'application/json';

      // Add fields
      request.fields['text_answer'] = textAnswer;
      request.fields['student_id'] = student_id.toString();

      // Add file if selected
      if (file != null) {
        request.files.add(await http.MultipartFile.fromPath(
          'file',
          file.path,
        ));
      }

      final response = await request.send();
      final responseData = await response.stream.bytesToString();
      final decoded = jsonDecode(responseData);

      hideLoading();

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (decoded['success'] == true) {
          // Success case
          Navigator.of(context).pop(); // Close dialog
          Navigator.of(context).pop(); // Close bottom sheet if open

          // Refresh submissions for this homework
          await _fetchHomeworkSubmissions(homework['id'].toString());

          awesomeDialog(
            context,
            "Success",
            decoded['message'] ?? "Homework submitted successfully!",
            true,
            DialogType.success, // Changed to success type
            ChanzoColors.primary,
          ).show();
        } else {
          // API returned success: false
          awesomeDialog(
            context,
            "Error",
            decoded['message'] ?? "Failed to submit homework",
            true,
            DialogType.error,
            ChanzoColors.secondary,
          ).show();
        }
      } else {
        // HTTP error status code
        awesomeDialog(
          context,
          "Error",
          decoded['message'] ?? "Failed to submit homework. Status: ${response.statusCode}",
          true,
          DialogType.error,
          ChanzoColors.secondary,
        ).show();
      }
    } catch (e) {
      hideLoading();
      awesomeDialog(
        context,
        "Error",
        "Network error: ${e.toString()}",
        true,
        DialogType.error,
        ChanzoColors.secondary,
      ).show();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Homework")),
      body: RefreshIndicator(
        onRefresh: () => fetchHomework(refresh: true),
        child: ListView(
          controller: _scrollController,
          padding: const EdgeInsets.all(12),
          physics: const AlwaysScrollableScrollPhysics(), // Force pull-to-refresh
          children: [
            // 👨‍🎓 Student Info Card
            Card(
              elevation: 3,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundImage: NetworkImage(
                      authController.selectedStudentAvatar ??
                          'https://via.placeholder.com/150'),
                  radius: 30,
                ),
                title: Text(authController.selectedStudentName ?? ''),
                subtitle: Text(
                    "Adm No: ${authController.selectedStudentAdmissionNumber}\nClass: ${authController.selectedStudentClassName} (${authController.selectedStudentStreamName})"),
              ),
            ),
            const SizedBox(height: 12),

            // 🔍 Search Field
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: "Search homework...",
                prefixIcon: const Icon(Icons.search),
                border:
                OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 12),

            // 📝 Homework List
            if (isLoading && homeworks.isEmpty)
              ...List.generate(
                7,
                    (index) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    children: [
                      const ShimmerWidget.circular(height: 50, width: 50),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: const [
                            ShimmerWidget.rectangular(
                                height: 16, width: double.infinity),
                            SizedBox(height: 8),
                            ShimmerWidget.rectangular(height: 14, width: 150),
                          ],
                        ),
                      )
                    ],
                  ),
                ),
              )
            else if (hasError)
              Center(
                child: Column(
                  children: [
                    const Text("Failed to load homework."),
                    TextButton(
                      onPressed: () => fetchHomework(refresh: true),
                      child: const Text("Try Again"),
                    ),
                  ],
                ),
              )
            else
              ...filteredHomeworks.map((hw) {
                final homeworkId = hw['id'].toString();
                final studentSubmissions = submissions[homeworkId] ?? [];
                final hasSubmissions = studentSubmissions.isNotEmpty;
                final latestSubmission = hasSubmissions ? studentSubmissions[0] : null;

                return Column(
                  children: [
                    ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      leading: Container(
                        width: 4,
                        height: 40,
                        decoration: BoxDecoration(
                          color: hasSubmissions ? Colors.green : ChanzoColors.secondary,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      title: Text(
                        hw['subject']['name'] ?? 'No Subject',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      subtitle: hasSubmissions
                          ? Text(
                        "Submitted: ${_formatDate(latestSubmission?['submission_date'])}",
                        style: const TextStyle(color: Colors.green),
                      )
                          : const Text(
                        "Not submitted",
                        style: TextStyle(color: Colors.orange),
                      ),
                      trailing: GestureDetector(
                        onTap: () => _showHomeworkDetails(hw),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'View',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Icon(
                              Icons.chevron_right,
                              color: Theme.of(context).colorScheme.primary,
                              size: 20,
                            ),
                          ],
                        ),
                      ),
                      onTap: () => _showHomeworkDetails(hw),
                    ),
                    Divider(
                      height: 1,
                      thickness: 1,
                      indent: 24,
                      endIndent: 24,
                    ),
                  ],
                );
              }).toList(),

            if (isLoadingMore)
              const Padding(
                padding: EdgeInsets.all(8.0),
                child: Center(child: CircularProgressIndicator()),
              )
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }
}