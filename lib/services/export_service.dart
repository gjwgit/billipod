/// ExportService — shared PDF export logic for BilliPod screens.
///
// Time-stamp: <Monday 2026-04-20 14:08:35 +1000 Graham Williams>
///
/// Copyright (C) 2026, Togaware Pty Ltd
///
/// Licensed under the GNU General Public License, Version 3

library;

import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import 'package:billipod/models/bill.dart';

class ExportService {
  ExportService._();

  static String _ts() {
    final now = DateTime.now();
    return '${now.year}'
        '${now.month.toString().padLeft(2, '0')}'
        '${now.day.toString().padLeft(2, '0')}'
        '_${now.hour.toString().padLeft(2, '0')}'
        '${now.minute.toString().padLeft(2, '0')}';
  }

  /// Export [bills] to a PDF file.
  ///
  /// Shows a save dialog on desktop/mobile or the print dialog on web.
  /// Returns an error string on failure, or null on success/cancelled.
  static Future<String?> exportPdf({
    required BuildContext context,
    required List<Bill> bills,
    required String title,
    required String prefix,
  }) async {
    try {
      final now = DateTime.now();
      final dateStr = DateFormat('d MMMM yyyy').format(now);
      final doc = pw.Document();

      doc.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(40),
          header: (ctx) => pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                title,
                style: pw.TextStyle(
                  fontSize: 20,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.Text(
                'Generated $dateStr  ·  '
                '${bills.length} bill${bills.length == 1 ? '' : 's'}',
                style: const pw.TextStyle(
                  fontSize: 10,
                  color: PdfColors.grey600,
                ),
              ),
              pw.Divider(),
              pw.SizedBox(height: 4),
            ],
          ),
          build: (ctx) => [
            pw.Table(
              columnWidths: {
                0: const pw.FlexColumnWidth(3),
                1: const pw.FlexColumnWidth(1.2),
                2: const pw.FlexColumnWidth(1.5),
                3: const pw.FlexColumnWidth(1.5),
              },
              border: const pw.TableBorder(
                bottom: pw.BorderSide(color: PdfColors.grey300, width: 0.5),
                horizontalInside: pw.BorderSide(
                  color: PdfColors.grey200,
                  width: 0.5,
                ),
              ),
              children: [
                // Header row
                pw.TableRow(
                  decoration: const pw.BoxDecoration(color: PdfColors.grey200),
                  children: [
                    _cell('Title', bold: true),
                    _cell('Amount', bold: true),
                    _cell('Due', bold: true),
                    _cell('Payment', bold: true),
                  ],
                ),
                // Data rows
                for (final b in bills)
                  pw.TableRow(
                    children: [
                      _cell(b.title),
                      _cell(b.amountStr),
                      _cell(
                        b.dueDate != null
                            ? DateFormat('d MMM yyyy').format(b.dueDate!)
                            : '—',
                      ),
                      _cell(b.paymentMethod ?? '—'),
                    ],
                  ),
              ],
            ),
          ],
        ),
      );

      final pdfBytes = await doc.save();
      final pdfName = 'billipod_${prefix}_${_ts()}.pdf';

      if (kIsWeb) {
        await Printing.layoutPdf(
          onLayout: (_) async => pdfBytes,
          name: pdfName,
        );
        return null;
      }

      final savePath = await FilePicker.saveFile(
        dialogTitle: 'Save PDF',
        fileName: pdfName,
        type: FileType.custom,
        allowedExtensions: ['pdf'],
      );
      if (savePath != null) {
        await File(savePath).writeAsBytes(pdfBytes);
      }
      return null;
    } catch (e, st) {
      debugPrint('[ExportService] PDF error: $e\n$st');
      return e.toString();
    }
  }

  static pw.Widget _cell(String text, {bool bold = false}) => pw.Padding(
    padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 5),
    child: pw.Text(
      text,
      style: pw.TextStyle(
        fontSize: 10,
        fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
      ),
    ),
  );
}
