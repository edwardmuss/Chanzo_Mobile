import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../models/payment_model.dart';

class PaymentDetailsScreen extends StatelessWidget {
  final Payment payment;
  final bool isOnline;

  const PaymentDetailsScreen({
    Key? key,
    required this.payment,
    required this.isOnline,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Payment Details'),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!isOnline)
              Container(
                padding: EdgeInsets.all(8),
                margin: EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.amber.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.wifi_off, size: 16, color: Colors.amber.shade800),
                    SizedBox(width: 8),
                    Text('Showing cached data - may not be up to date'),
                  ],
                ),
              ),
            _buildDetailRow('Transaction ID', payment.transId),
            _buildDetailRow('Payment Method', payment.method.toUpperCase()),
            _buildDetailRow(
              'Amount',
              NumberFormat.currency(locale: 'en_US', symbol: 'KES')
                  .format(payment.amount),
            ),
            _buildDetailRow(
              'Payment Date',
              DateFormat('dd MMM yyyy, hh:mm a').format(payment.paymentDate),
            ),
            _buildDetailRow('Payment Type', payment.paymentType),
            if (payment.feeCategoryId != null)
              _buildDetailRow('Fee Category ID', payment.feeCategoryId.toString()),
            if (payment.accountId != null)
              _buildDetailRow('Account ID', payment.accountId.toString()),
            SizedBox(height: 24),
            Text(
              'Additional Details',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            Divider(),
            // Add more payment-specific details here
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade600,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: TextStyle(fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }
}