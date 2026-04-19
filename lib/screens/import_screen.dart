/// ImportScreen — import from JSON and export to JSON and PDF.
///
// Time-stamp: <2026-04-20>
///
/// Copyright (C) 2026, Togaware Pty Ltd
///
/// Licensed under the GNU General Public License, Version 3

library;

import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:file_picker/file_picker.dart';
import 'package:gap/gap.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:provider/provider.dart';

import 'package:billipod/models/bill.dart';
import 'package:billipod/screens/import_screen_widgets.dart';
import 'package:billipod/services/app_provider.dart';

class ImportScreen extends StatefulWidget {
  const ImportScreen({super.key});

  @override
  State<ImportScreen> createState() => _ImportScreenState();
}

class _ImportScreenState extends State<ImportScreen> {
  bool _loading = false;
  String? _importMessage;
  bool _importError = false;
  String? _exportMessage;
  bool _exportError = false;

  void _setImportMessage(String msg, {bool error = false}) {
    setState(() {
      _importMessage = msg;
      _importError = error;
    });
  }

  void _setExportMessage(String msg, {bool error = false}) {
    setState(() {
      _exportMessage = msg;
      _exportError = error;
    });
  }

  String _ts() {
    final now = DateTime.now();
    return '${now.year}'
        '${now.month.toString().padLeft(2, '0')}'
        '${now.day.toString().padLeft(2, '0')}'
        '_${now.hour.toString().padLeft(2, '0')}'
        '${now.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final provider = context.watch<AppProvider>();
    final total = provider.allBills.where((b) => !b.isTemplate).length;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Import ──────────────────────────────────────────────────
          Text('Import', style: Theme.of(context).textTheme.titleLarge),
          const Gap(8),
          Text(
            'Import bills from a JSON backup. Imported bills are '
            'merged with your existing list.',
            style: TextStyle(color: cs.onSurfaceVariant),
          ),
          if (_importMessage != null) ...[
            const Gap(12),
            ImportMessageBanner(
              message: _importMessage!,
              isError: _importError,
              cs: cs,
            ),
          ],
          const Gap(16),
          ImportActionCard(
            icon: Icons.upload_file_outlined,
            title: 'Import from JSON',
            subtitle: 'Select a BilliPod JSON backup file to import.',
            loading: _loading,
            onTap: () => _importJson(context),
          ),

          // ── Export ──────────────────────────────────────────────────
          const Gap(32),
          Text(
            'Export / Backup',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          if (_exportMessage != null) ...[
            const Gap(12),
            ImportMessageBanner(
              message: _exportMessage!,
              isError: _exportError,
              cs: cs,
            ),
          ],
          const Gap(8),
          Text(
            'Save a timestamped backup of your bills.',
            style: TextStyle(color: cs.onSurfaceVariant),
          ),
          const Gap(16),
          ImportActionCard(
            icon: Icons.download_outlined,
            title: 'Export to JSON',
            subtitle: 'Saves all $total bills as a JSON backup.',
            loading: _loading,
            onTap: () => _exportJson(context, provider),
          ),
          const Gap(12),
          ImportActionCard(
            icon: Icons.picture_as_pdf_outlined,
            title: 'Export Scheduled as PDF',
            subtitle:
                'Save or print ${provider.scheduledBills.length} '
                'scheduled bills.',
            loading: _loading,
            onTap: () => _exportPdf(
              context,
              bills: provider.scheduledBills,
              title: 'Scheduled Bills',
              prefix: 'scheduled',
            ),
          ),
          const Gap(12),
          ImportActionCard(
            icon: Icons.picture_as_pdf_outlined,
            title: 'Export Expected as PDF',
            subtitle:
                'Save or print ${provider.futureBills.length} '
                'expected bills.',
            loading: _loading,
            onTap: () => _exportPdf(
              context,
              bills: provider.futureBills,
              title: 'Expected Bills',
              prefix: 'expected',
            ),
          ),
          const Gap(12),
          ImportActionCard(
            icon: Icons.picture_as_pdf_outlined,
            title: 'Export Past as PDF',
            subtitle: 'Save or print ${provider.pastBills.length} paid bills.',
            loading: _loading,
            onTap: () => _exportPdf(
              context,
              bills: provider.pastBills,
              title: 'Past Bills',
              prefix: 'past',
            ),
          ),
        ],
      ),
    );
  }

  // ── Import ────────────────────────────────────────────────────────────────

  Future<void> _importJson(BuildContext context) async {
    final provider = context.read<AppProvider>();
    setState(() {
      _loading = true;
      _importMessage = null;
    });

    try {
      final result = await FilePicker.platform.pickFiles(
        dialogTitle: 'Select BilliPod JSON backup',
        type: FileType.any,
        withData: true,
      );
      if (result == null || result.files.isEmpty) {
        setState(() => _loading = false);
        return;
      }

      final file = result.files.first;
      final bytes = file.bytes;
      if (bytes == null) {
        _setImportMessage('Could not read file.', error: true);
        setState(() => _loading = false);
        return;
      }

      final List<dynamic> raw = jsonDecode(utf8.decode(bytes));
      final imported = raw
          .map((e) => Bill.fromJson(e as Map<String, dynamic>))
          .toList();

      if (imported.isEmpty) {
        _setImportMessage('No bills found in "${file.name}".', error: true);
        setState(() => _loading = false);
        return;
      }

      // Merge — skip any whose id already exists.
      final existingIds = provider.allBills.map((b) => b.id).toSet();
      final fresh = imported.where((b) => !existingIds.contains(b.id)).toList();
      for (final b in fresh) {
        provider.addBill(b);
      }
      await provider.saveToPod();
      _setImportMessage(
        'Imported ${fresh.length} new bill${fresh.length == 1 ? '' : 's'} '
        '(${imported.length - fresh.length} skipped as duplicates).',
      );
    } catch (e, st) {
      debugPrint('[Import] error: $e\n$st');
      _setImportMessage('Import failed: $e', error: true);
    } finally {
      setState(() => _loading = false);
    }
  }

  // ── JSON Export ───────────────────────────────────────────────────────────

  Future<void> _exportJson(BuildContext context, AppProvider provider) async {
    setState(() {
      _loading = true;
      _exportMessage = null;
    });

    try {
      final bills = provider.allBills.where((b) => !b.isTemplate).toList();
      final json = const JsonEncoder.withIndent(
        '  ',
      ).convert(bills.map((b) => b.toJson()).toList());
      final bytes = utf8.encode(json);
      final fileName = 'billipod_backup_${_ts()}.json';

      if (kIsWeb) {
        _setExportMessage(
          'Export to file is not supported on web.',
          error: true,
        );
        return;
      }

      final savePath = await FilePicker.platform.saveFile(
        dialogTitle: 'Save JSON backup',
        fileName: fileName,
        type: FileType.custom,
        allowedExtensions: ['json'],
      );
      if (savePath != null) {
        await File(savePath).writeAsBytes(bytes);
        _setExportMessage('Saved to $savePath');
      }
    } catch (e, st) {
      debugPrint('[Export JSON] error: $e\n$st');
      _setExportMessage('Export failed: $e', error: true);
    } finally {
      setState(() => _loading = false);
    }
  }

  // ── PDF Export ────────────────────────────────────────────────────────────

  Future<void> _exportPdf(
    BuildContext context, {
    required List<Bill> bills,
    required String title,
    required String prefix,
  }) async {
    setState(() {
      _loading = true;
      _exportMessage = null;
    });

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
        _setExportMessage('PDF ready — use the dialog to save or print.');
        return;
      }

      final savePath = await FilePicker.platform.saveFile(
        dialogTitle: 'Save PDF',
        fileName: pdfName,
        type: FileType.custom,
        allowedExtensions: ['pdf'],
      );
      if (savePath != null) {
        await File(savePath).writeAsBytes(pdfBytes);
        _setExportMessage('Saved to $savePath');
      }
    } catch (e, st) {
      debugPrint('[PDF Export] error: $e\n$st');
      _setExportMessage('PDF export failed: $e', error: true);
    } finally {
      setState(() => _loading = false);
    }
  }

  pw.Widget _cell(String text, {bool bold = false}) => pw.Padding(
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
