import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:printing/printing.dart';

import '../core/l10n_ext.dart';

/// Full-screen review of a generated PDF report before any print/save/
/// share action happens. Renders the actual document via the `printing`
/// package's own `PdfPreview` widget, which provides its own print/save/
/// share controls in its toolbar — nothing here calls
/// `Printing.layoutPdf` (which opens the OS print dialog immediately);
/// that only happens if the user explicitly taps print inside this
/// preview, so there's always a look-before-you-print step.
class PdfReviewScreen extends StatelessWidget {
  final Uint8List bytes;
  final String documentName;

  const PdfReviewScreen({super.key, required this.bytes, required this.documentName});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.reportPreviewTitle)),
      body: PdfPreview(
        build: (format) async => bytes,
        pdfFileName: '$documentName.pdf',
        canChangeOrientation: false,
        canChangePageFormat: false,
        canDebug: false,
      ),
    );
  }
}
