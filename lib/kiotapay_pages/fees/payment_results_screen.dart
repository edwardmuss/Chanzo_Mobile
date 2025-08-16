import 'dart:io';

import 'package:clipboard/clipboard.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter/src/widgets/framework.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:kiotapay/globalclass/global_methods.dart';
import 'package:kiotapay/globalclass/kiotapay_fontstyle.dart';
import 'package:kiotapay/kiotapay_pages/fees/payment_screen.dart';
import 'package:kiotapay/kiotapay_pages/kiotapay_dahsboard/kiotapay_dahsboard.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
// import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';

import '../../globalclass/chanzo_color.dart';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

class PaymentResultScreen extends StatelessWidget {
  final bool success;
  final Map<String, dynamic>? paymentData;

  const PaymentResultScreen({
    Key? key,
    required this.success,
    this.paymentData,
  }) : super(key: key);

  void _sharePaymentDetails(Map<String, dynamic> paymentData) {
    // print(paymentData); return;

    final reference = paymentData['receipt_number'] ?? 'N/A';
    final amount = paymentData['amount'] ?? '0';
    final account = paymentData['account'] ?? 'N/A';
    final txDateStr = paymentData['TransactionDate'] ?? paymentData['data']['TransactionDate'] ?? '';

    // Parse and format the TransactionDate
    String formattedDate = '';
    if (txDateStr.length == 14) {
      try {
        final parsedDate = DateFormat("yyyyMMddHHmmss").parse(txDateStr);
        formattedDate = DateFormat("dd-MM-yyyy HH:mm").format(parsedDate);
      } catch (e) {
        formattedDate = 'Invalid date';
      }
    }

    final message =
        "$reference Confirmed. KSH. $amount sent to  ${authController.schoolName} for account $account via Gracehill App on $formattedDate.";

    Share.share(message);
  }

  Future<void> makePdf(Map<String, dynamic> paymentData, BuildContext context) async {
    // final font = await PdfGoogleFonts.nunitoExtraLight();
    final reference = paymentData['receipt_number'] ?? 'N/A';
    final amount = paymentData['amount'] ?? '0';
    final account = paymentData['account'] ?? 'N/A';
    final txDateStr = paymentData['TransactionDate'] ?? '';
    final phone = paymentData['phone'] ?? '';
    final status = paymentData['status']?.toString().toLowerCase() ??
        paymentData['data']?['status']?.toString().toLowerCase() ??
        '';
    final Directory? directory;
    final pdf = pw.Document();
    // Calculate the width and height of the A4 page in points
    final double pageWidth = PdfPageFormat.a4.availableWidth;
    final double pageHeight = PdfPageFormat.a4.availableHeight;

    pw.Widget roundedBackgroundText(String text,
        {pw.TextStyle? style, PdfColor? backgroundColor}) {
      return pw.Container(
        padding: pw.EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        decoration: pw.BoxDecoration(
          color: backgroundColor ?? PdfColors.grey400,
          borderRadius: pw.BorderRadius.circular(5),
        ),
        child: pw.Text(
          text,
          style: style ?? pw.TextStyle(color: PdfColors.black),
        ),
      );
    }

    PdfColor convertColor(Color color) {
      return PdfColor.fromInt(color.value);
    }

    final image = pw.MemoryImage(
      (await rootBundle.load('assets/images/logo-dark.png')).buffer.asUint8List(),
    );
    pw.Widget buildDetailRow(String label, String value) {
      return pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.SizedBox(
            width: 120,
            child: pw.Text(
              "$label:",
              style: pw.TextStyle(
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.black,
              ),
            ),
          ),
          pw.Expanded(
            child: pw.Text(
              value,
              style: pw.TextStyle(
                color: PdfColors.grey800,
              ),
            ),
          ),
        ],
      );
    }


    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Container(
                padding: pw.EdgeInsets.fromLTRB(10, 0, 10, 0),
                child: pw.Column(
                  mainAxisAlignment: pw.MainAxisAlignment.start,
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Image(
                          image,
                          width: 120,
                          fit: pw.BoxFit.contain,
                        ),
                        roundedBackgroundText(
                          status,
                          style: pw.TextStyle(
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColor.fromInt(ChanzoColors.white.value),
                          ),
                          backgroundColor: status.contains('confirmed')
                              ? convertColor(ChanzoColors.primary)
                              : PdfColors.orangeAccent,
                        ),
                      ],
                    ),
                    pw.SizedBox(height: 20),
                    pw.Text(
                      "RECEIPT NO. #${reference}",
                      style: pw.TextStyle(
                        fontWeight: pw.FontWeight.bold,
                        fontSize: 24,
                        color: PdfColor.fromInt(ChanzoColors.primary.value),
                      ),
                    ),
                    pw.SizedBox(height: 10),
                    pw.Text(
                      "DATE: ${DateFormat('d MMMM yyyy').format(DateFormat('yyyy-MM-dd').parse(paymentData['created_at']))}",
                      style: pw.TextStyle(
                        fontSize: 16,
                        color: PdfColor.fromInt(ChanzoColors.secondary.value),
                      ),
                    ),
                    pw.SizedBox(height: 5),
                    pw.Text(
                      "TIME: ${DateFormat('kk:mm:ss').format(DateTime.parse(paymentData['created_at']).add(Duration(hours: 3)))}",
                      style: pw.TextStyle(
                        fontSize: 16,
                        color: PdfColor.fromInt(ChanzoColors.secondary.value),
                      ),
                    ),
                    pw.SizedBox(height: 50),
                    pw.Row(
                      children: [
                        pw.Text(
                          "SENT TO: ",
                          style: pw.TextStyle(
                              fontWeight: pw.FontWeight.bold,
                              fontSize: 20,
                              color: PdfColor.fromInt(ChanzoColors.primary.value)),
                        ),
                        pw.SizedBox(width: 10),
                        pw.Text(
                          authController.schoolName,
                          style: pw.TextStyle(
                              fontWeight: pw.FontWeight.bold,
                              fontSize: 20,
                              color: PdfColor.fromInt(ChanzoColors.primary.value)),
                        ),
                      ],
                    ),
                    pw.SizedBox(height: 30),
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text(
                          "TOTAL:",
                          style: pw.TextStyle(
                              color: PdfColor.fromInt(ChanzoColors.primary.value),
                              fontSize: 30,
                              fontWeight: pw.FontWeight.bold),
                        ),
                        pw.Text(
                          "KES ${amount}",
                          style: pw.TextStyle(
                              color: PdfColor.fromInt(ChanzoColors.primary.value),
                              fontSize: 30,
                              fontWeight: pw.FontWeight.bold),
                        ),
                      ],
                    ),
                    pw.SizedBox(height: 50),
                    pw.Container(
                      padding: pw.EdgeInsets.all(16),
                      decoration: pw.BoxDecoration(
                        color: PdfColors.grey100,
                        borderRadius: pw.BorderRadius.circular(8),
                      ),
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(
                            "OTHER DETAILS",
                            style: pw.TextStyle(
                              fontSize: 22,
                              fontWeight: pw.FontWeight.bold,
                              color: PdfColor.fromInt(ChanzoColors.primary.value),
                              decoration: pw.TextDecoration.underline,
                            ),
                          ),
                          pw.SizedBox(height: 20),
                          buildDetailRow("Ref No", reference.isEmpty ? '---' : reference),
                          pw.SizedBox(height: 12),
                          buildDetailRow("Payment Mode", "MPESA"),
                          pw.SizedBox(height: 12),
                          buildDetailRow("Account", account),
                        ],
                      ),
                    ),

                    pw.SizedBox(height: 50),
                    pw.Container(
                      width: double.infinity,
                      padding: pw.EdgeInsets.all(16),
                      decoration: pw.BoxDecoration(
                        color: PdfColor.fromInt(ChanzoColors.primary.value),
                        borderRadius: pw.BorderRadius.circular(8),
                      ),
                      child: pw.Center(
                        child: pw.Text(
                          "THIS IS NOT AN OFFICIAL INVOICE OR TAX DOCUMENT",
                          textAlign: pw.TextAlign.center,
                          style: pw.TextStyle(
                            fontSize: 10,
                            color: PdfColors.white,
                            fontWeight: pw.FontWeight.bold,
                            letterSpacing: 1.5,
                          ),
                        ),
                      ),
                    ),
                    pw.SizedBox(height: 10),
                    // pw.Center(
                    //   child: pw.Text(
                    //     "Generated by Gracehill Pay",
                    //     style: pw.TextStyle(
                    //       fontSize: 12,
                    //       color: PdfColor.fromInt(ChanzoColors.grey_3.value),
                    //       fontStyle: pw.FontStyle.italic,
                    //     ),
                    //   ),
                    // ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );

    await saveAndOpenPdf(
      pdfBytes: await pdf.save(),
      reference: '$reference',
      title: "Receipt",
      context: context,
    );

  }

  @override
  Widget build(BuildContext context) {
    final status = paymentData?['status']?.toString().toLowerCase() ??
        paymentData?['data']?['status']?.toString().toLowerCase() ??
        '';

    final amount =
        paymentData?['amount'] ?? paymentData?['data']?['amount'] ?? '';

    final account =
        paymentData?['account'] ?? paymentData?['data']?['account'] ?? '';

    final reference =
        paymentData?['receipt_number'] ?? paymentData?['data']?['receipt_number'] ?? '';

    String title = "Payment Status";
    String message = "Something went wrong.";
    IconData icon = Icons.info;
    Color iconColor = Colors.grey;

    if (status.contains("confirmed")) {
      title = "Payment Successful";
      message = "Thank you! Your payment has been confirmed.";
      icon = Icons.check_circle;
      iconColor = ChanzoColors.primary;
    } else if (status.contains("cancelled")) {
      title = "Payment Cancelled";
      message =
      "You cancelled the payment. Please try again if this was a mistake.";
      icon = Icons.cancel;
      iconColor = Colors.orange;
    } else if (status.contains("timeout")) {
      title = "Payment Timeout";
      message = "DS timeout user cannot be reached.";
      icon = Icons.cancel;
      iconColor = Colors.orange;
    } else if (status.contains("insufficient") || status.contains("declined")) {
      title = "Payment Failed";
      message = "Insufficient balance or declined transaction.";
      icon = Icons.warning;
      iconColor = Colors.red;
    } else if (status.isNotEmpty) {
      title =
      "Payment Status: ${status[0].toUpperCase()}${status.substring(1)}";
      message =
          paymentData?['message'] ?? 'Awaiting confirmation or unknown status.';
      icon = Icons.info;
      iconColor = Colors.blue;
    } else if (!success) {
      title = "Payment Failed";
      message = "We couldn't confirm your payment. Please try again later.";
      icon = Icons.error;
      iconColor = Colors.red;
    }

    void copyText(String value) async {
      await FlutterClipboard.copy(value);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        backgroundColor: Colors.green,
        content: Text(
          "📝 text Copied to clipboard",
          style: TextStyle(color: Colors.white, fontSize: 12),
        ),
        behavior: SnackBarBehavior.floating,
        margin: EdgeInsets.symmetric(vertical: 10),
      ));
    }

    return Scaffold(
      appBar: AppBar(title: Text("Payment Status")),
      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              children: [
                // Card with payment result info
                Card(
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                  elevation: 4,
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(icon, color: iconColor, size: 80),
                        SizedBox(height: 20),
                        Text(
                          title,
                          style: TextStyle(
                              fontSize: 24, fontWeight: FontWeight.bold),
                        ),
                        SizedBox(height: 10),
                        // Text(message, textAlign: TextAlign.center),
                        // SizedBox(height: 10),
                        // Text("Amount: $amount"),
                        // Text("Account: $account"),
                        // if (reference.isNotEmpty) Text("Reference: $reference"),
                        // if (status.isNotEmpty) Text("Status: $status"),
                        if (reference.isNotEmpty)
                          ListTile(
                            contentPadding: EdgeInsets.symmetric(
                                horizontal: 0, vertical: 1),
                            leading: Text(
                              'Ref:',
                              style: pregular_md,
                            ),
                            trailing: RichText(
                              text: TextSpan(
                                children: [
                                  WidgetSpan(
                                    child: InkWell(
                                      onTap: () {
                                        copyText(reference);
                                      },
                                      child: Text(
                                        "$reference ",
                                        style: pregular_hsm.copyWith(
                                            color: ChanzoColors.primary,
                                            fontWeight: FontWeight.w900),
                                      ),
                                    ),
                                  ),
                                  WidgetSpan(
                                    child: InkWell(
                                      onTap: () {
                                        copyText(reference);
                                      },
                                      child: Icon(
                                        Icons.copy,
                                        size: 20,
                                        color: ChanzoColors.primary,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                        ListTile(
                          contentPadding:
                          EdgeInsets.symmetric(horizontal: 0, vertical: 1),
                          // title: Text('Available Balance'),
                          leading: Text(
                            'Amount:',
                            style: pregular_md,
                          ),
                          trailing: Text(
                            "KES ${amount} ",
                            style: pregular_hsm.copyWith(
                                color: ChanzoColors.primary,
                                fontWeight: FontWeight.w900),
                          ),
                        ),
                        ListTile(
                          contentPadding:
                          EdgeInsets.symmetric(horizontal: 0, vertical: 1),
                          // title: Text('Available Balance'),
                          leading: Text(
                            'Account:',
                            style: pregular_md,
                          ),
                          trailing: Text(
                            account,
                            style: pregular_hsm.copyWith(
                                color: ChanzoColors.primary,
                                fontWeight: FontWeight.w900),
                          ),
                        ),
                        // if (status.isNotEmpty)
                        //   Text(
                        //     status,
                        //     style: pregular_md.copyWith(
                        //         color: status.contains('confirmed')
                        //             ? ChanzoColors.primary
                        //             : Colors.red,
                        //         fontWeight: FontWeight.w300),
                        //   ),
                        SizedBox(height: 40),
                        InkWell(
                          splashColor: ChanzoColors.transparent,
                          highlightColor: ChanzoColors.transparent,
                          onTap: () {
                            if (status.contains("confirmed")) {
                              Get.to(
                                    () => KiotaPayDashboard('0') //tsScreen(studentId: authController.selectedStudent['id']),
                              );
                            } else {
                              Navigator.pop(context);
                            }
                          },
                          child: Container(
                            height: MediaQuery.of(context).size.height / 15,
                            decoration: BoxDecoration(
                              color: ChanzoColors.primary,
                              borderRadius: BorderRadius.circular(50),
                            ),
                            child: Center(
                              child: Text(
                                status.contains("confirmed") ? "Done" : "Retry",
                                style: pregular_md.copyWith(
                                    fontSize: 14, color: ChanzoColors.white),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Action buttons below the card
                SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _ActionIcon(
                      icon: Icons.share,
                      label: "Share\nDetails",
                      onTap: () {
                        if (paymentData != null &&
                            status.contains("confirmed")) {
                          // print("I was tapped $paymentData");return;
                          _sharePaymentDetails(paymentData!);
                        }
                      },
                    ),
                    SizedBox(width: 40),
                    _ActionIcon(
                      icon: Icons.download,
                      label: "Download \n Receipt",
                      onTap: () {
                        if (paymentData != null &&
                            status.contains("confirmed")) {
                          makePdf(paymentData!, context);
                        }
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ActionIcon extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ActionIcon({
    Key? key,
    required this.icon,
    required this.label,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      splashColor: Colors.transparent,
      child: Column(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: ChanzoColors.primary.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 30, color: ChanzoColors.primary),
          ),
          SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(fontSize: 12, color: ChanzoColors.primary),
            textAlign: TextAlign.center,
            maxLines: 2,
          ),
        ],
      ),
    );
  }
}
