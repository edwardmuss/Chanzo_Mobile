import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:kiotapay/globalclass/chanzo_color.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:path_provider/path_provider.dart';

import '../../globalclass/global_methods.dart';
import '../../globalclass/kiotapay_constants.dart';
import '../../models/payment_model.dart';
import '../../utils/pdf_viewer_screen.dart';
import 'package:http/http.dart' as http;

class PaymentDetailsScreen extends StatelessWidget {
  final Payment payment;
  final bool isOnline;

  const PaymentDetailsScreen({
    Key? key,
    required this.payment,
    required this.isOnline,
  }) : super(key: key);

  Future<void> downloadFeeReceiptPdf({
    required int paymentId,
  }) async {
    final token = await storage.read(key: 'token');
    if (token == null) throw Exception('No authentication token found');

    try {
      EasyLoading.show(status: 'Generating PDF...');

      final params = <String, String>{};

      final uri = Uri.parse('${KiotaPayConstants.getStudentFeeReceiptPdf}/$paymentId');

      final response = await http.get(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/pdf',
        },
      );

      if (response.statusCode == 200) {
        final directory = await getTemporaryDirectory();
        final filename = 'FEE_RECEIPT_${paymentId.toString().padLeft(4, '0')}_${DateFormat('dd-MM-yyyy-Hms').format(DateTime.now())}.pdf';
        final file = File('${directory.path}/$filename');

        await file.writeAsBytes(response.bodyBytes, flush: true);

        // Open PDF in custom viewer
        Navigator.of(Get.context!).push(
          MaterialPageRoute(
            builder: (context) => PdfViewerScreen(filePath: file.path, title: "Fee Receipt",),
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
    final theme = Theme.of(context);
    final currencyFormat = NumberFormat.currency(locale: 'en_US', symbol: 'KES');
    final dateFormat = DateFormat('dd MMM yyyy, hh:mm a');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Payment Receipt'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: Colors.grey.shade200, width: 1),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                // Header
                Column(
                  children: [
                    Text(
                      'PAYMENT RECEIPT',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Transaction Successful',
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: Colors.green.shade700,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Divider(color: Colors.grey.shade300),
                  ],
                ),

                // Offline notice
                if (!isOnline)
                  Container(
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.amber.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.amber.shade200),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.wifi_off, size: 20, color: Colors.amber.shade800),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Showing cached data - may not be up to date',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: Colors.amber.shade800,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                // Payment details
                _buildReceiptRow(
                  context,
                  label: 'Trans ID',
                  value: payment.transId,
                  isBoldValue: true,
                ),
                _buildReceiptRow(
                  context,
                  label: 'Method',
                  value: payment.method.toUpperCase(),
                ),
                _buildReceiptRow(
                  context,
                  label: 'Amount',
                  value: currencyFormat.format(payment.amount),
                  valueStyle: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.primaryColor,
                  ),
                ),
                _buildReceiptRow(
                  context,
                  label: 'Date',
                  value: dateFormat.format(payment.paymentDate),
                  valueStyle: TextStyle(fontSize: 15)
                ),
                _buildReceiptRow(
                  context,
                  label: 'Type',
                  value: payment.paymentType,
                ),
                if (payment.feeCategoryId != null)
                  _buildReceiptRow(
                    context,
                    label: 'Fee Vote',
                    value: payment.feeCategory!.name,
                  ),
                // if (payment.balance != null)
                  _buildReceiptRow(
                    context,
                    label: 'Balance',
                    value: payment.balance.toString(),
                  ),

                const SizedBox(height: 24),
                const Divider(),

                // Footer
                const SizedBox(height: 16),
                Text(
                  'Thank you for your payment to ${payment.student.branch.name}',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontStyle: FontStyle.italic,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'For any inquiries, please contact support',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.grey.shade600,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16),
        child: ElevatedButton.icon(
          icon: const Icon(LucideIcons.download),
          label: const Text('Download Receipt'),
          style: ElevatedButton.styleFrom(
            backgroundColor: ChanzoColors.primary,
            foregroundColor: ChanzoColors.white,
            minimumSize: const Size(double.infinity, 50),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          onPressed: () {
            // Handle print functionality
            downloadFeeReceiptPdf(paymentId: payment.id);
          },
        ),
      ),
    );
  }

  Widget _buildReceiptRow(
      BuildContext context, {
        required String label,
        required String value,
        TextStyle? valueStyle,
        bool isBoldValue = false,
      }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey.shade600,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: valueStyle ??
                  Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: isBoldValue ? FontWeight.bold : FontWeight.normal,
                  ),
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }
}