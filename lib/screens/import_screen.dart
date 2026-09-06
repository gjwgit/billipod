/// ImportScreen — import from JSON and export to JSON and PDF.
///
// Time-stamp: <Saturday 2026-07-18 10:17:15 +1000 Graham Williams>
///
/// Copyright (C) 2026, Togaware Pty Ltd
///
/// Licensed under the GNU General Public License, Version 3

library;

import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:file_picker/file_picker.dart';
import 'package:gap/gap.dart';
import 'package:intl/intl.dart';
import 'package:markdown_tooltip/markdown_tooltip.dart';
import 'package:printing/printing.dart';
import 'package:provider/provider.dart';

import 'package:billipod/models/bill.dart';
import 'package:billipod/screens/import_screen_widgets.dart';
import 'package:billipod/services/app_provider.dart';
import 'package:billipod/services/export_service.dart';
import 'package:billipod/widgets/date_field.dart';

class ImportScreen extends StatefulWidget {
  const ImportScreen({super.key});

  @override
  State<ImportScreen> createState() => _ImportScreenState();
}

class _ImportScreenState extends State<ImportScreen> {
  bool _loading = false;
  String? _backupMessage;
  bool _backupError = false;
  String? _viewMessage;
  bool _viewError = false;

  /// Which subset of bills to include when viewing as PDF.
  _PdfScope _pdfScope = _PdfScope.all;

  /// Optional date-range filter applied on top of the scope. When null on a
  /// side, that side is unbounded.
  DateTime? _rangeFrom;
  DateTime? _rangeTo;

  void _setBackupMessage(String msg, {bool error = false}) {
    setState(() {
      _backupMessage = msg;
      _backupError = error;
    });
  }

  void _setViewMessage(String msg, {bool error = false}) {
    setState(() {
      _viewMessage = msg;
      _viewError = error;
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

    return Align(
      alignment: Alignment.topLeft,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Backup & Restore ────────────────────────────────────────
            Text(
              'Export & Import',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const Gap(8),
            Text(
              'Save a complete JSON backup of all your bills, or restore '
              'everything from a previously saved backup file. '
              'Also note the encrypted backup option available through '
              'your profile menu.',
              style: TextStyle(color: cs.onSurfaceVariant),
            ),
            if (_backupMessage != null) ...[
              const Gap(12),
              ImportMessageBanner(
                message: _backupMessage!,
                isError: _backupError,
                cs: cs,
              ),
            ],
            const Gap(16),
            Row(
              children: [
                MarkdownTooltip(
                  message:
                      '**Export JSON**\n\n'
                      'Save all $total bills to a BilliPod JSON backup file '
                      'on this device. Keep it somewhere safe so you can '
                      'restore everything later.',
                  child: FilledButton.icon(
                    icon: const Icon(Icons.download),
                    label: const Text('Export JSON'),
                    onPressed: _loading
                        ? null
                        : () => _exportJson(context, provider),
                  ),
                ),
                const Gap(12),
                MarkdownTooltip(
                  message:
                      '**Import JSON**\n\n'
                      'Restore bills from a previously saved BilliPod JSON '
                      'backup file. Restored bills are merged with your '
                      'existing list.',
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.upload),
                    label: const Text('Import JSON'),
                    onPressed: _loading ? null : () => _importJson(context),
                  ),
                ),
              ],
            ),

            // ── View ────────────────────────────────────────────────────
            const Gap(32),
            Text('View', style: Theme.of(context).textTheme.titleLarge),
            const Gap(8),
            Text(
              'Choose which bills to include, then view them as a PDF on '
              'screen. You can save or print from the preview. Optionally '
              'restrict to a date range based on due dates.',
              style: TextStyle(color: cs.onSurfaceVariant),
            ),
            if (_viewMessage != null) ...[
              const Gap(12),
              ImportMessageBanner(
                message: _viewMessage!,
                isError: _viewError,
                cs: cs,
              ),
            ],
            const Gap(12),
            DropdownButtonFormField<_PdfScope>(
              initialValue: _pdfScope,
              decoration: const InputDecoration(
                labelText: 'Bills to include',
                border: OutlineInputBorder(),
                isDense: true,
              ),
              items: [
                DropdownMenuItem(
                  value: _PdfScope.all,
                  child: Text(
                    'All bills (${provider.allBills.where((b) => !b.isTemplate).length})',
                  ),
                ),
                DropdownMenuItem(
                  value: _PdfScope.expected,
                  child: Text('Expected (${provider.futureBills.length})'),
                ),
                DropdownMenuItem(
                  value: _PdfScope.scheduled,
                  child: Text('Scheduled (${provider.scheduledBills.length})'),
                ),
                DropdownMenuItem(
                  value: _PdfScope.past,
                  child: Text('Past (${provider.pastBills.length})'),
                ),
              ],
              onChanged: _loading
                  ? null
                  : (v) {
                      if (v != null) setState(() => _pdfScope = v);
                    },
            ),
            const Gap(12),
            // Date range row: From | To | Clear
            Row(
              children: [
                Expanded(
                  child: DateField(
                    label: 'From',
                    value: _rangeFrom,
                    enabled: !_loading,
                    onPick: () => _pickRangeDate(isFrom: true),
                  ),
                ),
                const Gap(8),
                Expanded(
                  child: DateField(
                    label: 'To',
                    value: _rangeTo,
                    enabled: !_loading,
                    onPick: () => _pickRangeDate(isFrom: false),
                  ),
                ),
                const Gap(8),
                IconButton(
                  icon: const Icon(Icons.clear),
                  tooltip: 'Clear date range',
                  onPressed:
                      (_loading || (_rangeFrom == null && _rangeTo == null))
                      ? null
                      : () => setState(() {
                          _rangeFrom = null;
                          _rangeTo = null;
                        }),
                ),
              ],
            ),
            const Gap(12),
            ImportActionCard(
              icon: Icons.picture_as_pdf_outlined,
              title: 'View as PDF',
              subtitle: _pdfScopeSubtitle(provider),
              loading: _loading,
              onTap: () => _exportPdf(context, provider),
            ),
          ],
        ),
      ),
    );
  }

  // ── Import ────────────────────────────────────────────────────────────────

  Future<void> _importJson(BuildContext context) async {
    final provider = context.read<AppProvider>();
    setState(() {
      _loading = true;
      _backupMessage = null;
    });

    try {
      final file = await FilePicker.pickFile(
        dialogTitle: 'Select BilliPod JSON backup',
        type: FileType.any,
      );
      if (file == null) {
        setState(() => _loading = false);
        return;
      }

      final bytes = await file.readAsBytes();

      final List<dynamic> raw = jsonDecode(utf8.decode(bytes));
      final imported = raw
          .map((e) => Bill.fromJson(e as Map<String, dynamic>))
          .toList();

      if (imported.isEmpty) {
        _setBackupMessage('No bills found in "${file.name}".', error: true);
        setState(() => _loading = false);
        return;
      }

      // Merge — skip any whose id already exists.
      final existingIds = provider.allBills.map((b) => b.id).toSet();
      final fresh = imported.where((b) => !existingIds.contains(b.id)).toList();
      for (final b in fresh) {
        provider.addBill(b);
      }
      final saveError = await provider.saveToPod();
      if (saveError != null) {
        // Do not claim success: the bills are in memory but not on the Pod.
        _setBackupMessage('Import failed to save: $saveError', error: true);

        return;
      }
      _setBackupMessage(
        'Imported ${fresh.length} new bill${fresh.length == 1 ? '' : 's'} '
        '(${imported.length - fresh.length} skipped as duplicates).',
      );
    } catch (e, st) {
      debugPrint('[Import] error: $e\n$st');
      _setBackupMessage('Import failed: $e', error: true);
    } finally {
      setState(() => _loading = false);
    }
  }

  // ── JSON Export ───────────────────────────────────────────────────────────

  Future<void> _exportJson(BuildContext context, AppProvider provider) async {
    setState(() {
      _loading = true;
      _backupMessage = null;
    });

    try {
      final bills = provider.allBills.where((b) => !b.isTemplate).toList();
      final json = const JsonEncoder.withIndent(
        '  ',
      ).convert(bills.map((b) => b.toJson()).toList());
      final bytes = utf8.encode(json);
      final fileName = 'billipod_backup_${_ts()}.json';

      if (kIsWeb) {
        _setBackupMessage(
          'Export to file is not supported on web.',
          error: true,
        );
        return;
      }

      final savedUri = await FilePicker.saveFile(
        dialogTitle: 'Save JSON backup',
        fileName: fileName,
        type: FileType.custom,
        allowedExtensions: ['json'],
        bytes: bytes,
      );
      if (savedUri != null) {
        _setBackupMessage(
          'Saved to '
          '${savedUri.scheme == 'file' ? savedUri.toFilePath() : savedUri}',
        );
      }
    } catch (e, st) {
      debugPrint('[Export JSON] error: $e\n$st');
      _setBackupMessage('Export failed: $e', error: true);
    } finally {
      setState(() => _loading = false);
    }
  }

  // ── PDF Export ────────────────────────────────────────────────────────────

  /// Bills covered by the currently-selected scope AND date range.
  List<Bill> _scopedBills(AppProvider provider) {
    final List<Bill> base = switch (_pdfScope) {
      _PdfScope.all => provider.allBills.where((b) => !b.isTemplate).toList(),
      _PdfScope.expected => provider.futureBills,
      _PdfScope.scheduled => provider.scheduledBills,
      _PdfScope.past => provider.pastBills,
    };
    if (_rangeFrom == null && _rangeTo == null) return base;
    // Normalise bounds: From at start of day, To at end of day, so a bill
    // dated on the boundary is included regardless of its time-of-day.
    final from = _rangeFrom == null
        ? null
        : DateTime(_rangeFrom!.year, _rangeFrom!.month, _rangeFrom!.day);
    final to = _rangeTo == null
        ? null
        : DateTime(_rangeTo!.year, _rangeTo!.month, _rangeTo!.day, 23, 59, 59);
    return base.where((b) {
      final d = b.dueDate;
      if (d == null) return false; // can't place undated bills in a range
      if (from != null && d.isBefore(from)) return false;
      if (to != null && d.isAfter(to)) return false;
      return true;
    }).toList();
  }

  String _pdfScopeSubtitle(AppProvider provider) {
    final n = _scopedBills(provider).length;
    final noun = 'bill${n == 1 ? '' : 's'}';
    final rangeStr = (_rangeFrom == null && _rangeTo == null)
        ? ''
        : ' (${_rangeLabel()})';
    switch (_pdfScope) {
      case _PdfScope.all:
        return 'Saves $n $noun as a PDF$rangeStr.';
      case _PdfScope.expected:
        return 'Saves $n expected $noun as a PDF$rangeStr.';
      case _PdfScope.scheduled:
        return 'Saves $n scheduled $noun as a PDF$rangeStr.';
      case _PdfScope.past:
        return 'Saves $n past $noun as a PDF$rangeStr.';
    }
  }

  String _rangeLabel() {
    final fmt = DateFormat('d MMM yyyy');
    if (_rangeFrom != null && _rangeTo != null) {
      return '${fmt.format(_rangeFrom!)} - ${fmt.format(_rangeTo!)}';
    }
    if (_rangeFrom != null) return 'from ${fmt.format(_rangeFrom!)}';
    return 'until ${fmt.format(_rangeTo!)}';
  }

  Future<void> _pickRangeDate({required bool isFrom}) async {
    final initial = isFrom
        ? (_rangeFrom ?? _rangeTo ?? DateTime.now())
        : (_rangeTo ?? _rangeFrom ?? DateTime.now());
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      helpText: isFrom ? 'Range start' : 'Range end',
    );
    if (picked == null) return;
    setState(() {
      if (isFrom) {
        _rangeFrom = picked;
        // If From is after To, push To forward.
        if (_rangeTo != null && _rangeTo!.isBefore(picked)) _rangeTo = picked;
      } else {
        _rangeTo = picked;
        if (_rangeFrom != null && _rangeFrom!.isAfter(picked)) {
          _rangeFrom = picked;
        }
      }
    });
  }

  Future<void> _exportPdf(BuildContext context, AppProvider provider) async {
    setState(() {
      _loading = true;
      _viewMessage = null;
    });

    try {
      final bills = _scopedBills(provider);
      if (bills.isEmpty) {
        _setViewMessage('No bills to view for this selection.', error: true);
        return;
      }

      final (baseTitle, prefix) = switch (_pdfScope) {
        _PdfScope.all => ('All Bills', 'all'),
        _PdfScope.expected => ('Expected Bills', 'expected'),
        _PdfScope.scheduled => ('Scheduled Bills', 'scheduled'),
        _PdfScope.past => ('Past Bills', 'past'),
      };
      final title = (_rangeFrom == null && _rangeTo == null)
          ? baseTitle
          : '$baseTitle (${_rangeLabel()})';

      // Expected and Scheduled read most naturally in ascending due-date
      // order; Past and All stay descending (newest first).
      final ascending =
          _pdfScope == _PdfScope.expected || _pdfScope == _PdfScope.scheduled;
      final pdfBytes = await ExportService.buildPdfBytes(
        bills: bills,
        title: title,
        ascending: ascending,
      );
      final pdfName = 'billipod_${prefix}_${_ts()}.pdf';

      if (!context.mounted) return;
      // Open an on-screen preview of the actual PDF. Sharing is replaced
      // with an explicit Save action that prompts for a filename and
      // location; printing stays available.
      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => Scaffold(
            appBar: AppBar(title: Text(title)),
            body: PdfPreview(
              build: (_) async => pdfBytes,
              pdfFileName: pdfName,
              canChangePageFormat: false,
              canChangeOrientation: false,
              canDebug: false,
              allowSharing: false,
              actions: [
                PdfPreviewAction(
                  icon: const Icon(Icons.save_alt),
                  onPressed: (ctx, build, pageFormat) async {
                    final bytes = await build(pageFormat);
                    final msg = await ExportService.savePdfAs(bytes, pdfName);
                    if (msg == null || !mounted) return;
                    if (msg.startsWith('error:')) {
                      _setViewMessage(msg.substring(6), error: true);
                    } else {
                      _setViewMessage('Saved to $msg');
                    }
                  },
                ),
              ],
            ),
          ),
        ),
      );
      _setViewMessage(
        'Viewed ${bills.length} bill${bills.length == 1 ? '' : 's'} as PDF.',
      );
    } catch (e, st) {
      debugPrint('[View PDF] error: $e\n$st');
      _setViewMessage('PDF generation failed: $e', error: true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }
}

/// Which subset of bills the PDF export should include.
enum _PdfScope { all, expected, scheduled, past }
