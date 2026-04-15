import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../../globalclass/chanzo_color.dart';
import '../../../globalclass/kiotapay_constants.dart';
import '../../../utils/dio_helper.dart';

class AddEditSchemeOfWorkScreen extends StatefulWidget {
  final int teacherId;
  final Map<String, dynamic>? scheme;

  const AddEditSchemeOfWorkScreen({super.key, required this.teacherId, this.scheme});

  @override
  State<AddEditSchemeOfWorkScreen> createState() => _AddEditSchemeOfWorkScreenState();
}

class _AddEditSchemeOfWorkScreenState extends State<AddEditSchemeOfWorkScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoadingDependencies = true;
  bool _isSaving = false;

  List<dynamic> _academicSessions = [];
  List<dynamic> _classes = [];
  List<dynamic> _availableTerms = [];
  List<dynamic> _availableStreams = [];
  List<dynamic> _subjects = [];
  List<dynamic> _availableStrands = [];
  List<dynamic> _availableSubStrands = [];
  List<dynamic> _availableActivities = [];

  int? _selectedSessionId;
  int? _selectedTermId;
  int? _selectedClassId;
  int? _selectedStreamId;
  int? _selectedSubjectId;
  int? _selectedStrandId;
  int? _selectedSubStrandId;
  int? _selectedActivityId;

  DateTime _date = DateTime.now();

  final _weekCtrl = TextEditingController();
  final _workCoveredCtrl = TextEditingController();
  final _remarksCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchDependencies();
  }

  void _updateStrands() {
    if (_selectedSubjectId == null || _selectedClassId == null) {
      setState(() {
        _availableStrands = [];
        _selectedStrandId = null;
        _availableSubStrands = [];
        _selectedSubStrandId = null;
        _availableActivities = [];
        _selectedActivityId = null;
      });
      return;
    }

    final subject = _subjects.firstWhere((s) => s['id'] == _selectedSubjectId, orElse: () => null);

    setState(() {
      if (subject != null) {
        // FILTER: Only show strands that belong to the currently selected Class!
        _availableStrands = (subject['strands'] as List)
            .where((strand) => strand['class_id'] == _selectedClassId)
            .toList();
      } else {
        _availableStrands = [];
      }

      // Reset downstream selections
      _selectedStrandId = null;
      _availableSubStrands = [];
      _selectedSubStrandId = null;
      _availableActivities = [];
      _selectedActivityId = null;
    });
  }

  void _updateSubStrands(int? strandId) {
    if (strandId == null) return;
    final strand = _availableStrands.firstWhere((s) => s['id'] == strandId, orElse: () => null);
    setState(() {
      _availableSubStrands = strand != null ? (strand['substrands'] ?? []) : [];
      _selectedSubStrandId = null;
      _availableActivities = [];
      _selectedActivityId = null;
    });
  }

  void _updateActivities(int? subStrandId) {
    if (subStrandId == null) return;
    final subStrand = _availableSubStrands.firstWhere((s) => s['id'] == subStrandId, orElse: () => null);
    setState(() {
      _availableActivities = subStrand != null ? (subStrand['activities'] ?? []) : [];
      _selectedActivityId = null;
    });
  }

  Future<void> _fetchDependencies() async {
    try {
      final isEdit = widget.scheme != null;
      final endpoint = isEdit
          ? '${KiotaPayConstants.schemeOfWork}/${widget.scheme!['id']}/edit-payload/${widget.teacherId}'
          : '${KiotaPayConstants.schemeOfWork}/create-payload/${widget.teacherId}';

      final response = await DioHelper().get(endpoint);

      if (response.statusCode == 200 && response.data['success'] == true) {
        setState(() {
          _academicSessions = response.data['academic_sessions'] ?? [];
          _classes = response.data['classes'] ?? [];

          // FIX: Actually populate the subjects list!
          _subjects = response.data['subjects'] ?? [];

          _isLoadingDependencies = false;
        });

        if (isEdit) _prefillData(response.data['data']);
      }
    } catch (e) {
      Get.snackbar('Error', 'Failed to load form dependencies.');
      setState(() => _isLoadingDependencies = false);
    }
  }

  void _prefillData(Map<String, dynamic> data) {
    _selectedSessionId = data['academic_session_id'];
    _updateTerms(_selectedSessionId);
    _selectedTermId = data['term_id'];

    _selectedClassId = data['class_id'];
    _updateStreams(_selectedClassId);
    _selectedStreamId = data['stream_id'];

    if (data['date'] != null) _date = DateTime.parse(data['date']);

    _weekCtrl.text = data['week']?.toString() ?? '';
    _workCoveredCtrl.text = data['work_covered'] ?? '';
    _remarksCtrl.text = data['remarks'] ?? '';

    _selectedActivityId = data['activity_id'];

    // Auto-discover the parent Subject, Strand, and SubStrand based on the Activity ID
    if (_selectedActivityId != null && _subjects.isNotEmpty) {
      for (var subject in _subjects) {
        for (var strand in (subject['strands'] ?? [])) {
          for (var subStrand in (strand['substrands'] ?? [])) {
            for (var activity in (subStrand['activities'] ?? [])) {
              if (activity['id'] == _selectedActivityId) {
                _selectedSubjectId = subject['id'];

                // Keep the class_id filter intact when prefilling
                _availableStrands = (subject['strands'] as List)
                    .where((s) => s['class_id'] == _selectedClassId)
                    .toList();

                _selectedStrandId = strand['id'];
                _availableSubStrands = strand['substrands'] ?? [];

                _selectedSubStrandId = subStrand['id'];
                _availableActivities = subStrand['activities'] ?? [];
                break;
              }
            }
          }
        }
      }
    }
  }

  void _updateTerms(int? sessionId) {
    if (sessionId == null) return;
    final session = _academicSessions.firstWhere((s) => s['id'] == sessionId, orElse: () => null);
    setState(() {
      _availableTerms = session != null ? (session['terms'] ?? []) : [];
      _selectedTermId = null;
    });
  }

  void _updateStreams(int? classId) {
    if (classId == null) return;
    final classObj = _classes.firstWhere((c) => c['id'] == classId, orElse: () => null);
    setState(() {
      _availableStreams = classObj != null ? (classObj['streams'] ?? []) : [];
      _selectedStreamId = null;
    });
  }

  Future<void> _submit(String status) async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    final payload = {
      'status': status,
      'teacher_id': widget.teacherId,
      'academic_session_id': _selectedSessionId,
      'term_id': _selectedTermId,
      'class_id': _selectedClassId,
      'stream_id': _selectedStreamId,
      'activity_id': _selectedActivityId,
      'date': DateFormat('yyyy-MM-dd').format(_date),
      'week': _weekCtrl.text,
      'work_covered': _workCoveredCtrl.text,
      'remarks': _remarksCtrl.text,
    };

    try {
      final isEdit = widget.scheme != null;
      final url = isEdit
          ? '${KiotaPayConstants.schemeOfWork}/${widget.scheme!['id']}'
          : KiotaPayConstants.schemeOfWork;

      final response = isEdit
          ? await DioHelper().put(url, data: payload)
          : await DioHelper().post(url, data: payload);

      if (response.statusCode == 200 || response.statusCode == 201) {
        Get.back(result: true);
        Get.snackbar('Success', 'Record saved as ${status.toUpperCase()}!', backgroundColor: Colors.green, colorText: Colors.white);
      }
    } catch (e) {
      Get.snackbar('Error', 'Failed to save record.');
    } finally {
      setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.scheme == null ? "Add Record of Work" : "Edit Record of Work")),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: _isSaving ? null : () => _submit('draft'),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.grey.shade600, foregroundColor: Colors.white, minimumSize: const Size(0, 50)),
                  child: const Text("Save as Draft"),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: _isSaving ? null : () => _submit('pending'),
                  style: ElevatedButton.styleFrom(backgroundColor: ChanzoColors.primary, foregroundColor: Colors.white, minimumSize: const Size(0, 50)),
                  child: _isSaving ? const CircularProgressIndicator(color: Colors.white) : const Text("Submit"),
                ),
              ),
            ],
          ),
        ),
      ),
      body: _isLoadingDependencies
          ? const Center(child: CircularProgressIndicator())
          : Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Row(
              children: [
                Expanded(child: _buildDropdown("Academic Session", _academicSessions, _selectedSessionId, (val) {
                  setState(() => _selectedSessionId = val);
                  _updateTerms(val);
                })),
                const SizedBox(width: 12),
                Expanded(child: _buildDropdown("Term", _availableTerms, _selectedTermId, (val) => setState(() => _selectedTermId = val))),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(child: _buildDropdown("Class", _classes, _selectedClassId, (val) {
                  setState(() => _selectedClassId = val);
                  _updateStreams(val);
                  _updateStrands();
                })),
                const SizedBox(width: 12),
                Expanded(child: _buildDropdown("Stream", _availableStreams, _selectedStreamId, (val) => setState(() => _selectedStreamId = val))),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _weekCtrl,
                    decoration: InputDecoration(labelText: 'Week (e.g. 5)', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: InkWell(
                    onTap: () async {
                      final picked = await showDatePicker(context: context, initialDate: _date, firstDate: DateTime(2020), lastDate: DateTime(2030));
                      if (picked != null) setState(() => _date = picked);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                      decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade400), borderRadius: BorderRadius.circular(12)),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(DateFormat('MMM d, yyyy').format(_date)),
                          const Icon(Icons.calendar_today, size: 16, color: ChanzoColors.primary),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Subject & Strand Row
            Row(
              children: [
                Expanded(child: _buildDropdown("Subject", _subjects, _selectedSubjectId, (val) {
                  setState(() => _selectedSubjectId = val);
                  _updateStrands();
                })),
                const SizedBox(width: 12),
                Expanded(child: _buildDropdown("Strand", _availableStrands, _selectedStrandId, (val) {
                  setState(() => _selectedStrandId = val);
                  _updateSubStrands(val);
                })),
              ],
            ),
            const SizedBox(height: 16),

            // Sub-Strand & Activity Row
            Row(
              children: [
                Expanded(child: _buildDropdown("Sub-Strand", _availableSubStrands, _selectedSubStrandId, (val) {
                  setState(() => _selectedSubStrandId = val);
                  _updateActivities(val);
                })),
                const SizedBox(width: 12),
                Expanded(child: _buildDropdown("Activity", _availableActivities, _selectedActivityId, (val) {
                  setState(() => _selectedActivityId = val);
                })),
              ],
            ),
            const SizedBox(height: 16),
            _buildTextField("Work Covered", _workCoveredCtrl, maxLines: 3),
            const SizedBox(height: 16),
            _buildTextField("Remarks", _remarksCtrl, maxLines: 2),
          ],
        ),
      ),
    );
  }

  Widget _buildDropdown(String label, List<dynamic> items, int? value, Function(int?) onChanged) {
    return DropdownButtonFormField<int>(
      // FIX: Ensure dropdown text doesn't overflow horizontally when names are long
      isExpanded: true,
      decoration: InputDecoration(labelText: label, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)), isDense: true),
      value: value,
      items: items.map<DropdownMenuItem<int>>((item) {
        return DropdownMenuItem<int>(
            value: item['id'],
            child: Text(
              item['name'] ?? item['year'] ?? item['term_number'] ?? '',
              overflow: TextOverflow.ellipsis,
            )
        );
      }).toList(),
      onChanged: onChanged,
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, {int maxLines = 1}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        decoration: InputDecoration(labelText: label, alignLabelWithHint: true, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
      ),
    );
  }
}