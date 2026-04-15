import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../../globalclass/chanzo_color.dart';
import '../../../globalclass/kiotapay_constants.dart';
import '../../../utils/dio_helper.dart';

class AddEditLessonPlanScreen extends StatefulWidget {
  final int teacherId;
  final Map<String, dynamic>? lessonPlan; // Null for Create, Populated for Edit

  const AddEditLessonPlanScreen({super.key, required this.teacherId, this.lessonPlan});

  @override
  State<AddEditLessonPlanScreen> createState() => _AddEditLessonPlanScreenState();
}

class _AddEditLessonPlanScreenState extends State<AddEditLessonPlanScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoadingDependencies = true;
  bool _isSaving = false;

  // Dependencies
  List<dynamic> _academicSessions = [];
  List<dynamic> _classes = [];
  List<dynamic> _availableTerms = [];
  List<dynamic> _availableStreams = [];
  List<dynamic> _subjects = [];
  List<dynamic> _availableStrands = [];
  List<dynamic> _availableSubStrands = [];
  List<dynamic> _availableActivities = [];

  // Selections
  int? _selectedSessionId;
  int? _selectedTermId;
  int? _selectedClassId;
  int? _selectedStreamId;
  int? _selectedSubjectId;
  int? _selectedStrandId;
  int? _selectedSubStrandId;
  int? _selectedActivityId;

  // Date and Time
  DateTime _date = DateTime.now();
  TimeOfDay? _startTime;
  TimeOfDay? _stopTime;

  // Controllers
  final _outcomeCtrl = TextEditingController();
  final _inquiryCtrl = TextEditingController();
  final _resourcesCtrl = TextEditingController();
  final _introCtrl = TextEditingController();
  final _conclusionCtrl = TextEditingController();
  final _summaryCtrl = TextEditingController();
  final _reflectionCtrl = TextEditingController();
  final _organisationCtrl = TextEditingController();
  final _pcisCtrl = TextEditingController();
  final _valuesCtrl = TextEditingController();
  final _rollCtrl = TextEditingController();

  // Dynamic Lesson Development Steps
  List<TextEditingController> _developmentSteps = [TextEditingController()];

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
        _availableStrands = (subject['strands'] as List)
            .where((strand) => strand['class_id'] == _selectedClassId)
            .toList();
      } else {
        _availableStrands = [];
      }

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
      final isEdit = widget.lessonPlan != null;
      final endpoint = isEdit
          ? '${KiotaPayConstants.lessonPlan}/${widget.lessonPlan!['id']}/edit-payload/${widget.teacherId}'
          : '${KiotaPayConstants.lessonPlan}/create-payload/${widget.teacherId}';

      final response = await DioHelper().get(endpoint);

      if (response.statusCode == 200 && response.data['success'] == true) {
        setState(() {
          _academicSessions = response.data['academic_sessions'] ?? [];
          _classes = response.data['classes'] ?? [];
          _subjects = response.data['subjects'] ?? [];
          _isLoadingDependencies = false;
        });

        if (isEdit) {
          _prefillData(response.data['data']);
        }
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
    if (data['time'] is Map) {
      _startTime = _parseTimeOfDay(data['time']['start_time']);
      _stopTime = _parseTimeOfDay(data['time']['stop_time']);
    }

    _outcomeCtrl.text = data['specific_learning_outcome'] ?? '';
    _inquiryCtrl.text = data['key_inquiry_question'] ?? '';
    _resourcesCtrl.text = data['learning_resources'] ?? '';
    _introCtrl.text = data['introduction'] ?? '';
    _conclusionCtrl.text = data['conclusion'] ?? '';
    _summaryCtrl.text = data['summary'] ?? '';
    _reflectionCtrl.text = data['reflection'] ?? '';
    _organisationCtrl.text = data['organisation_of_learning'] ?? '';
    _pcisCtrl.text = data['pcis'] ?? '';
    _valuesCtrl.text = data['values'] ?? '';
    _rollCtrl.text = data['roll']?.toString() ?? '';

    _selectedActivityId = data['activity_id'];

    // Auto-discover the parent Subject, Strand, and SubStrand based on the Activity ID
    if (_selectedActivityId != null && _subjects.isNotEmpty) {
      for (var subject in _subjects) {
        for (var strand in (subject['strands'] ?? [])) {
          for (var subStrand in (strand['substrands'] ?? [])) {
            for (var activity in (subStrand['activities'] ?? [])) {
              if (activity['id'] == _selectedActivityId) {
                _selectedSubjectId = subject['id'];

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

    // Handle nested steps
    if (data['lesson_development'] is Map) {
      _developmentSteps.clear();
      (data['lesson_development'] as Map).forEach((key, value) {
        _developmentSteps.add(TextEditingController(text: value.toString()));
      });
    }
    if (_developmentSteps.isEmpty) _developmentSteps.add(TextEditingController());
  }

  TimeOfDay? _parseTimeOfDay(String? timeStr) {
    if (timeStr == null) return null;
    final parts = timeStr.split(':');
    return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
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

    // Build the dynamic steps JSON
    Map<String, String> stepsJson = {};
    for (int i = 0; i < _developmentSteps.length; i++) {
      if (_developmentSteps[i].text.isNotEmpty) {
        stepsJson['step_${i + 1}'] = _developmentSteps[i].text;
      }
    }

    final payload = {
      'status': status,
      'teacher_id': widget.teacherId,
      'academic_session_id': _selectedSessionId,
      'term_id': _selectedTermId,
      'class_id': _selectedClassId,
      'stream_id': _selectedStreamId,
      'activity_id': _selectedActivityId,
      'date': DateFormat('yyyy-MM-dd').format(_date),
      if (_startTime != null) 'start_time': "${_startTime!.hour.toString().padLeft(2, '0')}:${_startTime!.minute.toString().padLeft(2, '0')}",
      if (_stopTime != null) 'stop_time': "${_stopTime!.hour.toString().padLeft(2, '0')}:${_stopTime!.minute.toString().padLeft(2, '0')}",

      'organisation_of_learning': _organisationCtrl.text,
      'pcis': _pcisCtrl.text,
      'values': _valuesCtrl.text,
      'roll': _rollCtrl.text,

      'specific_learning_outcome': _outcomeCtrl.text,
      'key_inquiry_question': _inquiryCtrl.text,
      'learning_resources': _resourcesCtrl.text,
      'introduction': _introCtrl.text,
      'lesson_development': stepsJson,
      'conclusion': _conclusionCtrl.text,
      'summary': _summaryCtrl.text,
      'reflection': _reflectionCtrl.text,
    };

    try {
      final isEdit = widget.lessonPlan != null;
      final url = isEdit
          ? '${KiotaPayConstants.lessonPlan}/${widget.lessonPlan!['id']}'
          : KiotaPayConstants.lessonPlan;

      final response = isEdit
          ? await DioHelper().put(url, data: payload)
          : await DioHelper().post(url, data: payload);

      if (response.statusCode == 200 || response.statusCode == 201) {
        Get.back(result: true);
        Get.snackbar('Success', 'Lesson plan saved as ${status.toUpperCase()}!', backgroundColor: Colors.green, colorText: Colors.white);
      }
    } catch (e) {
      Get.snackbar('Error', 'Failed to save lesson plan.');
    } finally {
      setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.lessonPlan == null ? "Create Lesson Plan" : "Edit Lesson Plan")),
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
            const Text("Basic Info", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: ChanzoColors.primary)),
            const SizedBox(height: 12),

            // Row 1: Session & Term
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

            // Row 2: Class & Stream
            Row(
              children: [
                Expanded(child: _buildDropdown("Class", _classes, _selectedClassId, (val) {
                  setState(() => _selectedClassId = val);
                  _updateStreams(val);
                  _updateStrands(); // Update strands if class changes!
                })),
                const SizedBox(width: 12),
                Expanded(child: _buildDropdown("Stream", _availableStreams, _selectedStreamId, (val) => setState(() => _selectedStreamId = val))),
              ],
            ),
            const SizedBox(height: 16),

            // Row 3: Date & Time Pickers
            Row(
              children: [
                Expanded(
                  flex: 2,
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
                const SizedBox(width: 12),
                Expanded(
                  child: InkWell(
                    onTap: () async {
                      final picked = await showTimePicker(context: context, initialTime: _startTime ?? TimeOfDay.now());
                      if (picked != null) setState(() => _startTime = picked);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                      decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade400), borderRadius: BorderRadius.circular(12)),
                      child: Text(_startTime?.format(context) ?? 'Start Time', textAlign: TextAlign.center),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: InkWell(
                    onTap: () async {
                      final picked = await showTimePicker(context: context, initialTime: _stopTime ?? TimeOfDay.now());
                      if (picked != null) setState(() => _stopTime = picked);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                      decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade400), borderRadius: BorderRadius.circular(12)),
                      child: Text(_stopTime?.format(context) ?? 'End Time', textAlign: TextAlign.center),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            const Text("Curriculum", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: ChanzoColors.primary)),
            const SizedBox(height: 12),

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
            const SizedBox(height: 24),

            const Text("Content", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: ChanzoColors.primary)),
            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 16.0),
                    child: TextFormField(
                      controller: _rollCtrl,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: "Roll (Number of Students)",
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                ),
              ],
            ),

            _buildTextField("Specific Learning Outcome", _outcomeCtrl, maxLines: 2),
            _buildTextField("Key Inquiry Question", _inquiryCtrl),
            _buildTextField("Learning Resources", _resourcesCtrl, maxLines: 2),
            _buildTextField("Introduction", _introCtrl, maxLines: 2),
            _buildTextField("Organisation of Learning", _organisationCtrl, maxLines: 2),
            _buildTextField("PCIs (Pertinent & Contemporary Issues)", _pcisCtrl, maxLines: 2),
            _buildTextField("Core Values", _valuesCtrl, maxLines: 2),

            // Dynamic Lesson Development Steps
            const SizedBox(height: 12),
            const Text("Lesson Development Steps", style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            ..._developmentSteps.asMap().entries.map((entry) {
              int idx = entry.key;
              return Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: entry.value,
                        decoration: InputDecoration(
                          hintText: "Step ${idx + 1}",
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          isDense: true,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.remove_circle, color: Colors.red),
                      onPressed: () {
                        if (_developmentSteps.length > 1) {
                          setState(() => _developmentSteps.removeAt(idx));
                        }
                      },
                    )
                  ],
                ),
              );
            }),
            TextButton.icon(
              onPressed: () => setState(() => _developmentSteps.add(TextEditingController())),
              icon: const Icon(Icons.add),
              label: const Text("Add Step"),
            ),
            const SizedBox(height: 12),

            _buildTextField("Conclusion", _conclusionCtrl, maxLines: 2),
            _buildTextField("Summary", _summaryCtrl, maxLines: 2),
            _buildTextField("Reflection", _reflectionCtrl, maxLines: 2),
          ],
        ),
      ),
    );
  }

  Widget _buildDropdown(String label, List<dynamic> items, int? value, Function(int?) onChanged) {
    return DropdownButtonFormField<int>(
      isExpanded: true, // Prevents text overflow errors for long subject names!
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
        decoration: InputDecoration(
          labelText: label,
          alignLabelWithHint: true,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }
}