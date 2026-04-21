import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../globalclass/chanzo_color.dart';
import '../../../globalclass/kiotapay_constants.dart';
import '../../../utils/dio_helper.dart';
import '../../../widgets/error.dart';
import 'summative_results_screen.dart';

class ExamPapersScreen extends StatefulWidget {
  final int examId;
  final String? examName;

  const ExamPapersScreen({super.key, required this.examId, this.examName});

  @override
  State<ExamPapersScreen> createState() => _ExamPapersScreenState();
}

class _ExamPapersScreenState extends State<ExamPapersScreen> {
  bool _isLoading = true;
  bool _hasError = false;
  List<dynamic> _papers = [];

  @override
  void initState() {
    super.initState();
    _fetchPapers();
  }

  Future<void> _fetchPapers() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    try {
      final response = await DioHelper().get(KiotaPayConstants.examPapers(widget.examId));

      if (response.statusCode == 200 && response.data['success'] == true) {
        setState(() {
          // Note: Based on your JSON, papers might come back empty or populated.
          _papers = response.data['data']['papers'] ?? [];
          _isLoading = false;
        });
      } else {
        setState(() => _hasError = true);
      }
    } catch (e) {
      setState(() => _hasError = true);
    } finally {
      if (mounted && _isLoading) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.examName ?? "Exam Papers"),
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _hasError
          ? ErrorWidgetUniversal(title: "Error", description: "Failed to load papers.", onRetry: _fetchPapers)
          : _papers.isEmpty
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.folder_off_outlined, size: 64, color: isDark ? Colors.grey.shade700 : Colors.grey.shade400),
            const SizedBox(height: 16),
            const Text("No Papers Found", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text("There are no papers configured for this exam yet.", textAlign: TextAlign.center),
          ],
        ),
      )
          : ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _papers.length,
        itemBuilder: (context, index) {
          final paper = _papers[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            elevation: isDark ? 0 : 1,
            color: isDark ? Theme.of(context).cardColor : Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: isDark ? Colors.grey.shade800 : Colors.grey.shade200),
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.all(16),
              title: Text(paper['name'] ?? 'Unknown Paper', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              subtitle: Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  alignment: WrapAlignment.spaceBetween,
                  children: [
                    _buildBadge(paper['class'] ?? 'Class', isDark),
                    _buildBadge(paper['subject'] ?? 'Subject', isDark),
                    Text(
                      "Max: ${paper['max_marks'] ?? 100}",
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: ChanzoColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
              trailing: const Icon(Icons.edit_document, color: ChanzoColors.secondary),
              onTap: () {
                // Navigate to the final Grading Screen!
                Get.to(() => SummativeResultsScreen(
                  examId: widget.examId,
                  paperId: paper['id'],
                ));
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildBadge(String text, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(text, style: TextStyle(fontSize: 12, color: isDark ? Colors.white70 : Colors.black87)),
    );
  }
}