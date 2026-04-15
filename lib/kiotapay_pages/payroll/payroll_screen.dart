import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../globalclass/chanzo_color.dart';
import '../../globalclass/kiotapay_constants.dart';
import '../../utils/dio_helper.dart';
import '../../widgets/error.dart';

class PayrollScreen extends StatefulWidget {
  const PayrollScreen({super.key});

  @override
  State<PayrollScreen> createState() => _PayrollScreenState();
}

class _PayrollScreenState extends State<PayrollScreen> {
  bool _isLoading = true;
  bool _hasError = false;

  List<dynamic> _payslips = [];
  Map<String, dynamic> _staffInfo = {};

  // Filters
  List<int> _availableYears = [];
  int? _selectedYear;
  int? _selectedMonth;

  final NumberFormat _currencyFormat = NumberFormat.currency(symbol: 'KES ', decimalDigits: 2);

  final List<Map<String, dynamic>> _months = [
    {'id': 1, 'name': 'January'}, {'id': 2, 'name': 'February'},
    {'id': 3, 'name': 'March'}, {'id': 4, 'name': 'April'},
    {'id': 5, 'name': 'May'}, {'id': 6, 'name': 'June'},
    {'id': 7, 'name': 'July'}, {'id': 8, 'name': 'August'},
    {'id': 9, 'name': 'September'}, {'id': 10, 'name': 'October'},
    {'id': 11, 'name': 'November'}, {'id': 12, 'name': 'December'},
  ];

  @override
  void initState() {
    super.initState();
    _fetchPayroll();
  }

  Future<void> _fetchPayroll() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    try {
      final Map<String, dynamic> queryParams = {};
      if (_selectedYear != null) queryParams['year'] = _selectedYear;
      if (_selectedMonth != null) queryParams['month'] = _selectedMonth;

      final response = await DioHelper().get(
        KiotaPayConstants.payroll,
        queryParameters: queryParams.isNotEmpty ? queryParams : null,
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        final filters = response.data['filters'] ?? {};

        setState(() {
          _staffInfo = response.data['staff'] ?? {};
          _payslips = response.data['data'] ?? [];

          // Parse available years from the filters response
          if (filters['years'] != null) {
            _availableYears = List<int>.from(filters['years']);
          }

          // If no year is selected yet, default to the one returned by the API
          _selectedYear ??= int.tryParse(filters['selected_year']?.toString() ?? '');

          _isLoading = false;
        });
      } else {
        setState(() => _hasError = true);
      }
    } catch (e) {
      setState(() => _hasError = true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _openPayslip(String? urlString) async {
    if (urlString == null || urlString.isEmpty) {
      Get.snackbar('Error', 'Payslip URL is not available.');
      return;
    }

    final Uri url = Uri.parse(urlString);
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      Get.snackbar('Error', 'Could not open the payslip.');
    }
  }

  Color _getStatusColor(String? status) {
    switch (status?.toLowerCase()) {
      case 'paid': return Colors.green;
      case 'approved': return Colors.blue;
      case 'pending': return Colors.orange;
      case 'draft': return Colors.grey;
      default: return ChanzoColors.primary;
    }
  }

  String _getMonthName(int monthNumber) {
    if (monthNumber < 1 || monthNumber > 12) return '';
    return _months.firstWhere((m) => m['id'] == monthNumber)['name'];
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text("My Payroll"),
        elevation: 0,
      ),
      body: Column(
        children: [
          // Header / Filter Section
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? Theme.of(context).cardColor : ChanzoColors.primary.withOpacity(0.05),
              border: Border(bottom: BorderSide(color: isDark ? Colors.grey.shade800 : Colors.grey.shade200)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_staffInfo.isNotEmpty) ...[
                  Text(
                    _staffInfo['name'] ?? '',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: isDark ? Colors.white : ChanzoColors.primary),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "Staff No: ${_staffInfo['staff_number']} • ${_staffInfo['branch_name']}",
                    style: TextStyle(fontSize: 13, color: isDark ? Colors.grey.shade400 : Colors.grey.shade700),
                  ),
                  const SizedBox(height: 16),
                ],
                Row(
                  children: [
                    Expanded(
                      child: _buildDropdown(
                          "Year",
                          _availableYears.map((y) => {'id': y, 'name': y.toString()}).toList(),
                          _selectedYear,
                              (val) {
                            setState(() => _selectedYear = val);
                            _fetchPayroll();
                          }
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildDropdown(
                          "Month (All)",
                          [{'id': null, 'name': 'All Months'}, ..._months],
                          _selectedMonth,
                              (val) {
                            setState(() => _selectedMonth = val);
                            _fetchPayroll();
                          }
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Payslips List Section
          Expanded(
            child: _isLoading
                ? _buildShimmerLoader(context)
                : _hasError
                ? ErrorWidgetUniversal(
              title: "Failed to load",
              description: "We couldn't fetch your payroll records.",
              onRetry: _fetchPayroll,
            )
                : RefreshIndicator(
              onRefresh: _fetchPayroll,
              color: ChanzoColors.primary,
              child: _payslips.isEmpty
                  ? _buildEmptyState(isDark)
                  : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _payslips.length,
                itemBuilder: (context, index) {
                  final payslip = _payslips[index];
                  return _buildPayslipCard(payslip, isDark);
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDropdown(String label, List<Map<String, dynamic>> items, int? value, Function(int?) onChanged) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return DropdownButtonFormField<int>(
      isExpanded: true,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: isDark ? Colors.grey.shade400 : Colors.grey.shade600),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: isDark ? Colors.grey.shade700 : Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: isDark ? Colors.grey.shade700 : Colors.grey.shade300),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        isDense: true,
      ),
      value: value,
      dropdownColor: isDark ? Colors.grey.shade900 : Colors.white,
      items: items.map<DropdownMenuItem<int>>((item) {
        return DropdownMenuItem<int>(
          value: item['id'],
          child: Text(item['name'].toString()),
        );
      }).toList(),
      onChanged: onChanged,
    );
  }

  Widget _buildPayslipCard(Map<String, dynamic> payslip, bool isDark) {
    final statusColor = _getStatusColor(payslip['status']);
    final monthName = _getMonthName(payslip['month']);
    final netSalary = double.tryParse(payslip['net_salary']?.toString() ?? '0') ?? 0.0;

    final bool hasDraft = payslip['draft_available'] == true;
    final bool hasFinal = payslip['final_available'] == true;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: isDark ? 0 : 2,
      color: isDark ? Theme.of(context).cardColor : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: isDark ? Colors.grey.shade800 : Colors.transparent),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Row: Month/Year and Status
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "$monthName ${payslip['year']}",
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: statusColor.withOpacity(0.5)),
                  ),
                  child: Text(
                    (payslip['status'] ?? 'Unknown').toString().toUpperCase(),
                    style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),

            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12.0),
              child: Divider(height: 1),
            ),

            // Middle Row: Salary Details
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Net Salary", style: TextStyle(color: isDark ? Colors.grey.shade400 : Colors.grey.shade600, fontSize: 12)),
                    const SizedBox(height: 4),
                    Text(
                      _currencyFormat.format(netSalary),
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                if (payslip['payment_method'] != null)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text("Method", style: TextStyle(color: isDark ? Colors.grey.shade400 : Colors.grey.shade600, fontSize: 12)),
                      const SizedBox(height: 4),
                      Text(
                        payslip['payment_method'].toString().capitalizeFirst ?? '',
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
              ],
            ),
            const SizedBox(height: 16),

            // Bottom Row: Action Buttons
            Row(
              children: [
                if (hasDraft)
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _openPayslip(payslip['draft_url']),
                      icon: const Icon(Icons.description_outlined, size: 18),
                      label: const Text("Draft"),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: isDark ? Colors.grey.shade300 : Colors.grey.shade800,
                        side: BorderSide(color: isDark ? Colors.grey.shade700 : Colors.grey.shade300),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ),
                if (hasDraft && hasFinal) const SizedBox(width: 12),
                if (hasFinal)
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _openPayslip(payslip['final_url']),
                      icon: const Icon(Icons.download, size: 18),
                      label: const Text("Final Payslip"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: ChanzoColors.primary,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ),
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: Container(
        height: MediaQuery.of(context).size.height * 0.5,
        alignment: Alignment.center,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.receipt_long_outlined, size: 64, color: isDark ? Colors.grey.shade700 : Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              "No Payslips Found",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.grey.shade800),
            ),
            const SizedBox(height: 8),
            Text(
              "There are no payroll records for the selected period.",
              style: TextStyle(color: isDark ? Colors.grey.shade400 : Colors.grey.shade600),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShimmerLoader(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color baseColor = isDark ? Colors.grey.shade800 : Colors.grey.shade300;
    final Color highlightColor = isDark ? Colors.grey.shade700 : Colors.grey.shade100;
    final Color containerColor = isDark ? Colors.grey.shade900 : Colors.white;

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 4,
      itemBuilder: (_, __) => Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: Shimmer.fromColors(
          baseColor: baseColor,
          highlightColor: highlightColor,
          child: Container(
            height: 160,
            decoration: BoxDecoration(color: containerColor, borderRadius: BorderRadius.circular(16)),
          ),
        ),
      ),
    );
  }
}