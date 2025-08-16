import 'dart:convert';
import 'dart:io';
import 'package:bootstrap_icons/bootstrap_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:nb_utils/nb_utils.dart';
import '../../globalclass/chanzo_color.dart';
import '../../globalclass/kiotapay_constants.dart';
import '../../globalclass/kiotapay_icons.dart';
import '../../utils/pdf_viewer_screen.dart';
import '../kiotapay_authentication/AuthController.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';
import '/models/fee_structure_model.dart';
import 'package:http/http.dart' as http;

class FeeStructureScreen extends StatefulWidget {
  const FeeStructureScreen({Key? key}) : super(key: key);

  @override
  _FeeStructureScreenState createState() => _FeeStructureScreenState();
}

class _FeeStructureScreenState extends State<FeeStructureScreen> {
  late Future<FeeStructureResponse> _feeStructureFuture;
  final storage = const FlutterSecureStorage();
  final authController = Get.put(AuthController());
  String? _selectedSessionId;
  String? _selectedTermId;
  FeeStructureResponse? _feeStructure;
  bool _showDetailedView = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _feeStructureFuture = _loadInitialData();
  }

  Future<FeeStructureResponse> _loadInitialData() async {
    setState(() => _isLoading = true);
    try {
      final data = await getStudentFee();
      setState(() {
        _feeStructure = data;
        _selectedSessionId = data.data.selectedSessionId ??
            data.data.activeSession.id.toString();
        _selectedTermId = data.data.selectedTermId ??
            data.data.activeTerm.id.toString();
      });
      return data;
      print(data);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<FeeStructureResponse> getStudentFee({
    String? academicSessionId,
    String? termId
  }) async {
    final token = await storage.read(key: 'token');
    if (token == null) {
      throw Exception('No authentication token found');
    }

    final params = <String, String>{};
    if (academicSessionId != null && academicSessionId != 'all') {
      params['academic_session_id'] = academicSessionId;
    }

    if (academicSessionId != null && academicSessionId == 'all') {
      params['academic_session_id'] = '';
      params['term_id'] = '';
    }

    if (termId != null && termId != 'all') {
      params['term_id'] = termId;
    }

    if (termId == null) {
      params['term_id'] = '';
    }else{
      params['term_id'] = termId;
    }

    int student_id = authController.selectedStudent['id'];
    final uri = Uri.parse('${KiotaPayConstants.getStudentFee}/$student_id').replace(
      queryParameters: params.isNotEmpty ? params : null,
    );

    print("URL ${uri}");
    final response = await http.get(
      uri,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final data = FeeStructureResponse.fromJson(json.decode(response.body));

      // Debug print to verify the response data
      print('API Response: ${json.encode(data.data.fees.map((f) => f.session).toList())}');
      print('Selected Session ID: $_selectedSessionId');
      print('Selected Term ID: $_selectedTermId');

      return data;
    } else {
      throw Exception('Failed to load fee structure: ${response.statusCode}');
    }
  }

  Future<void> _refreshData() async {
    setState(() {
      _feeStructureFuture = getStudentFee(
        academicSessionId: _selectedSessionId,
        termId: _selectedTermId,
      );
    });
  }

  Future<void> downloadFeeStructurePdf2({
    required int studentId,
    String? academicSessionId,
    String? termId,
  }) async {
    final token = await storage.read(key: 'token');
    if (token == null) throw Exception('No authentication token found');

    try {
      // Show loading indicator
      EasyLoading.show(status: 'Generating PDF...');

      // Prepare parameters
      final params = <String, String>{};

      if (academicSessionId != null && academicSessionId != 'all') {
        params['academic_session_id'] = academicSessionId;
      }

      if (termId != null && termId != 'all') {
        params['term_id'] = termId;
      }

      // For "All Sessions" case
      if (academicSessionId == 'all') {
        params['academic_session_id'] = '';
        params['term_id'] = '';
      }

      final uri = Uri.parse('${KiotaPayConstants.getStudentFeePdf}/$studentId').replace(
        queryParameters: params.isNotEmpty ? params : null,
      );

      final response = await http.get(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/pdf',
        },
      );

      if (response.statusCode == 200) {
        // Get downloads directory (works better for PDF viewing)
        final directory = await getDownloadsDirectory() ?? await getApplicationDocumentsDirectory();
        final filename = 'FEE_STRUCTURE_${studentId.toString().padLeft(4, '0')}_${DateFormat('dd-MM-yyyy-Hms').format(DateTime.now())}.pdf';
        final file = File('${directory.path}/$filename');

        // Save the file
        await file.writeAsBytes(response.bodyBytes, flush: true);

        // Open the file with platform-specific viewer
        final result = await OpenFile.open(file.path);

        if (result.type != ResultType.done) {
          throw Exception('Could not open PDF. You can find it at: ${file.path}');
        }
      } else {
        throw Exception('Server responded with ${response.statusCode}');
      }
    } catch (e) {
      EasyLoading.showError('Download failed: ${e.toString()}');
      rethrow;
    } finally {
      EasyLoading.dismiss();
    }
  }

  Future<void> saveAndOpenPdf(List<int> bytes, String filename) async {
    // Get directory
    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/$filename');

    // Save file
    await file.writeAsBytes(bytes, flush: true);

    // Open file
    final result = await OpenFile.open(file.path);

    if (result.type != ResultType.done) {
      throw Exception('Could not open PDF file');
    }
  }

  Future<void> downloadFeeStructurePdf({
    required int studentId,
    String? academicSessionId,
    String? termId,
  }) async {
    final token = await storage.read(key: 'token');
    if (token == null) throw Exception('No authentication token found');

    try {
      EasyLoading.show(status: 'Generating PDF...');

      final params = <String, String>{};

      if (academicSessionId != null && academicSessionId != 'all') {
        params['academic_session_id'] = academicSessionId;
      }

      if (termId != null && termId != 'all') {
        params['term_id'] = termId;
      }

      if (academicSessionId == 'all') {
        params['academic_session_id'] = '';
        params['term_id'] = '';
      }

      final uri = Uri.parse('${KiotaPayConstants.getStudentFeePdf}/$studentId').replace(
        queryParameters: params.isNotEmpty ? params : null,
      );

      final response = await http.get(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/pdf',
        },
      );

      if (response.statusCode == 200) {
        final directory = await getTemporaryDirectory();
        final filename = 'FEE_STRUCTURE_${studentId.toString().padLeft(4, '0')}_${DateFormat('dd-MM-yyyy-Hms').format(DateTime.now())}.pdf';
        final file = File('${directory.path}/$filename');

        await file.writeAsBytes(response.bodyBytes, flush: true);

        // Open PDF in custom viewer
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => PdfViewerScreen(filePath: file.path, title: "Fee Structure",),
          ),
        );
      } else {
        throw Exception('Server responded with ${response.statusCode}');
      }
    } catch (e) {
      EasyLoading.showError('Download failed: ${e.toString()}');
      rethrow;
    } finally {
      EasyLoading.dismiss();
    }
  }

  @override
  Widget build(BuildContext context) {
    print('Current selectedSessionId: $_selectedSessionId');
    print('Current feeStructure sessions: ${_feeStructure?.data.fees.map((f) => f.session).toList()}');
    return Scaffold(
      appBar: AppBar(
        title: const Text('Fee Structure'),
        actions: [
          IconButton(
            icon: const Icon(BootstrapIcons.download),
            onPressed: () async {
              try {
                await downloadFeeStructurePdf(
                  studentId: authController.selectedStudent['id'], // Pass the student ID
                  academicSessionId: _selectedSessionId,
                  termId: _selectedTermId,
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Failed to download: $e')),
                );
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshData,
          ),
          // IconButton(
          //   icon: Icon(_showDetailedView ? Icons.list : Icons.grid_view),
          //   onPressed: () =>
          //       setState(() => _showDetailedView = !_showDetailedView),
          // ),
        ],
      ),
      body: FutureBuilder<FeeStructureResponse>(
        future: _feeStructureFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting &&
              !_isLoading) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Failed to load fee structure'),
                  Text(snapshot.error.toString(),
                      style: const TextStyle(color: Colors.red)),
                  ElevatedButton(
                    onPressed: _refreshData,
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          } else if (snapshot.hasData && _feeStructure != null) {
            return _buildContent(_feeStructure!);
          } else {
            return const Center(child: Text('No data available'));
          }
        },
      ),
    );
  }

  Widget _buildContent(FeeStructureResponse feeStructure) {
    // Debug print to verify all sessions are present
    print('Available sessions in data: ${feeStructure.data.fees.map((f) => f.session).toList()}');

    return RefreshIndicator(
      onRefresh: _refreshData,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildStudentInfo(feeStructure.data.student,
                feeStructure.data.activeSession,
                feeStructure.data.activeTerm),
            const SizedBox(height: 20),
            _buildSessionTermSelector(feeStructure),
            // const SizedBox(height: 20),
            // if (feeStructure.data.unallocatedPayments > 0) ...[
            //   _buildUnallocatedPayments(feeStructure.data.unallocatedPayments),
            //   const SizedBox(height: 20),
            // ],
            // Force rebuild of the content when selection changes
            _selectedSessionId == null || _selectedSessionId == 'all'
                ? _buildAllSessionsView(feeStructure)
                : _buildSessionDetailsView(feeStructure),
          ],
        ),
      ),
    );
  }

  Widget _buildStudentInfo(Student student, AcademicSession activeSession,
      Term activeTerm) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            CircleAvatar(
              radius: 30,
              backgroundColor: ChanzoColors.textgrey,
              child: CachedNetworkImage(
                imageUrl: student.photoPath != null
                    ? '${KiotaPayConstants.webUrl}storage/${student.photoPath}'
                    : '',
                imageBuilder: (context, imageProvider) =>
                    Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        image: DecorationImage(
                          image: imageProvider,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                placeholder: (context, url) =>
                    CircleAvatar(
                      backgroundColor: ChanzoColors.textgrey,
                      radius: 30,
                      backgroundImage: AssetImage(KiotaPayPngimage.profile),
                    ),
                errorWidget: (context, url, error) =>
                    CircleAvatar(
                      backgroundColor: ChanzoColors.textgrey,
                      radius: 30,
                      backgroundImage: AssetImage(KiotaPayPngimage.profile),
                    ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Admission No: ${student.admissionNo}',
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  Text('Gender: ${student.gender}'),
                  Text('Type: ${student.type}'),
                  Text('Current: Term ${activeTerm.termNumber} ${activeSession
                      .year}'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSessionTermSelector(FeeStructureResponse feeStructure) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Select Academic Session & Term',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Stack(
              children: [
                DropdownButtonFormField<String>(
                  value: _selectedSessionId,
                  decoration: const InputDecoration(
                    labelText: 'Academic Session',
                    border: OutlineInputBorder(),
                  ),
                  items: [
                    // Add "All Sessions" option
                    const DropdownMenuItem<String>(
                      value: 'all',
                      child: Text('All Sessions'),
                    ),
                    ...feeStructure.data.academicSessions.map((session) {
                      return DropdownMenuItem<String>(
                        value: session.id.toString(),
                        child: Text(
                          '${session.year} (${session.status})',
                          style: session.id.toString() ==
                              feeStructure.data.activeSession.id.toString()
                              ? TextStyle(
                              fontWeight: FontWeight.bold, color: Colors.blue)
                              : null,
                        ),
                      );
                    }).toList(),
                  ],
                  onChanged: (value) async {
                    setState(() {
                      _selectedSessionId = value;
                      _selectedTermId = null; // Reset term selection
                      _isLoading = true;
                    });

                    try {
                      _feeStructureFuture = getStudentFee(academicSessionId: value);
                      final updatedData = await _feeStructureFuture;

                      setState(() {
                        _feeStructure = updatedData;
                        // Ensure we're showing the correct session's data
                        if (value != 'all' && value != null) {
                          _selectedSessionId = value;
                        }
                      });
                    } finally {
                      setState(() => _isLoading = false);
                    }
                  },
                ),
                if (_isLoading)
                  Positioned.fill(
                    child: Container(
                      color: Colors.black.withOpacity(0.1),
                      child: const Center(
                        child: CircularProgressIndicator(),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 10),
            if (_selectedSessionId != null && _selectedSessionId != 'all')
              Stack(
                children: [
                  DropdownButtonFormField<String>(
                    value: _selectedTermId,
                    decoration: const InputDecoration(
                      labelText: 'Term',
                      border: OutlineInputBorder(),
                    ),
                    items: [
                      // Add "All Terms" option
                      const DropdownMenuItem<String>(
                        value: 'all',
                        child: Text('All Terms'),
                      ),
                      ...feeStructure.data.academicSessions
                          .firstWhere((session) =>
                      session.id.toString() == _selectedSessionId)
                          .terms
                          .map((term) {
                        return DropdownMenuItem<String>(
                          value: term.id.toString(),
                          child: Text(
                            'Term ${term.termNumber} (${term.status})',
                            style: term.id.toString() ==
                                feeStructure.data.activeTerm.id.toString()
                                ? TextStyle(
                                fontWeight: FontWeight.bold, color: Colors.blue)
                                : null,
                          ),
                        );
                      }).toList(),
                    ],
                    onChanged: (value) async {
                      setState(() {
                        _selectedTermId = value;
                        _isLoading = true;
                      });

                      try {
                        _feeStructureFuture = value == 'all'
                            ? getStudentFee(academicSessionId: _selectedSessionId)
                            : getStudentFee(
                          academicSessionId: _selectedSessionId,
                          termId: value,
                        );

                        final updatedData = await _feeStructureFuture;

                        setState(() {
                          _feeStructure = updatedData;
                        });
                      } finally {
                        setState(() => _isLoading = false);
                      }
                    },
                  ),
                  if (_isLoading)
                    Positioned.fill(
                      child: Container(
                        color: Colors.black.withOpacity(0.1),
                        child: const Center(
                          child: CircularProgressIndicator(),
                        ),
                      ),
                    ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildUnallocatedPayments(double amount) {
    return Card(
      color: Colors.blue[50],
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Unallocated Payments:',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            Text(
              'KSh ${amount.toStringAsFixed(2)}',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAllSessionsView(FeeStructureResponse feeStructure) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      children: feeStructure.data.fees.map((session) {
        return Card(
          margin: const EdgeInsets.only(bottom: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Session Header
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16.0),
                color: colorScheme.primary,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Academic Session ${session.session}',
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: colorScheme.onPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${_formatDate(session.startDate)} - ${_formatDate(session.endDate)}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onPrimary,
                      ),
                    ),
                  ],
                ),
              ),

              // Terms List
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    ...session.terms.values.map((term) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Term Header
                          Padding(
                            padding: const EdgeInsets.only(bottom: 8.0),
                            child: Text(
                              'Term ${term.termNumber} (${_formatDate(term.startDate)} - ${_formatDate(term.endDate)})',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),

                          // Fee Categories Table
                          if (term.fees.isNotEmpty)
                            Table(
                              columnWidths: const {
                                0: FlexColumnWidth(2),
                                1: FlexColumnWidth(1),
                              },
                              border: TableBorder.symmetric(
                                inside: BorderSide(
                                    color: colorScheme.outlineVariant
                                        .withOpacity(0.5)),
                                outside: BorderSide(
                                    color: colorScheme.outlineVariant
                                        .withOpacity(0.5)),
                              ),
                              children: [
                                // Table Header
                                TableRow(
                                  decoration:
                                  BoxDecoration(color: colorScheme.surfaceVariant),
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: Text(
                                        'Fee Category',
                                        style: theme.textTheme.bodyMedium?.copyWith(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: Text(
                                        'Amount (KES)',
                                        textAlign: TextAlign.end,
                                        style: theme.textTheme.bodyMedium?.copyWith(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),

                                // Fee Items
                                ...term.fees.map(
                                      (fee) => TableRow(
                                    children: [
                                      Padding(
                                        padding: const EdgeInsets.all(8.0),
                                        child: Column(
                                          crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                          children: [
                                            Text(fee.feeCategory.name),
                                            if (fee.feeCategory.description != null)
                                              Text(
                                                fee.feeCategory.description!,
                                                style: theme.textTheme.bodySmall
                                                    ?.copyWith(
                                                    color: colorScheme
                                                        .onSurfaceVariant),
                                              ),
                                          ],
                                        ),
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.all(8.0),
                                        child: Column(
                                          crossAxisAlignment:
                                          CrossAxisAlignment.end,
                                          children: [
                                            if (fee.discountAmount > 0)
                                              Text(
                                                '-${fee.discountAmount.toStringAsFixed(2)}',
                                                style: TextStyle(
                                                  color: Colors.green.shade700,
                                                  fontSize: 12,
                                                ),
                                              ),
                                            Text(
                                              fee.netAmount.toStringAsFixed(2),
                                              style: const TextStyle(
                                                  fontWeight: FontWeight.bold),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),

                          // Term Summary
                          const SizedBox(height: 12),
                          Table(
                            columnWidths: const {
                              0: FlexColumnWidth(2),
                              1: FlexColumnWidth(1),
                            },
                            border: TableBorder.symmetric(
                              inside: BorderSide(
                                  color: colorScheme.outlineVariant.withOpacity(0.5)),
                              outside: BorderSide(
                                  color: colorScheme.outlineVariant.withOpacity(0.5)),
                            ),
                            children: [
                              _buildSummaryRow('Opening Balance', term.openingBalance),
                              _buildSummaryRow('Term Total', term.totalFeesBeforeDiscount),
                              _buildSummaryRow(
                                'Term Discount',
                                (term.totalFeesBeforeDiscount - term.totalFees),
                              ),
                              _buildSummaryRow('Term Payments', term.totalPayments),
                              _buildSummaryRow(
                                'Closing Balance',
                                term.closingBalance,
                                highlight: true,
                                isNegative: term.closingBalance < 0,
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                        ],
                      );
                    }).toList(),

                    // Session Summary (ONE COLUMN)
                    const Padding(
                      padding: EdgeInsets.only(bottom: 8.0),
                      child: Text(
                        'Session Summary',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Table(
                      columnWidths: const {
                        0: FlexColumnWidth(2),
                        1: FlexColumnWidth(1),
                      },
                      border: TableBorder.symmetric(
                        inside: BorderSide(
                            color: colorScheme.outlineVariant.withOpacity(0.5)),
                        outside: BorderSide(
                            color: colorScheme.outlineVariant.withOpacity(0.5)),
                      ),
                      children: [
                        _buildSummaryRow('Opening Balance', session.openingBalance),
                        _buildSummaryRow('Total Fees', session.sessionTotalFees),
                        _buildSummaryRow('Total Payments', session.sessionTotalPayments),
                        _buildSummaryRow(
                          'Closing Balance',
                          session.sessionBalance,
                          highlight: true,
                          isNegative: session.sessionBalance < 0,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }


  // Helper method for date formatting
  String _formatDate(DateTime date) {
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  String _getMonthName(int month) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return months[month - 1];
  }

  Widget _buildFeeSummary(FeeStructureResponse feeStructure) {
    // Find the selected session or use the last one if "All Sessions" is selected
    FeeSession displaySession;

    if (_selectedSessionId == null || _selectedSessionId == 'all') {
      // When showing all sessions, default to the most recent session
      displaySession = feeStructure.data.fees.last;
    } else {
      // Find the specifically selected session
      displaySession = feeStructure.data.fees.firstWhere(
            (fee) => fee.session.toString() == _selectedSessionId,
        orElse: () => feeStructure.data.fees.last, // Fallback to last session if not found
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Fee Summary for ${displaySession.session}',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            _buildSummaryItem('Opening Balance', 'KSh ${displaySession.openingBalance.toStringAsFixed(2)}'),
            _buildSummaryItem('Total Fees', 'KSh ${displaySession.sessionTotalFees.toStringAsFixed(2)}'),
            _buildSummaryItem('Total Payments', 'KSh ${displaySession.sessionTotalPayments.toStringAsFixed(2)}'),
            _buildSummaryItem(
              'Balance',
              'KSh ${displaySession.sessionBalance.toStringAsFixed(2)}',
              isBalance: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryItem(String label, String value,
      {bool isBalance = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: isBalance
                  ? (double.parse(value.replaceAll(RegExp(r'[^0-9.]'), '')) < 0
                  ? Colors.green // Negative balance (overpayment) in green
                  : Colors.red) // Positive balance in red
                  : null,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeeDetails(FeeStructureResponse feeStructure) {
    if (_selectedSessionId == 'all') {
      return _buildAllSessionsView(feeStructure);
    }

    final selectedSession = feeStructure.data.fees.firstWhere(
          (fee) => fee.session.toString() == _selectedSessionId,
      orElse: () => feeStructure.data.fees.first,
    );

    if (_selectedTermId == 'all') {
      return Column(
        children: selectedSession.terms.values.map((term) {
          return Card(
            margin: const EdgeInsets.only(bottom: 16.0),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Term ${term.termNumber}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _buildTermSummary(term),
                  const SizedBox(height: 12),
                  if (term.fees.isNotEmpty) ...[
                    const Text(
                      'Fee Categories:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    ...term.fees.map((fee) => _buildFeeItemCard(fee)).toList(),
                  ] else
                    const Center(child: Text('No fees for this term')),
                ],
              ),
            ),
          );
        }).toList(),
      );
    }

    final selectedTerm = selectedSession.terms[_selectedTermId];
    if (selectedTerm == null) return const SizedBox.shrink();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Term ${selectedTerm.termNumber} Fee Details',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            if (selectedTerm.fees.isEmpty)
              const Center(child: Text('No fees for this term')),
            ...selectedTerm.fees.map((fee) => _buildFeeItemCard(fee)).toList(),
            const SizedBox(height: 10),
            _buildTermSummary(selectedTerm),
          ],
        ),
      ),
    );
  }

  Widget _buildFeeItemCard(FeeItem fee) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              fee.feeCategory.name,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 5),
            Text(fee.feeCategory.description),
            const SizedBox(height: 10),
            // _buildFeeDetailRow('Amount', 'KSh ${fee.amount}'),
            if (fee.discountAmount > 0)
              _buildFeeDetailRow(
                  'Discount', '-KSh ${fee.discountAmount.toStringAsFixed(2)}'),
            _buildFeeDetailRow(
              'Net Amount',
              'KSh ${fee.netAmount.toStringAsFixed(2)}',
              isTotal: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeeDetailRow(String label, String value,
      {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(
            value,
            style: isTotal
                ? const TextStyle(fontWeight: FontWeight.bold)
                : null,
          ),
        ],
      ),
    );
  }

  Widget _buildTermSummary(TermFee term) {
    return Container(
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: Column(
        children: [
          _buildTermSummaryRow('Opening Balance', term.openingBalance),
          _buildTermSummaryRow('Total Fees', term.totalFees),
          _buildTermSummaryRow('Total Payments', term.totalPayments),
          _buildTermSummaryRow(
            'Closing Balance',
            term.closingBalance,
            isBalance: true,
          ),
        ],
      ),
    );
  }

  Widget _buildTermSummaryRow(String label, double value,
      {bool isBalance = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          Text(
            'KSh ${value.toStringAsFixed(2)}',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: isBalance
                  ? (value < 0
                  ? Colors.green
                  .shade800 // Negative balance (overpayment) in green
                  : Colors.red.shade900) // Positive balance in red
                  : null,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSessionDetailsView(FeeStructureResponse feeStructure) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final session = feeStructure.data.fees.firstWhere(
          (f) => f.session.toString() == _selectedSessionId,
      orElse: () => feeStructure.data.fees.last,
    );

    return Column(
      children: [
        Card(
          elevation: 3,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Session Header
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  color: colorScheme.primary,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Academic Session ${session.session}',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${_formatDate(session.startDate)} - ${_formatDate(session.endDate)}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onPrimary,
                      ),
                    ),
                  ],
                ),
              ),

              // Terms + Fees
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    ...session.terms.values.map((term) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Term Header
                          Padding(
                            padding: const EdgeInsets.only(bottom: 8.0, top: 12.0),
                            child: Text(
                              'Term ${term.termNumber} (${_formatDate(term.startDate)} - ${_formatDate(term.endDate)})',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: colorScheme.primary,
                              ),
                            ),
                          ),

                          // Fee Categories Table
                          if (term.fees.isNotEmpty)
                            Table(
                              columnWidths: const {0: FlexColumnWidth(2), 1: FlexColumnWidth(1.5)},
                              border: TableBorder.symmetric(
                                inside: BorderSide(color: colorScheme.outlineVariant.withOpacity(0.3)),
                                outside: BorderSide(color: colorScheme.outlineVariant.withOpacity(0.3)),
                              ),
                              children: [
                                TableRow(
                                  decoration: BoxDecoration(color: colorScheme.surfaceVariant),
                                  children: [
                                    _buildHeaderCell('Fee Category', colorScheme.onSurface),
                                    _buildHeaderCell('Amount (KES)', colorScheme.onSurface, alignEnd: true),
                                  ],
                                ),
                                ...term.fees.map((fee) => TableRow(
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(fee.feeCategory.name,
                                              style: theme.textTheme.bodySmall?.copyWith(fontSize: 16)),
                                          if (fee.feeCategory.description != null)
                                            Text(
                                              fee.feeCategory.description!,
                                              style: theme.textTheme.bodySmall?.copyWith(
                                                color: colorScheme.onSurfaceVariant,
                                                fontSize: 11,
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.end,
                                        children: [
                                          if (fee.discountAmount > 0)
                                            Text(
                                              '-${fee.discountAmount.toStringAsFixed(2)}',
                                              style: theme.textTheme.bodySmall?.copyWith(
                                                color: Colors.green,fontSize: 11
                                              ),
                                            ),
                                          Text(
                                            fee.netAmount.toStringAsFixed(2),
                                            style: theme.textTheme.bodySmall?.copyWith(
                                              fontWeight: FontWeight.bold, fontSize: 16
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                )),
                              ],
                            ),

                          // Term Summary (single column)
                          const SizedBox(height: 12),
                          Table(
                            columnWidths: const {0: FlexColumnWidth(2), 1: FlexColumnWidth(1)},
                            border: TableBorder.symmetric(
                              inside: BorderSide(color: colorScheme.outlineVariant.withOpacity(0.3)),
                              outside: BorderSide(color: colorScheme.outlineVariant.withOpacity(0.3)),
                            ),
                            children: [
                              _buildSummaryRow('Opening Balance', term.openingBalance),
                              _buildSummaryRow('Term Total', term.totalFeesBeforeDiscount),
                              _buildSummaryRow(
                                'Term Discount',
                                (term.totalFeesBeforeDiscount - term.totalFees),
                              ),
                              _buildSummaryRow('Term Payments', term.totalPayments),
                              _buildSummaryRow(
                                'Closing Balance',
                                term.closingBalance,
                                highlight: true,
                                isNegative: term.closingBalance < 0,
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                        ],
                      );
                    }),

                    // Session Summary (single column)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8.0),
                      child: Text(
                        'Session Summary',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: colorScheme.primary,
                        ),
                      ),
                    ),
                    Table(
                      columnWidths: const {0: FlexColumnWidth(2), 1: FlexColumnWidth(1.5)},
                      border: TableBorder.symmetric(
                        inside: BorderSide(color: colorScheme.outlineVariant.withOpacity(0.3)),
                        outside: BorderSide(color: colorScheme.outlineVariant.withOpacity(0.3)),
                      ),
                      children: [
                        _buildSummaryRow('Opening Balance', session.openingBalance),
                        _buildSummaryRow('Total Fees', session.sessionTotalFees),
                        _buildSummaryRow('Total Payments', session.sessionTotalPayments),
                        _buildSummaryRow(
                          'Closing Balance',
                          session.sessionBalance,
                          highlight: true,
                          isNegative: session.sessionBalance < 0,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHeaderCell(String text, Color color, {bool alignEnd = false}) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Text(
        text,
        style: TextStyle(fontWeight: FontWeight.bold, color: color, fontSize: 16),
        textAlign: alignEnd ? TextAlign.end : TextAlign.start,
      ),
    );
  }

  TableRow _buildSummaryRow(
      String label,
      double value, {
        bool highlight = false,
        bool isNegative = false,
      }) {
    return TableRow(
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text(label,
            style: TextStyle(
              fontWeight: highlight ? FontWeight.bold : FontWeight.normal, fontSize: 16,
              color: highlight
                  ? (isNegative ? Colors.green : Colors.red)
                  : null,
            ),),
        ),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text(
            value.toStringAsFixed(0), // just the number
            textAlign: TextAlign.end,
            style: TextStyle(
              fontWeight: highlight ? FontWeight.bold : FontWeight.normal, fontSize: 16,
              color: highlight
                  ? (isNegative ? Colors.green : Colors.red)
                  : null,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildValueCell(double value, {bool highlight = false, bool isNegative = false}) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Text(
        'KES ${value.toStringAsFixed(2)}',
        textAlign: TextAlign.end,
        style: TextStyle(
          fontWeight: highlight ? FontWeight.bold : FontWeight.normal,
          color: highlight
              ? (isNegative ? Colors.green : Colors.red)
              : null,
        ),
      ),
    );
  }

}