import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../../globalclass/chanzo_color.dart';
import '../../../globalclass/kiotapay_constants.dart';
import '../../../utils/dio_helper.dart';

class ShowSchemeOfWorkScreen extends StatefulWidget {
  final int schemeId;

  const ShowSchemeOfWorkScreen({super.key, required this.schemeId});

  @override
  State<ShowSchemeOfWorkScreen> createState() => _ShowSchemeOfWorkScreenState();
}

class _ShowSchemeOfWorkScreenState extends State<ShowSchemeOfWorkScreen> {
  bool _isLoading = true;
  Map<String, dynamic>? _scheme;

  @override
  void initState() {
    super.initState();
    _fetchScheme();
  }

  Future<void> _fetchScheme() async {
    try {
      final response = await DioHelper().get('${KiotaPayConstants.schemeOfWork}/${widget.schemeId}');

      if (response.statusCode == 200 && response.data['success'] == true) {
        setState(() {
          _scheme = response.data['data'];
        });
      } else {
        Get.snackbar('Error', response.data['message'] ?? 'Failed to load details.');
      }
    } catch (e) {
      Get.snackbar('Error', 'Failed to load details.');
    } finally {
      // FIX 1: Ensure loading always stops, even on silent failures
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null) return 'N/A';
    try {
      return DateFormat('MMM d, yyyy').format(DateTime.parse(dateStr));
    } catch (e) {
      return dateStr;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Record of Work Details")),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _scheme == null
          ? const Center(child: Text("Not found."))
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              elevation: 0,
              color: ChanzoColors.primary.withOpacity(0.05),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: ChanzoColors.primary.withOpacity(0.2))),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_scheme!['subject'] ?? 'Unknown', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: ChanzoColors.primary)),
                    const SizedBox(height: 12),

                    _buildMetaRow("Class", "${_scheme!['class']} (${_scheme!['stream']})"),
                    // FIX 3: Actually use the intl formatting
                    _buildMetaRow("Date", _formatDate(_scheme!['date'])),
                    _buildMetaRow("Week", _scheme!['week']?.toString() ?? 'N/A'),

                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      child: Divider(height: 1),
                    ),

                    // FIX 2: Added missing curriculum hierarchy details
                    _buildMetaRow("Strand", _scheme!['strand'] ?? 'N/A'),
                    _buildMetaRow("Sub-Strand", _scheme!['sub_strand'] ?? 'N/A'),
                    _buildMetaRow("Activity", _scheme!['activity'] ?? 'N/A'),

                    const SizedBox(height: 8),
                    _buildMetaRow("Status", (_scheme!['status'] ?? 'Draft').toString().toUpperCase(), isStatus: true),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            _buildSection("Work Covered", _scheme!['work_covered']),
            _buildSection("Remarks", _scheme!['remarks']),

            if (_scheme!['disapproval_description'] != null)
              _buildSection("Disapproval Reason", _scheme!['disapproval_description'], isAlert: true),
          ],
        ),
      ),
    );
  }

  Widget _buildMetaRow(String label, String value, {bool isStatus = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start, // Ensures long text wraps nicely
        children: [
          Text("$label: ", style: TextStyle(color: Colors.grey.shade700, fontWeight: FontWeight.w600)),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontWeight: isStatus ? FontWeight.bold : FontWeight.w500,
                color: isStatus
                    ? (value.toLowerCase() == 'approved' ? Colors.green : value.toLowerCase() == 'rejected' ? Colors.red : Colors.orange)
                    : Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(String title, String? content, {bool isAlert = false}) {
    if (content == null || content.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: isAlert ? Colors.red : ChanzoColors.primary)),
          const SizedBox(height: 6),
          Text(content, style: const TextStyle(fontSize: 14, height: 1.5)),
        ],
      ),
    );
  }
}