/// ImportScreen — import from JSON and export to JSON and PDF.
///
// Time-stamp: <Monday 2026-04-20 14:08:12 +1000 Graham Williams>
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
  String? _importMessage;
  bool _importError = false;
  String? _exportMessage;
  bool _exportError = false;

  /// Which subset of bills to include when exporting to PDF.
  _PdfScope _pdfScope = _PdfScope.all;

  /// Optional date-range filter applied on top of the scope. When null on a
  /// side, that side is unbounded.
  DateTime? _rangeFrom;
  DateTime? _rangeTo;

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

    return Align(
      alignment: Alignment.topLeft,
      child: SingleChildScrollView(
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

            // ── PDF Export ──────────────────────────────────────────────
            const Gap(24),
            Text(
              'Choose which bills to include, then export to PDF. '
              'Optionally restrict to a date range based on due dates.',
              style: TextStyle(color: cs.onSurfaceVariant),
            ),
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
              title: 'Export to PDF',
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
      _importMessage = null;
    });

    try {
      final result = await FilePicker.pickFiles(
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

      final savePath = await FilePicker.saveFile(
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

  /// Bills covered by the currently-selected scope AND date range.
  List<Bill> _scopedBills(AppProvider provider) {
    final List<Bill> base = switch (_pdfScope) {
      _PdfScope.all => provider.allBills.where((b) => !b.isTemplate).toList(),
      _PdfScope.expected => provider.futureBills,
      _PdfScope.scheduled => provider.scheduledBills,
      _PdfScope.past => provider.pastBills,
    };
    if (_rangeFrom == null && _rangeTo == null) return base;
    // Normalize bounds: From at start of day, To at end of day, so a bill
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
      _exportMessage = null;
    });

    try {
      final bills = _scopedBills(provider);
      if (bills.isEmpty) {
        _setExportMessage(
          'No bills to export for this selection.',
          error: true,
        );
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

      if (!context.mounted) return;
      final messenger = ScaffoldMessenger.of(context);
      final result = await ExportService.exportPdf(
        bills: bills,
        title: title,
        prefix: prefix,
      );
      if (result.error != null) {
        _setExportMessage('PDF export failed: ${result.error}', error: true);
      } else if (result.savePath != null) {
        _setExportMessage(
          'Saved ${bills.length} bill${bills.length == 1 ? '' : 's'} to PDF.',
        );
        // Offer to view the saved file via a SnackBar action.
        final savedPath = result.savePath!;
        messenger.showSnackBar(
          SnackBar(
            content: const Text('PDF saved.'),
            action: SnackBarAction(
              label: 'View',
              onPressed: () async {
                final openErr = await ExportService.openSavedPdf(savedPath);
                if (openErr != null && mounted) {
                  messenger.showSnackBar(
                    SnackBar(content: Text('Could not open: $openErr')),
                  );
                }
              },
            ),
            duration: const Duration(seconds: 6),
          ),
        );
      }
      // result.savePath == null with no error → user cancelled the save
      // dialog; leave _exportMessage as-is.
    } catch (e, st) {
      debugPrint('[Export PDF] error: $e\n$st');
      _setExportMessage('Export failed: $e', error: true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }
}

/// Which subset of bills the PDF export should include.
enum _PdfScope { all, expected, scheduled, past }
