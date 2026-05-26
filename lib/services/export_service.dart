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

import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';
import 'package:open_filex/open_filex.dart';
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

  /// Generate a PDF and open it directly in the system viewer, without
  /// prompting for a save location. Writes the bytes to a temp file and
  /// launches the OS PDF handler. Returns an error string on failure, or
  /// null on success.
  ///
  /// Use this for "quick view" actions like the PDF button on each list
  /// page. For save-and-share flows, use [exportPdf] instead.
  static Future<String?> previewPdf({
    required List<Bill> bills,
    required String title,
    required String prefix,
    bool ascending = false,
  }) async {
    try {
      final built = await _buildPdfBytes(
        bills: bills,
        title: title,
        ascending: ascending,
      );
      final pdfName = 'billipod_${prefix}_${_ts()}.pdf';

      if (kIsWeb) {
        // No real filesystem; fall back to the printing-package preview.
        await Printing.layoutPdf(onLayout: (_) async => built, name: pdfName);
        return null;
      }

      // Write to temp and open. The file persists for the OS session but is
      // not the user's "saved" copy — they used the view button.
      final tmpDir = Directory.systemTemp;
      final tmpPath = '${tmpDir.path}${Platform.pathSeparator}$pdfName';
      await File(tmpPath).writeAsBytes(built);

      final result = await OpenFilex.open(tmpPath);
      if (result.type != ResultType.done) {
        debugPrint(
          '[ExportService] OpenFilex: ${result.type} - ${result.message}',
        );
        return 'Could not open PDF viewer: ${result.message}';
      }
      return null;
    } catch (e, st) {
      debugPrint('[ExportService] previewPdf error: $e\n$st');
      return e.toString();
    }
  }

  /// Result of an [exportPdf] call. [error] is non-null on failure;
  /// [savePath] is non-null on a successful save (null if user cancelled
  /// or on web where there is no save path).
  ///
  /// Callers can use [savePath] to offer a "View" action (e.g. via
  /// [openSavedPdf]).

  /// Export [bills] to a PDF file. Shows a save dialog on desktop/mobile
  /// or the print dialog on web. Does NOT auto-open the file — callers
  /// who want a view affordance should use [savePath] in the result to
  /// invoke [openSavedPdf] from a SnackBar action or similar.
  static Future<({String? error, String? savePath})> exportPdf({
    required List<Bill> bills,
    required String title,
    required String prefix,
    bool ascending = false,
  }) async {
    try {
      final built = await _buildPdfBytes(
        bills: bills,
        title: title,
        ascending: ascending,
      );
      final pdfName = 'billipod_${prefix}_${_ts()}.pdf';

      if (kIsWeb) {
        await Printing.layoutPdf(onLayout: (_) async => built, name: pdfName);
        return (error: null, savePath: null);
      }

      final savePath = await FilePicker.saveFile(
        dialogTitle: 'Save PDF',
        fileName: pdfName,
        type: FileType.custom,
        allowedExtensions: ['pdf'],
      );
      if (savePath == null) {
        return (error: null, savePath: null); // user cancelled
      }
      await File(savePath).writeAsBytes(built);
      return (error: null, savePath: savePath);
    } catch (e, st) {
      debugPrint('[ExportService] exportPdf error: $e\n$st');
      return (error: e.toString(), savePath: null);
    }
  }

  /// Open a previously-saved PDF in the system viewer. Returns an error
  /// string on failure, or null on success.
  static Future<String?> openSavedPdf(String path) async {
    try {
      final result = await OpenFilex.open(path);
      if (result.type != ResultType.done) {
        return 'Could not open PDF viewer: ${result.message}';
      }
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  /// Build the raw PDF bytes for [bills]. Shared by [previewPdf] and
  /// [exportPdf]. Does no file I/O.
  static Future<Uint8List> _buildPdfBytes({
    required List<Bill> bills,
    required String title,
    bool ascending = false,
  }) async {
    final now = DateTime.now();
    final dateStr = DateFormat('d MMMM yyyy').format(now);

    // Use a Unicode-capable font as the document default so characters
    // outside basic Latin (e.g. ·, –, —) render without the pdf package
    // emitting "Helvetica has no Unicode support" warnings. Noto Sans
    // covers a wide range and is bundled by the printing package.
    final baseFont = await PdfGoogleFonts.notoSansRegular();
    final boldFont = await PdfGoogleFonts.notoSansBold();
    final italicFont = await PdfGoogleFonts.notoSansItalic();
    final boldItalicFont = await PdfGoogleFonts.notoSansBoldItalic();

    final doc = pw.Document(
      theme: pw.ThemeData.withFont(
        base: baseFont,
        bold: boldFont,
        italic: italicFont,
        boldItalic: boldItalicFont,
      ),
    );

    // Sum of bill amounts (bills with no amount contribute zero).
    final totalAmount = bills.fold<double>(
      0,
      (sum, b) => sum + (b.amount ?? 0),
    );
    final totalStr = '\$${NumberFormat('#,##0.00').format(totalAmount)}';

    // Period: span between earliest and latest due dates across the
    // selected bills. Bills with no due date are ignored for this.
    final dueDates =
        bills.where((b) => b.dueDate != null).map((b) => b.dueDate!).toList()
          ..sort();
    final DateTime? firstDue = dueDates.isEmpty ? null : dueDates.first;
    final DateTime? lastDue = dueDates.isEmpty ? null : dueDates.last;
    final periodRange = (firstDue == null || lastDue == null)
        ? '—'
        : (firstDue == lastDue
              ? DateFormat('d MMM yyyy').format(firstDue)
              : '${DateFormat('d MMM yyyy').format(firstDue)} – '
                    '${DateFormat('d MMM yyyy').format(lastDue)}');
    final periodLength = (firstDue == null || lastDue == null)
        ? ''
        : _periodLength(firstDue, lastDue);

    // Shared column widths so the column-header table on each page lines
    // up exactly with the data table below it.
    final columnWidths = <int, pw.TableColumnWidth>{
      0: const pw.FlexColumnWidth(3),
      1: const pw.FlexColumnWidth(1.2),
      2: const pw.FlexColumnWidth(1.5),
      3: const pw.FlexColumnWidth(1.5),
    };

    pw.Widget buildColumnHeader() => pw.Table(
      columnWidths: columnWidths,
      border: const pw.TableBorder(
        bottom: pw.BorderSide(color: PdfColors.grey300, width: 0.5),
      ),
      defaultVerticalAlignment: pw.TableCellVerticalAlignment.middle,
      children: [
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfColors.grey200),
          children: [
            _cell('Title', bold: true),
            _cell('Amount', bold: true),
            _cell('Due', bold: true),
            _cell('Payment', bold: true),
          ],
        ),
      ],
    );

    // Sort bills by due date, most recent first. Bills with no due date
    // sink to the bottom in their original order.
    final sortedBills = [...bills]
      ..sort((a, b) {
        final ad = a.dueDate;
        final bd = b.dueDate;
        if (ad == null && bd == null) return 0;
        if (ad == null) return 1;
        if (bd == null) return -1;
        return ascending ? ad.compareTo(bd) : bd.compareTo(ad);
      });

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        header: (ctx) {
          if (ctx.pageNumber == 1) {
            return pw.Column(
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
                  '${bills.length} bill${bills.length == 1 ? '' : 's'}  ·  '
                  'Total $totalStr  ·  '
                  'Period $periodRange',
                  style: const pw.TextStyle(
                    fontSize: 10,
                    color: PdfColors.grey600,
                  ),
                ),
                pw.Divider(),
                pw.SizedBox(height: 4),
                buildColumnHeader(),
              ],
            );
          }
          return pw.Padding(
            padding: const pw.EdgeInsets.only(bottom: 4),
            child: buildColumnHeader(),
          );
        },
        footer: (ctx) => pw.Container(
          alignment: pw.Alignment.centerRight,
          margin: const pw.EdgeInsets.only(top: 8),
          child: pw.Text(
            'Page ${ctx.pageNumber} of ${ctx.pagesCount}',
            style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600),
          ),
        ),
        build: (ctx) => [
          pw.Table(
            columnWidths: columnWidths,
            border: const pw.TableBorder(
              bottom: pw.BorderSide(color: PdfColors.grey300, width: 0.5),
              horizontalInside: pw.BorderSide(
                color: PdfColors.grey200,
                width: 0.5,
              ),
            ),
            defaultVerticalAlignment: pw.TableCellVerticalAlignment.middle,
            children: [
              for (final b in sortedBills)
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
              pw.TableRow(
                decoration: const pw.BoxDecoration(color: PdfColors.grey100),
                children: [
                  _cell('Total', bold: true),
                  _cell(totalStr, bold: true),
                  _cell(periodLength, bold: true),
                  _cell(''),
                ],
              ),
            ],
          ),
        ],
      ),
    );

    return doc.save();
  }

  /// Compute a human-readable period length between [start] and [end],
  /// shown using two units at most:
  ///   - if there are any years: `N years M months` (months may be 0)
  ///   - otherwise:              `N months M days`  (months may be 0)
  /// Days are dropped once years are present; sub-day precision is never
  /// shown. Singular forms used where appropriate. Same-day → `0 days`.
  static String _periodLength(DateTime start, DateTime end) {
    if (end.isBefore(start)) {
      return _periodLength(end, start);
    }
    int years = end.year - start.year;
    int months = end.month - start.month;
    int days = end.day - start.day;

    if (days < 0) {
      // Borrow days from the previous month of `end`.
      final prevMonth = DateTime(end.year, end.month, 0);
      days += prevMonth.day;
      months -= 1;
    }
    if (months < 0) {
      months += 12;
      years -= 1;
    }

    String unit(int n, String singular) =>
        '$n ${n == 1 ? singular : '${singular}s'}';

    if (years > 0) {
      // Years present → show years + months, drop days.
      if (months > 0) return '${unit(years, 'year')} ${unit(months, 'month')}';
      return unit(years, 'year');
    }
    if (months > 0) {
      // Under a year → show months + days.
      if (days > 0) return '${unit(months, 'month')} ${unit(days, 'day')}';
      return unit(months, 'month');
    }
    return unit(days, 'day'); // covers 0 days and N days
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
