import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:kiotapay/globalclass/global_methods.dart';
import 'package:kiotapay/globalclass/kiotapay_constants.dart';
import 'package:kiotapay/globalclass/kiotapay_fontstyle.dart';

import '../../globalclass/chanzo_color.dart';
import 'payment_results_screen.dart';

class PaymentConfirmScreen extends StatefulWidget {
  const PaymentConfirmScreen(
      {super.key,
        required this.phone,
        required this.amount,
        required this.account,
        required this.method});

  final String phone;
  final String account;
  final int amount;
  final String method;

  @override
  State<PaymentConfirmScreen> createState() =>
      _PaymentConfirmScreenState();
}

class _PaymentConfirmScreenState extends State<PaymentConfirmScreen> {
  dynamic size;
  double height = 0.00;
  double width = 0.00;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> postMobilePaymentWithStatusCheck({
    required BuildContext context,
    required String account,
    required int amount,
    required String phone,
  }) async {
    final Uri paymentUrl = widget.method == 'kcb' ? Uri.parse(KiotaPayConstants.kcbStkPush) : Uri.parse(KiotaPayConstants.mpesaPaybillStkPush);
    final Uri statusUrl = Uri.parse(KiotaPayConstants.stkPushStatus);

    final payload = {
      "student_id": authController.selectedStudentId,
      "amount": amount,
      "account_number": account,
      "mpesa_number": phone
    };

    // Show loader
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text("Processing payment..."),
          ],
        ),
      ),
    );

    try {
      final response = await http.post(
        paymentUrl,
        headers: {
          'Authorization': 'Bearer ${await storage.read(key: 'token')}',
          'Content-Type': 'application/json',
          'Accept': 'application/json'
        },
        body: jsonEncode(payload),
      );

      final result = jsonDecode(response.body);
      print("STK Push Response: $result");

      if (response.statusCode == 200 && result['MerchantRequestID'] != null) {
        final merchantRequestID = result['MerchantRequestID'];

        final pollResult =
        await pollPaymentStatus(statusUrl, merchantRequestID);

        Navigator.of(context).pop();

        final Map<String, dynamic> paymentData = {
          ...(pollResult['data'] as Map<String, dynamic>? ?? {}),
          'amount': amount,
          'account': account,
        };
        print("Payment data is $paymentData");
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => PaymentResultScreen(
              success: pollResult['confirmed'],
              paymentData: paymentData,
            ),
          ),
        );
      } else {
        Navigator.of(context).pop();

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) =>
                PaymentResultScreen(success: false, paymentData: result),
          ),
        );
      }
    } catch (e) {
      print("Payment initiation failed: $e");

      // Close loader
      Navigator.of(context).pop();

      // Navigate to fail screen
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => PaymentResultScreen(success: false),
        ),
      );
    }
  }

  Future<Map<String, dynamic>> pollPaymentStatus(
      Uri statusUrl, String merchantRequestID) async {
    const int maxAttempts = 12;
    const Duration delay = Duration(seconds: 5);
    int attempts = 0;

    while (attempts < maxAttempts) {
      final response = await http.post(
        statusUrl,
        headers: {
          'Authorization': 'Bearer ${await storage.read(key: 'token')}',
          'Content-Type': 'application/json',
          'Accept': 'application/json'
        },
        body: jsonEncode({'MerchantRequestID': merchantRequestID}),
      );

      final result = jsonDecode(response.body);
      final String statusMessage = result['status'].toString().toLowerCase();

      // Break polling for known final states or specific keywords
      if (response.statusCode == 200) {
        if (statusMessage.contains('confirmed')) {
          return {'confirmed': true, 'data': result};
        }

        if (statusMessage.contains('cancelled') ||
            statusMessage.contains('timeout') ||
            statusMessage.contains('invalid') ||
            statusMessage.contains('no response') ||
            statusMessage.contains('not a child') ||
            statusMessage.contains('cannot be reached')) {
          return {'confirmed': false, 'data': result};
        }
      }

      await Future.delayed(delay);
      attempts++;
    }

    return {
      'confirmed': false,
      'data': {'status': 'timeout', 'message': 'Payment confirmation timed out'}
    };
  }

  @override
  Widget build(BuildContext context) {
    size = MediaQuery.of(context).size;
    height = size.height;
    width = size.width;
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.only(left: 16.0, right: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: height / 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    ClipOval(
                      child: Material(
                        color: ChanzoColors.primary,
                        child: InkWell(
                          splashColor: ChanzoColors.white,
                          onTap: () {
                            Navigator.pop(context);
                          },
                          child: SizedBox(
                            width: 35,
                            height: 35,
                            child: Icon(
                              Icons.chevron_left,
                              size: 25,
                              color: ChanzoColors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                    ClipOval(
                      child: Material(
                        color: ChanzoColors.primary,
                        child: InkWell(
                          splashColor: ChanzoColors.white,
                          onTap: () {
                            Navigator.pop(context);
                          },
                          child: SizedBox(
                            width: 35,
                            height: 35,
                            child: Icon(
                              Icons.chevron_left,
                              size: 25,
                              color: ChanzoColors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 20),
                Center(
                  child: Text(
                    "CONFIRM",
                    textAlign: TextAlign.center,
                    style: Theme.of(context)
                        .textTheme
                        .headlineSmall!
                        .copyWith(color: ChanzoColors.primary),
                  ),
                ),
                SizedBox(height: 20),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(20),
                    margin: EdgeInsets.symmetric(vertical: 20),
                    decoration: BoxDecoration(
                      color: ChanzoColors.primary.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(20),
                      border:
                      Border.all(color: ChanzoColors.primary.withOpacity(0.2)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Payment Summary",
                          style: pregular_hmd.copyWith(
                              color: ChanzoColors.primary,
                              fontWeight: FontWeight.w600),
                        ),
                        SizedBox(height: 16),
                        _buildDetailRow(
                            Icons.phone_android, "Phone", widget.phone),
                        SizedBox(height: 12),
                        _buildDetailRow(Icons.account_balance_wallet, "Amount",
                            "KES ${widget.amount}"),
                        SizedBox(height: 12),
                        _buildDetailRow(
                            Icons.account_box, "Account", widget.account),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        minimum: EdgeInsets.all(16),
        child: InkWell(
          splashColor: ChanzoColors.transparent,
          highlightColor: ChanzoColors.transparent,
          onTap: () async {
            // final isAuthenticated = await BiometricAuth.authenticateUser();
            // if (isAuthenticated) {
            //   print(isAuthenticated);
            await postMobilePaymentWithStatusCheck(
              account: widget.account,
              amount: widget.amount,
              phone: widget.phone,
              context: context,
            );
            // }
          },
          child: Container(
            height: height / 15,
            decoration: BoxDecoration(
              color: ChanzoColors.primary,
              borderRadius: BorderRadius.circular(50),
            ),
            child: Center(
              child: Text(
                "Confirm",
                style: pregular_md.copyWith(fontSize: 14, color: ChanzoColors.white),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: ChanzoColors.primary, size: 20),
        SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  // color: Colors.grey.shade700,
                ),
              ),
              SizedBox(height: 4),
              Text(value,
                  style: TextStyle(
                      fontSize: 16,
                      color: ChanzoColors.primary,
                      fontWeight: FontWeight.w600)),
            ],
          ),
        )
      ],
    );
  }
}
