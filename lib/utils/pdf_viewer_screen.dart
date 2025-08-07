// PDF Viewer Screen
import 'package:flutter/material.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:open_file/open_file.dart';
import 'package:share_plus/share_plus.dart';

class PdfViewerScreen extends StatelessWidget {
  final String filePath;
  final String title;

  const PdfViewerScreen({
    Key? key,
    required this.filePath,
    this.title = 'PDF Document',
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: [
          IconButton(
            icon: Icon(Icons.share),
            onPressed: () => _sharePdf(context),
          ),
          IconButton(
            icon: Icon(Icons.open_in_browser),
            onPressed: () => OpenFile.open(filePath),
          ),
        ],
      ),
      body: PDFView(
        filePath: filePath,
        enableSwipe: true,
        swipeHorizontal: false,
        autoSpacing: true,
        pageFling: true,
        onError: (error) {
          print(error.toString());
        },
        onPageError: (page, error) {
          print('$page: ${error.toString()}');
        },
      ),
    );
  }

  void _sharePdf(BuildContext context) async {
    final box = context.findRenderObject() as RenderBox?;
    try {
      final shareResult = await SharePlus.instance.share(
        ShareParams(
          files: [XFile(filePath)],
          subject: "Fee Structure",
          title: "Download Fee Structure",
          text: "Download Fee Structure",
          sharePositionOrigin: box!.localToGlobal(Offset.zero) & box.size,
        ),
      );

      if (shareResult.status == ShareResultStatus.success) {
        debugPrint("Shared successfully!");
      } else if (shareResult.status == ShareResultStatus.dismissed) {
        debugPrint("Sharing dismissed by user.");
      } else {
        debugPrint("Sharing failed: ${shareResult.raw}");
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to share PDF: ${e.toString()}')),
      );
    }
  }
}