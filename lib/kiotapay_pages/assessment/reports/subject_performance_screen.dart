import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shimmer/shimmer.dart';

import '../../../globalclass/chanzo_color.dart';
import '../../../globalclass/kiotapay_constants.dart';
import '../../../utils/dio_helper.dart';
import '../../../widgets/error.dart';

class SubjectPerformanceScreen extends StatefulWidget {
  const SubjectPerformanceScreen({super.key});

  @override
  State<SubjectPerformanceScreen> createState() => _SubjectPerformanceScreenState();
}

class _SubjectPerformanceScreenState extends State<SubjectPerformanceScreen> {
  bool _isLoadingFilters = true;
  bool _isGenerating = false;
  bool _hasError = false;

  // Raw API Data
  List<dynamic> _academicSessions = [];
  List<dynamic> _classStreamsRaw = [];

  // Filtered Dropdown Lists
  List<dynamic> _availableTerms = [];
  List<dynamic> _availableClasses = [];
  List<dynamic> _availableStreams = [];
  List<dynamic> _availableSubjects = [];

  // Selections
  int? _selectedSessionId;
  int? _selectedTermId;
  int? _selectedClassId;
  int? _selectedStreamId;
  int? _selectedSubjectId;

  // Report Data (Grouped by Term)
  Map<String, dynamic> _reportData = {};
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
      final response = await DioHelper().get(KiotaPayConstants.reportSubjectPerformance);

      if (response.statusCode == 200 && response.data['success'] == true) {
        final data = response.data['data'];

        setState(() {
          _academicSessions = data['academicSessions'] ?? [];
          _classStreamsRaw = data['class_streams'] ?? [];

          _availableClasses = _getUniqueClasses();

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
    if (_selectedSessionId == null || _selectedClassId == null) {
      Get.snackbar('Required Fields', 'Please select a Session and Class to generate the report.', backgroundColor: Colors.orange, colorText: Colors.white);
      return;
    }

    setState(() => _isGenerating = true);

    try {
      final Map<String, dynamic> queryParams = {
        'academic_session_id': _selectedSessionId,
        'class_id': _selectedClassId,
      };
      if (_selectedTermId != null) queryParams['term_id'] = _selectedTermId;
      if (_selectedStreamId != null) queryParams['stream_id'] = _selectedStreamId;
      if (_selectedSubjectId != null) queryParams['subject_id'] = _selectedSubjectId;

      final response = await DioHelper().get(
        KiotaPayConstants.reportSubjectPerformance,
        queryParameters: queryParams,
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        setState(() {
          var rawReport = response.data['data']['report'];

          // Handle Laravel's JSON quirk: empty object {} vs empty array []
          if (rawReport is Map) {
            _reportData = Map<String, dynamic>.from(rawReport);
          } else {
            _reportData = {};
          }

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
    });
  }

  void _updateStreams(int classId) {
    setState(() {
      _availableStreams = _classStreamsRaw
          .where((cs) => cs['class_id'] == classId)
          .map((cs) => {'id': cs['stream_id'], 'name': cs['stream_name']})
          .toList();
      _selectedStreamId = null;
      _updateSubjects(classId, null); // Load all subjects for this class initially
    });
  }

  void _updateSubjects(int classId, int? streamId) {
    final Map<int, dynamic> uniqueSubjects = {};

    final matchingStreams = _classStreamsRaw.where((cs) {
      if (streamId != null) return cs['class_id'] == classId && cs['stream_id'] == streamId;
      return cs['class_id'] == classId;
    });

    for (var cs in matchingStreams) {
      final subjects = cs['subjects'] ?? [];
      for (var subject in subjects) {
        uniqueSubjects[subject['id']] = subject;
      }
    }

    setState(() {
      _availableSubjects = uniqueSubjects.values.toList();
      _selectedSubjectId = null;
    });
  }

  // --- UI BUILDERS ---

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Subject Performance"),
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
                child: _buildDropdown("Term (All)", [{'id': null, 'name': 'All Terms'}, ..._availableTerms.map((t) => {'id': t['id'], 'name': "Term ${t['term_number']}"})], _selectedTermId, (val) {
                  setState(() => _selectedTermId = val);
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
                  if (_selectedClassId != null) _updateSubjects(_selectedClassId!, val);
                }, isDark),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildDropdown("Subject (Optional)", [{'id': null, 'name': 'All Subjects'}, ..._availableSubjects], _selectedSubjectId, (val) {
            setState(() => _selectedSubjectId = val);
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
    return ListView(
      padding: const EdgeInsets.all(16),
      children: _reportData.entries.map((entry) {
        final termName = entry.key;
        final List<dynamic> subjectsData = entry.value;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12.0),
              child: Text(
                "Term $termName",
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: ChanzoColors.primary),
              ),
            ),
            ...subjectsData.map((subject) {
              final termMean = double.tryParse(subject['term_mean']?.toString() ?? '0') ?? 0.0;
              final Map<String, dynamic> exams = subject['exam_means'] ?? {};

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                elevation: isDark ? 0 : 1,
                color: isDark ? Theme.of(context).cardColor : Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: isDark ? Colors.grey.shade800 : Colors.grey.shade200),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  subject['subject_name'] ?? 'Unknown Subject',
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  "${subject['class_name']} • ${subject['stream_name']}",
                                  style: TextStyle(fontSize: 13, color: isDark ? Colors.grey.shade400 : Colors.grey.shade600),
                                ),
                              ],
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              const Text("Term Mean", style: TextStyle(fontSize: 11, color: Colors.grey)),
                              Text(
                                "${termMean.toStringAsFixed(1)}%",
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: termMean >= 50 ? Colors.green : (termMean > 0 ? Colors.red : Colors.grey),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      if (exams.isNotEmpty) ...[
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 8.0),
                          child: Divider(height: 1),
                        ),
                        // Wrap the specific exam means inside a nice pill layout
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: exams.entries.map((exam) {
                            return Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: isDark ? Colors.grey.shade800 : Colors.grey.shade100,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                "${exam.key}: ${double.tryParse(exam.value.toString())?.toStringAsFixed(1) ?? '0'}%",
                                style: TextStyle(fontSize: 12, color: isDark ? Colors.white70 : Colors.black87),
                              ),
                            );
                          }).toList(),
                        )
                      ]
                    ],
                  ),
                ),
              );
            }).toList(),
          ],
        );
      }).toList(),
    );
  }

  Widget _buildInitialState(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.auto_graph, size: 64, color: isDark ? Colors.grey.shade700 : Colors.grey.shade400),
          const SizedBox(height: 16),
          Text("Subject Performance", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.grey.shade800)),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text("Select your filters above and click Generate.", style: TextStyle(color: isDark ? Colors.grey.shade400 : Colors.grey.shade600), textAlign: TextAlign.center,),
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
          Text("No Data Available", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.grey.shade800)),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text("No results were found for the selected filters.", style: TextStyle(color: isDark ? Colors.grey.shade400 : Colors.grey.shade600), textAlign: TextAlign.center),
          ),
        ],
      ),
    );
  }

  Widget _buildShimmerLoader(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 4,
      itemBuilder: (_, __) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Shimmer.fromColors(
          baseColor: isDark ? Colors.grey.shade800 : Colors.grey.shade300,
          highlightColor: isDark ? Colors.grey.shade700 : Colors.grey.shade100,
          child: Container(height: 100, decoration: BoxDecoration(color: isDark ? Colors.grey.shade900 : Colors.white, borderRadius: BorderRadius.circular(12))),
        ),
      ),
    );
  }
}