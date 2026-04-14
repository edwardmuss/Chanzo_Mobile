import 'dart:io';
import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:dio/dio.dart' as dio;
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../globalclass/chanzo_color.dart';
import '../../globalclass/kiotapay_constants.dart';
import '../../utils/dio_helper.dart';
import '../kiotapay_authentication/AuthController.dart';
import '../../widgets/class_stream_selector.dart';

class TeacherAddEditHomeworkScreen extends StatefulWidget {
  final Map<String, dynamic>? homework; // If null, it's CREATE mode. If provided, it's EDIT mode.

  const TeacherAddEditHomeworkScreen({super.key, this.homework});

  @override
  State<TeacherAddEditHomeworkScreen> createState() => _TeacherAddEditHomeworkScreenState();
}

class _TeacherAddEditHomeworkScreenState extends State<TeacherAddEditHomeworkScreen> {
  final AuthController authController = Get.find<AuthController>();
  final _formKey = GlobalKey<FormState>();

  bool _isLoading = false;
  bool _isLoadingClassesAndSubjects = true;

  List<dynamic> _apiClasses = [];
  List<dynamic> _apiSubjects = [];

  int? _selectedClassId;
  int? _selectedStreamId;
  int? _selectedSubjectId;

  DateTime? _homeworkDate = DateTime.now();
  DateTime? _submissionDate;
  DateTime? _evaluationDate;

  final TextEditingController _descriptionController = TextEditingController();
  File? _selectedFile;
  String? _existingFileName;

  @override
  void initState() {
    super.initState();
    _fetchFormData();
    _prefillDataIfEditing();
  }

  void _prefillDataIfEditing() {
    if (widget.homework != null) {
      final hw = widget.homework!;
      _selectedClassId = hw['class_id'];
      _selectedStreamId = hw['stream_id'];
      _selectedSubjectId = hw['subject_id'];
      _descriptionController.text = hw['description'] ?? '';
      _homeworkDate = DateTime.tryParse(hw['homework_date'] ?? '');
      _submissionDate = DateTime.tryParse(hw['submission_date'] ?? '');
      _evaluationDate = DateTime.tryParse(hw['evaluation_date'] ?? '');
      if (hw['file'] != null) {
        _existingFileName = hw['file'].toString().split('/').last;
      }
    }
  }

  Future<void> _fetchFormData() async {
    final branchId = authController.activeBranchId ?? authController.user['branch_id'];
    if (branchId == null) return;

    try {
      // Fetch Classes
      final classRes = await DioHelper().get('${KiotaPayConstants.baseUrl}classes/$branchId');
      // Fetch Subjects
      final subjectRes = await DioHelper().get('${KiotaPayConstants.getTeacherSubjects}');

      setState(() {
        _apiClasses = classRes.data['data'] ?? [];
        _apiSubjects = subjectRes.data['data'] ?? [];
        _isLoadingClassesAndSubjects = false;
      });
    } catch (e) {
      setState(() => _isLoadingClassesAndSubjects = false);
      Get.snackbar('Error', 'Failed to load form data.', snackPosition: SnackPosition.BOTTOM);
    }
  }

  Future<void> _pickDate(BuildContext context, String type) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(colorScheme: const ColorScheme.light(primary: ChanzoColors.primary)),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        if (type == 'homework') _homeworkDate = picked;
        if (type == 'submission') _submissionDate = picked;
        if (type == 'evaluation') _evaluationDate = picked;
      });
    }
  }

  Future<void> _pickFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'doc', 'docx', 'jpg', 'jpeg', 'png'],
    );

    if (result != null && result.files.single.path != null) {
      setState(() {
        _selectedFile = File(result.files.single.path!);
        _existingFileName = null; // Clear existing file name visual if they pick a new one
      });
    }
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedClassId == null || _selectedStreamId == null || _selectedSubjectId == null) {
      Get.snackbar('Error', 'Please select Class, Stream, and Subject.', backgroundColor: Colors.redAccent, colorText: Colors.white);
      return;
    }
    if (_homeworkDate == null || _submissionDate == null || _evaluationDate == null) {
      Get.snackbar('Error', 'Please select all required dates.', backgroundColor: Colors.redAccent, colorText: Colors.white);
      return;
    }

    setState(() => _isLoading = true);

    try {
      final isEditing = widget.homework != null;
      final url = isEditing
          ? '${KiotaPayConstants.addEditHomeWork}/${widget.homework!['id']}'
          : '${KiotaPayConstants.addEditHomeWork}';

      // Use FormData for file uploads
      dio.FormData formData = dio.FormData.fromMap({
        'class_id': _selectedClassId,
        'stream_id': _selectedStreamId,
        'subject_id': _selectedSubjectId,
        'homework_date': DateFormat('yyyy-MM-dd').format(_homeworkDate!),
        'submission_date': DateFormat('yyyy-MM-dd').format(_submissionDate!),
        'evaluation_date': DateFormat('yyyy-MM-dd').format(_evaluationDate!),
        'description': _descriptionController.text,
      });

      // Laravel needs _method=PUT when sending multipart/form-data for an update
      if (isEditing) {
        formData.fields.add(const MapEntry('_method', 'PUT'));
      }

      if (_selectedFile != null) {
        formData.files.add(MapEntry(
          'file',
          await dio.MultipartFile.fromFile(_selectedFile!.path),
        ));
      }

      final response = await DioHelper().post(url, data: formData); // Note: We use POST even for edit because of the _method spoof

      if (response.statusCode == 200 || response.statusCode == 201) {
        Get.back(result: true); // Return true to tell the list screen to refresh
        Get.snackbar('Success', 'Homework saved successfully!', backgroundColor: Colors.green, colorText: Colors.white);
      }
    } on dio.DioException catch (e) {
      Get.snackbar('Error', e.response?.data['message'] ?? 'Failed to save homework.', backgroundColor: ChanzoColors.secondary, colorText: Colors.white);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.homework == null ? 'Add Homework' : 'Edit Homework')),
      body: _isLoadingClassesAndSubjects
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Class & Stream
              ClassStreamSelector(
                classes: _apiClasses,
                initialClassId: _selectedClassId,
                initialStreamId: _selectedStreamId,
                onChanged: (cId, sId) {
                  setState(() {
                    _selectedClassId = cId;
                    _selectedStreamId = sId;
                  });
                },
              ),
              const SizedBox(height: 16),

              // Subject Dropdown
              const Text("Select Subject", style: TextStyle(fontWeight: FontWeight.w500)),
              const SizedBox(height: 6),
              DropdownButtonFormField<int>(
                value: _selectedSubjectId,
                hint: const Text('Choose a subject'),
                decoration: InputDecoration(border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
                items: _apiSubjects.map<DropdownMenuItem<int>>((s) {
                  return DropdownMenuItem<int>(value: s['id'], child: Text(s['name']));
                }).toList(),
                onChanged: (val) => setState(() => _selectedSubjectId = val),
                validator: (val) => val == null ? 'Required' : null,
              ),
              const SizedBox(height: 16),

              // Dates
              Row(
                children: [
                  Expanded(child: _buildDateSelector('Assigned Date', _homeworkDate, () => _pickDate(context, 'homework'))),
                  const SizedBox(width: 12),
                  Expanded(child: _buildDateSelector('Due Date', _submissionDate, () => _pickDate(context, 'submission'))),
                ],
              ),
              const SizedBox(height: 16),
              _buildDateSelector('Evaluation Target Date', _evaluationDate, () => _pickDate(context, 'evaluation')),
              const SizedBox(height: 16),

              // Description
              const Text("Description / Instructions", style: TextStyle(fontWeight: FontWeight.w500)),
              const SizedBox(height: 6),
              TextFormField(
                controller: _descriptionController,
                maxLines: 4,
                decoration: InputDecoration(border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
                validator: (val) => val!.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),

              // File Upload
              const Text("Attachment (Optional)", style: TextStyle(fontWeight: FontWeight.w500)),
              const SizedBox(height: 6),
              ElevatedButton.icon(
                onPressed: _pickFile,
                icon: const Icon(Icons.attach_file),
                label: Text(_existingFileName ?? (_selectedFile != null ? _selectedFile!.path.split('/').last : 'Choose File')),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.grey.shade200, foregroundColor: Colors.black),
              ),
              const SizedBox(height: 32),

              // Submit Button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submitForm,
                  style: ElevatedButton.styleFrom(backgroundColor: ChanzoColors.primary, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text(widget.homework == null ? 'Create Homework' : 'Update Homework', style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDateSelector(String label, DateTime? date, VoidCallback onTap) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
        const SizedBox(height: 4),
        InkWell(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
            decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade400), borderRadius: BorderRadius.circular(12)),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(date == null ? 'Select Date' : DateFormat('MMM d, yyyy').format(date)),
                const Icon(Icons.calendar_today, size: 16, color: ChanzoColors.primary),
              ],
            ),
          ),
        ),
      ],
    );
  }
}