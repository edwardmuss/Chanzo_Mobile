import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';

import '../../globalclass/chanzo_color.dart';
import '../../globalclass/kiotapay_constants.dart';
import '../../globalclass/kiotapay_icons.dart';
import '../../utils/dio_helper.dart';
import '../../widgets/class_stream_selector.dart';
import '../../widgets/error.dart';
import '../kiotapay_authentication/AuthController.dart';

class ClassAttendanceScreen extends StatefulWidget {
  const ClassAttendanceScreen({super.key});

  @override
  State<ClassAttendanceScreen> createState() => _ClassAttendanceScreenState();
}

class _ClassAttendanceScreenState extends State<ClassAttendanceScreen> {
  final AuthController authController = Get.find<AuthController>();

  List<dynamic> _apiClasses = [];
  bool _isLoadingClasses = true;
  bool _isLoadingAttendance = false;
  bool _isSaving = false;

  int? selectedClassId;
  int? selectedStreamId;
  DateTime selectedDate = DateTime.now();

  List<dynamic> students = [];
  // Map to hold the current attendance state: {student_id: status}
  Map<int, String> attendanceState = {};
  // Map for remarks
  Map<int, String> remarksState = {};
  final Map<int, TextEditingController> _remarkControllers = {};

  late final bool canEdit;

  @override
  void initState() {
    super.initState();
    canEdit = authController.hasPermission('student_attendance-add') ||
        authController.hasPermission('student_attendance-edit');
    _fetchClasses();
  }
  @override
  void dispose() {
    // Dispose all controllers to prevent memory leaks
    for (var controller in _remarkControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _fetchClasses() async {
    final branchId = authController.activeBranchId ?? authController.user['branch_id'];
    if (branchId == null) return;
    final url = KiotaPayConstants.getClassesByBranch.replaceAll(':branch_id', branchId.toString());

    try {
      final response = await DioHelper().get(url);
      if (response.statusCode == 200 && response.data['success'] == true) {
        setState(() {
          _apiClasses = response.data['data'] ?? [];
          _isLoadingClasses = false;
        });
      }
    } catch (e) {
      setState(() => _isLoadingClasses = false);
      Get.snackbar('Error', 'Failed to load classes.', snackPosition: SnackPosition.BOTTOM);
    }
  }

  Future<void> _fetchClassAttendance() async {
    if (selectedClassId == null || selectedStreamId == null) return;

    setState(() => _isLoadingAttendance = true);

    try {
      final formattedDate = DateFormat('yyyy-MM-dd').format(selectedDate);
      final response = await DioHelper().get(
        '${KiotaPayConstants.getClassAttendance}',
        queryParameters: {
          'class_id': selectedClassId,
          'stream_id': selectedStreamId,
          'date': formattedDate,
        },
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        final data = response.data['data'];
        final fetchedStudents = data['students'] as List<dynamic>;

        // --- Safely parse attendance_records to handle empty [] ---
        Map<String, dynamic> fetchedRecords = {};
        if (data['attendance_records'] is Map) {
          fetchedRecords = Map<String, dynamic>.from(data['attendance_records']);
        }

        setState(() {
          students = fetchedStudents;
          attendanceState.clear();
          remarksState.clear();

          // Populate existing records, default to 'present' if none exists
          for (var student in fetchedStudents) {
            int studentId = student['id'];
            String existingRemark = '';

            if (fetchedRecords.containsKey(studentId.toString())) {
              attendanceState[studentId] = fetchedRecords[studentId.toString()]['status'];
              existingRemark = fetchedRecords[studentId.toString()]['remarks'] ?? '';
            } else {
              attendanceState[studentId] = 'present';
            }

            remarksState[studentId] = existingRemark;

            // Assign a controller for this student's remark
            _remarkControllers[studentId] = TextEditingController(text: existingRemark);
          }
        });
      }
    } catch (e) {
      print("Attendance Fetch Error: $e"); // Helpful for debugging
      Get.snackbar('Error', 'Failed to load attendance roster.', snackPosition: SnackPosition.BOTTOM);
    } finally {
      setState(() => _isLoadingAttendance = false);
    }
  }

  Future<void> _saveAttendance() async {
    if (students.isEmpty || _isSaving) return;

    setState(() => _isSaving = true);

    try {
      final formattedDate = DateFormat('yyyy-MM-dd').format(selectedDate);

      // Build the payload
      List<Map<String, dynamic>> payloadData = [];
      attendanceState.forEach((studentId, status) {
        payloadData.add({
          'student_id': studentId,
          'status': status,
          'remarks': remarksState[studentId] ?? '',
        });
      });

      final response = await DioHelper().post(
        '${KiotaPayConstants.storeClassAttendance}',
        data: {
          'date': formattedDate,
          'attendance': payloadData,
        },
      );

      if (response.statusCode == 200) {
        Get.snackbar(
          'Success',
          'Attendance saved successfully!',
          backgroundColor: Colors.green,
          colorText: Colors.white,
          snackPosition: SnackPosition.BOTTOM,
        );
      } else {
        throw Exception(response.data['message']);
      }
    } catch (e) {
      Get.snackbar('Error', 'Failed to save attendance. Try again.', snackPosition: SnackPosition.BOTTOM);
    } finally {
      setState(() => _isSaving = false);
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(primary: ChanzoColors.primary),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != selectedDate) {
      setState(() {
        selectedDate = picked;
      });
      _fetchClassAttendance(); // Fetch fresh data for the new date
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Class Attendance')),
      bottomNavigationBar: (canEdit && students.isNotEmpty && !_isLoadingAttendance)
          ? SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: ChanzoColors.primary,
              minimumSize: const Size(double.infinity, 50),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: _isSaving ? null : _saveAttendance,
            child: _isSaving
                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white))
                : const Text("Save Attendance", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
          ),
        ),
      )
          : null,
      body: _isLoadingClasses
          ? const Center(child: CircularProgressIndicator())
          : Column(
        children: [
          // Filter Section
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: Column(
              children: [
                ClassStreamSelector(
                  classes: _apiClasses,
                  onChanged: (classId, streamId) {
                    setState(() {
                      selectedClassId = classId;
                      selectedStreamId = streamId;
                      students.clear(); // Clear old students
                    });
                    _fetchClassAttendance();
                  },
                ),
                const SizedBox(height: 16),
                // Date Selector
                InkWell(
                  onTap: () => _selectDate(context),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "Date: ${DateFormat('EEE, MMM d, yyyy').format(selectedDate)}",
                          style: const TextStyle(fontSize: 16),
                        ),
                        const Icon(Icons.calendar_today, color: ChanzoColors.primary, size: 20),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          const Divider(height: 1, thickness: 1),

          // Roster Section
          Expanded(
            child: _buildRosterSection(),
          ),
        ],
      ),
    );
  }

  Widget _buildRosterSection() {
    if (selectedClassId == null || selectedStreamId == null) {
      return Center(
        child: Text("Select a class and stream to view roster.", style: TextStyle(color: Colors.grey.shade600)),
      );
    }

    if (_isLoadingAttendance) {
      return ListView.builder(
        itemCount: 6,
        itemBuilder: (_, __) => Padding(
          padding: const EdgeInsets.all(16.0),
          child: Shimmer.fromColors(
            baseColor: Colors.grey[300]!,
            highlightColor: Colors.grey[100]!,
            child: Container(height: 80, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12))),
          ),
        ),
      );
    }

    if (students.isEmpty) {
      return Center(
        child: Text("No students found in this stream.", style: TextStyle(color: Colors.grey.shade600)),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 20),
      itemCount: students.length,
      itemBuilder: (context, index) {
        final student = students[index];
        final studentId = student['id'];
        final admissionNumber = student['admission_no'];
        final user = student['user'] ?? {};
        final name = "${user['first_name'] ?? ''} ${user['last_name'] ?? ''}".trim();
        final avatar = user['avatar'];

        final currentStatus = attendanceState[studentId] ?? 'present';

        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      backgroundImage: NetworkImage(
                          avatar != null
                              ? '${KiotaPayConstants.webUrl}storage/$avatar'
                              : KiotaPayPngimage.profile
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Segmented Attendance Buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildStatusButton(studentId, 'present', 'Present', Colors.green),
                    _buildStatusButton(studentId, 'absent', 'Absent', Colors.red),
                    _buildStatusButton(studentId, 'late', 'Late', Colors.orange),
                    _buildStatusButton(studentId, 'half day', 'Half Day', Colors.amber),
                  ],
                ),

                // --- Dynamic Remarks Field ---
                // Only show if status is NOT present, OR if they already typed a remark
                if (currentStatus != 'present' || (_remarkControllers[studentId]?.text.isNotEmpty ?? false)) ...[
                  const SizedBox(height: 12),
                  TextField(
                    controller: _remarkControllers[studentId],
                    enabled: canEdit,
                    onChanged: (value) {
                      remarksState[studentId] = value;
                    },
                    decoration: InputDecoration(
                      hintText: "Add reason (optional)...",
                      hintStyle: TextStyle(fontSize: 13, color: Colors.grey.shade500),
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      filled: true,
                      fillColor: Colors.grey.shade50,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: Colors.grey.shade200),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: Colors.grey.shade200),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: ChanzoColors.primary.withOpacity(0.5)),
                      ),
                    ),
                  ),
                ]
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatusButton(int studentId, String value, String label, Color color) {
    final isSelected = attendanceState[studentId] == value;

    return IgnorePointer(
      ignoring: !canEdit, // Prevent tapping if user doesn't have permission
      child: GestureDetector(
        onTap: () {
          setState(() {
            attendanceState[studentId] = value;
          });
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? color : Colors.grey.shade100,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: isSelected ? color : Colors.grey.shade300),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: isSelected ? Colors.white : Colors.grey.shade600,
            ),
          ),
        ),
      ),
    );
  }
}