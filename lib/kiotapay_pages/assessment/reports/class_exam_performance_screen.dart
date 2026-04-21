import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shimmer/shimmer.dart';

import '../../../globalclass/chanzo_color.dart';
import '../../../globalclass/kiotapay_constants.dart';
import '../../../utils/dio_helper.dart';
import '../../../widgets/error.dart';

class ClassExamPerformanceScreen extends StatefulWidget {
  const ClassExamPerformanceScreen({super.key});

  @override
  State<ClassExamPerformanceScreen> createState() => _ClassExamPerformanceScreenState();
}

class _ClassExamPerformanceScreenState extends State<ClassExamPerformanceScreen> {
  bool _isLoadingFilters = true;
  bool _isGenerating = false;
  bool _hasError = false;

  // Raw API Data
  List<dynamic> _academicSessions = [];
  List<dynamic> _classStreamsRaw = [];

  // Filtered Dropdown Lists
  List<dynamic> _availableTerms = [];
  List<dynamic> _availableExams = [];
  List<dynamic> _availableClasses = [];
  List<dynamic> _availableStreams = [];

  // Selections
  int? _selectedSessionId;
  int? _selectedTermId;
  int? _selectedExamId;
  int? _selectedClassId;
  int? _selectedStreamId;

  // Report Data
  List<dynamic> _reportData = [];
  bool _reportGenerated = false;

  @override
  void initState() {
    super.initState();
    _fetchFilters();
  }

  Future<void> _fetchFilters() async {
    setState(() {
      _isLoadingFilters = true;
      _hasError = false;
    });

    try {
      final response = await DioHelper().get(KiotaPayConstants.reportClassExamPerformance);

      if (response.statusCode == 200 && response.data['success'] == true) {
        final data = response.data['data'];

        setState(() {
          _academicSessions = data['academicSessions'] ?? [];
          _classStreamsRaw = data['class_streams'] ?? [];

          // Build Unique Classes from the flat class_streams array
          _availableClasses = _getUniqueClasses();

          // Auto-select the first available session if null
          _selectedSessionId = data['selected_academic_session_id'] ??
              (_academicSessions.isNotEmpty ? _academicSessions.first['id'] : null);

          if (_selectedSessionId != null) {
            _updateTerms(_selectedSessionId!);
          }

          _isLoadingFilters = false;
        });
      } else {
        setState(() => _hasError = true);
      }
    } catch (e) {
      setState(() => _hasError = true);
    } finally {
      if (mounted && _isLoadingFilters) setState(() => _isLoadingFilters = false);
    }
  }

  Future<void> _generateReport() async {
    if (_selectedSessionId == null || _selectedClassId == null || _selectedTermId == null) {
      Get.snackbar('Required Fields', 'Please select a Session, Term, and Class to generate the report.', backgroundColor: Colors.orange, colorText: Colors.white);
      return;
    }

    setState(() => _isGenerating = true);

    try {
      final Map<String, dynamic> queryParams = {
        'academic_session_id': _selectedSessionId,
        'class_id': _selectedClassId,
        'term_id': _selectedTermId,
      };
      if (_selectedStreamId != null) queryParams['stream_id'] = _selectedStreamId;
      if (_selectedExamId != null) queryParams['exam_id'] = _selectedExamId;

      final response = await DioHelper().get(
        KiotaPayConstants.reportClassExamPerformance,
        queryParameters: queryParams,
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        setState(() {
          _reportData = response.data['data']['report'] ?? [];
          _reportGenerated = true;
        });

        if (_reportData.isEmpty) {
          Get.snackbar('Notice', 'No results found for the selected filters.', backgroundColor: Colors.blue, colorText: Colors.white);
        }
      }
    } catch (e) {
      Get.snackbar('Error', 'Failed to generate report. Try again.', backgroundColor: Colors.red, colorText: Colors.white);
    } finally {
      setState(() => _isGenerating = false);
    }
  }

  // --- CASCADING LOGIC HELPER METHODS ---

  List<dynamic> _getUniqueClasses() {
    final Map<int, dynamic> uniqueMap = {};
    for (var cs in _classStreamsRaw) {
      uniqueMap[cs['class_id']] = {'id': cs['class_id'], 'name': cs['class_name']};
    }
    return uniqueMap.values.toList();
  }

  void _updateTerms(int sessionId) {
    final session = _academicSessions.firstWhere((s) => s['id'] == sessionId, orElse: () => null);
    setState(() {
      _availableTerms = session != null ? (session['terms'] ?? []) : [];
      _selectedTermId = null;
      _availableExams = [];
      _selectedExamId = null;
    });
  }

  void _updateExams(int termId) {
    final term = _availableTerms.firstWhere((t) => t['id'] == termId, orElse: () => null);
    setState(() {
      _availableExams = term != null ? (term['exams'] ?? []) : [];
      _selectedExamId = null;
    });
  }

  void _updateStreams(int classId) {
    setState(() {
      // Filter the raw array to find streams matching this class
      _availableStreams = _classStreamsRaw
          .where((cs) => cs['class_id'] == classId)
          .map((cs) => {'id': cs['stream_id'], 'name': cs['stream_name']})
          .toList();
      _selectedStreamId = null;
    });
  }

  // --- UI BUILDERS ---

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Class Exam Performance"),
        elevation: 0,
      ),
      body: _isLoadingFilters
          ? const Center(child: CircularProgressIndicator())
          : _hasError
          ? ErrorWidgetUniversal(title: "Error", description: "Failed to load report filters.", onRetry: _fetchFilters)
          : Column(
        children: [
          _buildFilterSection(isDark),
          Expanded(
            child: _isGenerating
                ? _buildShimmerLoader(context)
                : !_reportGenerated
                ? _buildInitialState(isDark)
                : _reportData.isEmpty
                ? _buildNoDataState(isDark)
                : _buildReportList(isDark),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterSection(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? Theme.of(context).cardColor : ChanzoColors.primary.withOpacity(0.05),
        border: Border(bottom: BorderSide(color: isDark ? Colors.grey.shade800 : Colors.grey.shade200)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: _buildDropdown("Session", _academicSessions.map((s) => {'id': s['id'], 'name': s['title'] ?? s['year']}).toList(), _selectedSessionId, (val) {
                  setState(() => _selectedSessionId = val);
                  if (val != null) _updateTerms(val);
                }, isDark),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildDropdown("Term", _availableTerms.map((t) => {'id': t['id'], 'name': "Term ${t['term_number']}"}).toList(), _selectedTermId, (val) {
                  setState(() => _selectedTermId = val);
                  if (val != null) _updateExams(val);
                }, isDark),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildDropdown("Class", _availableClasses, _selectedClassId, (val) {
                  setState(() => _selectedClassId = val);
                  if (val != null) _updateStreams(val);
                }, isDark),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildDropdown("Stream (All)", [{'id': null, 'name': 'All Streams'}, ..._availableStreams], _selectedStreamId, (val) {
                  setState(() => _selectedStreamId = val);
                }, isDark),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildDropdown("Specific Exam (Optional)", [{'id': null, 'name': 'All Term Exams'}, ..._availableExams], _selectedExamId, (val) {
            setState(() => _selectedExamId = val);
          }, isDark),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _isGenerating ? null : _generateReport,
            icon: const Icon(Icons.analytics),
            label: const Text("Generate Report", style: TextStyle(fontWeight: FontWeight.bold)),
            style: ElevatedButton.styleFrom(
              backgroundColor: ChanzoColors.primary,
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 48),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildDropdown(String label, List<dynamic> items, int? value, Function(int?) onChanged, bool isDark) {
    return DropdownButtonFormField<int>(
      isExpanded: true,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: isDark ? Colors.grey.shade400 : Colors.grey.shade600, fontSize: 13),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        filled: true,
        fillColor: isDark ? Colors.grey.shade900 : Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        isDense: true,
      ),
      value: value,
      dropdownColor: isDark ? Colors.grey.shade900 : Colors.white,
      items: items.map<DropdownMenuItem<int>>((item) {
        return DropdownMenuItem<int>(
          value: item['id'],
          child: Text(item['name'].toString(), overflow: TextOverflow.ellipsis),
        );
      }).toList(),
      onChanged: onChanged,
    );
  }

  Widget _buildReportList(bool isDark) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _reportData.length,
      itemBuilder: (context, index) {
        final student = _reportData[index];
        final meanScore = double.tryParse(student['mean_score']?.toString() ?? '') ?? 0.0;
        final isGraded = student['mean_score'] != null;

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          elevation: isDark ? 0 : 1,
          color: isDark ? Theme.of(context).cardColor : Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: isDark ? Colors.grey.shade800 : Colors.grey.shade200),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            leading: CircleAvatar(
              backgroundColor: isGraded ? ChanzoColors.secondary.withOpacity(0.1) : Colors.grey.withOpacity(0.1),
              child: Text("${index + 1}", style: TextStyle(color: isGraded ? ChanzoColors.secondary : Colors.grey, fontWeight: FontWeight.bold)),
            ),
            title: Text(student['student_name'] ?? 'Unknown', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            subtitle: Text("Adm: ${student['admission_no']} • ${student['stream_name']}", style: TextStyle(fontSize: 12, color: isDark ? Colors.grey.shade400 : Colors.grey.shade600)),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  isGraded ? "${meanScore.toStringAsFixed(1)}%" : "N/A",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isGraded ? (meanScore >= 50 ? Colors.green : Colors.red) : Colors.grey,
                  ),
                ),
                if (student['mean_grade'] != null)
                  Text("Grade: ${student['mean_grade']}", style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildInitialState(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.assessment_outlined, size: 64, color: isDark ? Colors.grey.shade700 : Colors.grey.shade400),
          const SizedBox(height: 16),
          Text("Ready to Generate", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.grey.shade800)),
          const SizedBox(height: 8),
          Text("Select your filters above and click Generate.", style: TextStyle(color: isDark ? Colors.grey.shade400 : Colors.grey.shade600)),
        ],
      ),
    );
  }

  Widget _buildNoDataState(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.query_stats, size: 64, color: isDark ? Colors.grey.shade700 : Colors.grey.shade400),
          const SizedBox(height: 16),
          Text("No Data Available", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.grey.shade800)),
          const SizedBox(height: 8),
          Text("No results were found for the selected filters.", style: TextStyle(color: isDark ? Colors.grey.shade400 : Colors.grey.shade600)),
        ],
      ),
    );
  }

  Widget _buildShimmerLoader(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 6,
      itemBuilder: (_, __) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Shimmer.fromColors(
          baseColor: isDark ? Colors.grey.shade800 : Colors.grey.shade300,
          highlightColor: isDark ? Colors.grey.shade700 : Colors.grey.shade100,
          child: Container(height: 70, decoration: BoxDecoration(color: isDark ? Colors.grey.shade900 : Colors.white, borderRadius: BorderRadius.circular(12))),
        ),
      ),
    );
  }
}