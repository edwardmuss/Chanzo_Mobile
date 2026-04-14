import 'dart:io';
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

class AddEditResourceScreen extends StatefulWidget {
  final Map<String, dynamic>? resource; // Null for Add, populated for Edit

  const AddEditResourceScreen({super.key, this.resource});

  @override
  State<AddEditResourceScreen> createState() => _AddEditResourceScreenState();
}

class _AddEditResourceScreenState extends State<AddEditResourceScreen> {
  final AuthController authController = Get.find<AuthController>();
  final _formKey = GlobalKey<FormState>();

  bool _isLoading = false;
  bool _isLoadingDependencies = true;

  List<dynamic> _apiClasses = [];
  List<dynamic> _apiResourceTypes = [];

  // Available roles to pick from
  final List<String> _availableRoles = ['student', 'parent', 'teacher'];
  final List<String> _selectedRoles = [];

  int? _selectedClassId;
  int? _selectedStreamId;
  int? _selectedResourceTypeId;

  DateTime _uploadDate = DateTime.now();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  File? _selectedFile;
  String? _existingFileName;

  @override
  void initState() {
    super.initState();
    _fetchDependencies();
    _prefillDataIfEditing();
  }

  void _prefillDataIfEditing() {
    if (widget.resource != null) {
      final res = widget.resource!;
      _titleController.text = res['title'] ?? '';
      _descriptionController.text = res['description'] ?? '';
      _selectedResourceTypeId = res['resource_type_id'];
      _selectedClassId = res['class_id'];
      _selectedStreamId = res['stream_id'];
      _uploadDate = DateTime.tryParse(res['upload_date'] ?? '') ?? DateTime.now();

      if (res['available_for'] != null) {
        // Handle parsing JSON array if it comes as a string or list
        List<dynamic> roles = res['available_for'] is String
            ? ['parent', 'student'] // Fallback if string mapping needed, adjust based on your API
            : res['available_for'];
        _selectedRoles.addAll(roles.map((e) => e.toString()));
      }

      if (res['file'] != null) {
        _existingFileName = res['file'].toString().split('/').last;
      }
    } else {
      // Default to parent and student for new resources
      _selectedRoles.addAll(['parent', 'student']);
    }
  }

  Future<void> _fetchDependencies() async {
    final branchId = authController.activeBranchId ?? authController.user['branch_id'];
    if (branchId == null) return;
    final url = KiotaPayConstants.getClassesByBranch.replaceAll(':branch_id', branchId.toString());
    print("Branch is $branchId");

    try {
      // Fetch Classes for the selector
      final classRes = await DioHelper().get(url);

      final typeRes = await DioHelper().get(KiotaPayConstants.getResourceTypesByBranch.replaceAll(':branch_id', branchId.toString()).toString());

      setState(() {
        _apiClasses = classRes.data['data'] ?? [];
        _apiResourceTypes = typeRes.data['data'] ?? []; // Adjust based on your API structure
        _isLoadingDependencies = false;
      });
    } catch (e) {
      setState(() => _isLoadingDependencies = false);
      Get.snackbar('Error', 'Failed to load form data.', snackPosition: SnackPosition.BOTTOM);
    }
  }

  Future<void> _pickDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _uploadDate,
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
      setState(() => _uploadDate = picked);
    }
  }

  Future<void> _pickFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'doc', 'docx', 'ppt', 'pptx', 'txt', 'jpg', 'jpeg', 'png'],
    );

    if (result != null && result.files.single.path != null) {
      setState(() {
        _selectedFile = File(result.files.single.path!);
        _existingFileName = null;
      });
    }
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedResourceTypeId == null) {
      Get.snackbar('Error', 'Please select a Resource Type.', backgroundColor: Colors.redAccent, colorText: Colors.white);
      return;
    }
    if (_selectedRoles.isEmpty) {
      Get.snackbar('Error', 'Please select at least one role under "Available For".', backgroundColor: Colors.redAccent, colorText: Colors.white);
      return;
    }
    if (_selectedFile == null && widget.resource == null) {
      Get.snackbar('Error', 'Please upload a file.', backgroundColor: Colors.redAccent, colorText: Colors.white);
      return;
    }

    setState(() => _isLoading = true);

    try {
      final isEditing = widget.resource != null;
      final url = isEditing
          ? '${KiotaPayConstants.resourceCenter}/${widget.resource!['id']}'
          : '${KiotaPayConstants.resourceCenter}';

      dio.FormData formData = dio.FormData.fromMap({
        'title': _titleController.text,
        'description': _descriptionController.text,
        'resource_type_id': _selectedResourceTypeId,
        'upload_date': DateFormat('yyyy-MM-dd').format(_uploadDate),
        'school_id': authController.school['id'],
        'branch_id': authController.activeBranchId ?? authController.user['branch_id'],
      });

      // Add Class/Stream if selected
      if (_selectedClassId != null) formData.fields.add(MapEntry('class_id', _selectedClassId.toString()));
      if (_selectedStreamId != null) formData.fields.add(MapEntry('stream_id', _selectedStreamId.toString()));

      // Add Roles array
      for (var role in _selectedRoles) {
        formData.fields.add(MapEntry('available_for[]', role));
      }

      // Laravel needs _method=PUT when sending multipart/form-data for an update
      if (isEditing) {
        formData.fields.add(const MapEntry('_method', 'PUT'));
      }

      if (_selectedFile != null) {
        formData.files.add(MapEntry(
          'content_file', // Matches Laravel validation key
          await dio.MultipartFile.fromFile(_selectedFile!.path),
        ));
      }

      final response = await DioHelper().post(url, data: formData);

      if (response.statusCode == 200 || response.statusCode == 201) {
        Get.back(result: true);
        Get.snackbar('Success', 'Resource saved successfully!', backgroundColor: Colors.green, colorText: Colors.white);
      }
    } on dio.DioException catch (e) {
      Get.snackbar('Error', e.response?.data['message'] ?? 'Failed to save resource.', backgroundColor: ChanzoColors.secondary, colorText: Colors.white);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.resource == null ? 'Add Resource' : 'Edit Resource')),
      body: _isLoadingDependencies
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title
              const Text("Resource Title *", style: TextStyle(fontWeight: FontWeight.w500)),
              const SizedBox(height: 6),
              TextFormField(
                controller: _titleController,
                decoration: InputDecoration(border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
                validator: (val) => val!.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),

              // Resource Type
              const Text("Resource Type *", style: TextStyle(fontWeight: FontWeight.w500)),
              const SizedBox(height: 6),
              DropdownButtonFormField<int>(
                value: _selectedResourceTypeId,
                hint: const Text('Select Type'),
                decoration: InputDecoration(border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
                items: _apiResourceTypes.map<DropdownMenuItem<int>>((t) {
                  return DropdownMenuItem<int>(value: t['id'], child: Text(t['name']));
                }).toList(),
                onChanged: (val) => setState(() => _selectedResourceTypeId = val),
              ),
              const SizedBox(height: 16),

              // Available For (Roles)
              const Text("Available For *", style: TextStyle(fontWeight: FontWeight.w500)),
              const SizedBox(height: 6),
              Wrap(
                spacing: 8,
                children: _availableRoles.map((role) {
                  final isSelected = _selectedRoles.contains(role);
                  return FilterChip(
                    label: Text(role.capitalizeFirst!),
                    selected: isSelected,
                    selectedColor: ChanzoColors.primary.withOpacity(0.2),
                    checkmarkColor: ChanzoColors.primary,
                    onSelected: (selected) {
                      setState(() {
                        selected ? _selectedRoles.add(role) : _selectedRoles.remove(role);
                      });
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),

              // Class & Stream (Optional)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade200)),
                child: ClassStreamSelector(
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
              ),
              const SizedBox(height: 16),

              // Upload Date
              const Text("Upload Date *", style: TextStyle(fontWeight: FontWeight.w500)),
              const SizedBox(height: 6),
              InkWell(
                onTap: () => _pickDate(context),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                  decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade400), borderRadius: BorderRadius.circular(12)),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(DateFormat('MMM d, yyyy').format(_uploadDate)),
                      const Icon(Icons.calendar_today, size: 16, color: ChanzoColors.primary),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Description
              const Text("Description *", style: TextStyle(fontWeight: FontWeight.w500)),
              const SizedBox(height: 6),
              TextFormField(
                controller: _descriptionController,
                maxLines: 3,
                decoration: InputDecoration(border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
                validator: (val) => val!.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),

              // File Upload
              const Text("Content File *", style: TextStyle(fontWeight: FontWeight.w500)),
              const SizedBox(height: 6),
              ElevatedButton.icon(
                onPressed: _pickFile,
                icon: const Icon(Icons.attach_file),
                label: Text(_existingFileName ?? (_selectedFile != null ? _selectedFile!.path.split('/').last : 'Choose File')),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.grey.shade200, foregroundColor: Colors.black),
              ),
              const SizedBox(height: 32),

              // Submit
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submitForm,
                  style: ElevatedButton.styleFrom(backgroundColor: ChanzoColors.primary, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text(widget.resource == null ? 'Create Resource' : 'Update Resource', style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}