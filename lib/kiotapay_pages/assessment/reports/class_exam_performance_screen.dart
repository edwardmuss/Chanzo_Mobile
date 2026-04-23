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
        final filters = data['filters'] ?? {};

        setState(() {
          _academicSessions = filters['academic_sessions'] ?? [];
          _classStreamsRaw = filters['class_streams'] ?? [];

          _availableClasses = _getUniqueClasses();

          _selectedSessionId = data['selected_academic_session_id'] ??
              (_academicSessions.isNotEmpty ? _academicSessions.first['id'] : null);

          _selectedTermId = data['selected_term_id'];
          _selectedExamId = data['selected_exam_id'];
          _selectedClassId = data['selected_class_id'];
          _selectedStreamId = data['selected_stream_id'];

          if (_selectedSessionId != null) _updateTerms(_selectedSessionId!);
          if (_selectedTermId != null) _updateExams(_selectedTermId!);
          if (_selectedClassId != null) _updateStreams(_selectedClassId!);

          // Safely check for either 'results' or 'report'
          final initialData = data['results'] ?? data['report'] ?? [];
          if (initialData.isNotEmpty) {
            _reportData = initialData;
            _reportGenerated = true;
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
          // Safely check for either 'results' or 'report'
          _reportData = response.data['data']['results'] ?? response.data['data']['report'] ?? [];
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
    _availableTerms = session != null ? (session['terms'] ?? []) : [];

    if (!_availableTerms.any((t) => t['id'] == _selectedTermId)) {
      _selectedTermId = null;
      _availableExams = [];
      _selectedExamId = null;
    }
  }

  void _updateExams(int termId) {
    final term = _availableTerms.firstWhere((t) => t['id'] == termId, orElse: () => null);
    _availableExams = term != null ? (term['exams'] ?? []) : [];

    if (!_availableExams.any((e) => e['id'] == _selectedExamId)) {
      _selectedExamId = null;
    }
  }

  void _updateStreams(int classId) {
    _availableStreams = _classStreamsRaw
        .where((cs) => cs['class_id'] == classId)
        .map((cs) => {'id': cs['stream_id'], 'name': cs['stream_name']})
        .toList();

    if (!_availableStreams.any((s) => s['id'] == _selectedStreamId)) {
      _selectedStreamId = null;
    }
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
                child: _buildDropdown(
                    "Session",
                    [{'id': null, 'name': 'Select Session'}, ..._academicSessions.map((s) => {'id': s['id'], 'name': s['title'] ?? s['year']})],
                    _selectedSessionId,
                        (val) {
                      setState(() {
                        _selectedSessionId = val;
                        if (val != null) _updateTerms(val);
                      });
                    },
                    isDark
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildDropdown(
                    "Term",
                    [{'id': null, 'name': 'Select Term'}, ..._availableTerms.map((t) => {'id': t['id'], 'name': "Term ${t['term_number']}"})],
                    _selectedTermId,
                        (val) {
                      setState(() {
                        _selectedTermId = val;
                        if (val != null) _updateExams(val);
                      });
                    },
                    isDark
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildDropdown(
                    "Class",
                    [{'id': null, 'name': 'Select Class'}, ..._availableClasses],
                    _selectedClassId,
                        (val) {
                      setState(() {
                        _selectedClassId = val;
                        if (val != null) _updateStreams(val);
                      });
                    },
                    isDark
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildDropdown(
                    "Stream (All)",
                    [{'id': null, 'name': 'All Streams'}, ..._availableStreams],
                    _selectedStreamId,
                        (val) {
                      setState(() => _selectedStreamId = val);
                    },
                    isDark
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildDropdown(
              "Specific Exam (Optional)",
              [{'id': null, 'name': 'All Term Exams'}, ..._availableExams],
              _selectedExamId,
                  (val) {
                setState(() => _selectedExamId = val);
              },
              isDark
          ),
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
        final item = _reportData[index];
        final studentInfo = item['student'] ?? item; // Handles both old and new JSON formats gracefully!

        // Score logic - Extract from the ROOT of the item, NOT from studentInfo
        final meanScore = double.tryParse(item['mean_score']?.toString() ?? '') ?? 0.0;
        final isGraded = item['mean_score'] != null;
        final meanGrade = item['mean_grade'];
        final List subjects = item['subjects'] ?? [];

        // UI Strings
        final studentName = studentInfo['name'] ?? studentInfo['student_name'] ?? 'Unknown';
        final admissionNo = studentInfo['admission_no'] ?? 'N/A';
        final streamName = studentInfo['stream_name'] ?? 'N/A';

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          elevation: isDark ? 0 : 1,
          color: isDark ? Theme.of(context).cardColor : Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: isDark ? Colors.grey.shade800 : Colors.grey.shade200),
          ),
          child: ExpansionTile(
            tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            leading: CircleAvatar(
              backgroundColor: isGraded ? ChanzoColors.secondary.withOpacity(0.1) : Colors.grey.withOpacity(0.1),
              child: Text("${index + 1}", style: TextStyle(color: isGraded ? ChanzoColors.secondary : Colors.grey, fontWeight: FontWeight.bold)),
            ),
            title: Text(studentName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            subtitle: Text("Adm: $admissionNo • $streamName", style: TextStyle(fontSize: 12, color: isDark ? Colors.grey.shade400 : Colors.grey.shade600)),

            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      isGraded ? "${meanScore.toStringAsFixed(1)}%" : "N/A",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: isGraded ? (meanScore >= 50 ? Colors.green : Colors.red) : Colors.grey,
                      ),
                    ),
                    if (meanGrade != null)
                      Text("Grade: $meanGrade", style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                  ],
                ),
                const SizedBox(width: 8),
                Icon(Icons.expand_more, color: isDark ? Colors.white54 : Colors.grey, size: 20),
              ],
            ),
            children: [
              if (subjects.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text("No subject data available.", style: TextStyle(color: Colors.grey.shade500, fontStyle: FontStyle.italic)),
                )
              else
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.black12 : Colors.grey.shade50,
                    borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(12), bottomRight: Radius.circular(12)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: subjects.map((subject) {
                      final List papers = subject['exam_papers'] ?? [];
                      final subjectScore = subject['overall_score']?.toString() ?? '-';
                      final subjectGrade = subject['grade'] ?? '-';

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    subject['subject_name'] ?? 'Unknown Subject',
                                    style: TextStyle(fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87),
                                  ),
                                ),
                                Text(
                                  "$subjectScore ($subjectGrade)",
                                  style: const TextStyle(fontWeight: FontWeight.bold, color: ChanzoColors.primary),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            if (papers.isNotEmpty)
                              ...papers.map((paper) {
                                final pName = paper['exam_paper_name'] ?? 'Paper';
                                final pScore = paper['score']?.toString() ?? '-';
                                final pMax = paper['max_marks']?.toString() ?? '-';
                                final pGrade = paper['grade'] ?? '-';

                                return Padding(
                                  padding: const EdgeInsets.only(left: 12.0, bottom: 4.0),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text("↳ ", style: TextStyle(color: Colors.grey)),
                                      Expanded(
                                        child: Text(
                                          pName,
                                          style: TextStyle(fontSize: 13, color: isDark ? Colors.grey.shade400 : Colors.grey.shade700),
                                        ),
                                      ),
                                      Text(
                                        "$pScore/$pMax ($pGrade)",
                                        style: TextStyle(fontSize: 13, color: isDark ? Colors.grey.shade300 : Colors.grey.shade800),
                                      ),
                                    ],
                                  ),
                                );
                              }),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                )
            ],
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
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text("Select your filters above and click Generate.", textAlign: TextAlign.center, style: TextStyle(color: isDark ? Colors.grey.shade400 : Colors.grey.shade600)),
          ),
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
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text("No Data Available", textAlign: TextAlign.center, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.grey.shade800)),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text("No results were found for the selected filters.", textAlign: TextAlign.center, style: TextStyle(color: isDark ? Colors.grey.shade400 : Colors.grey.shade600)),
          ),
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