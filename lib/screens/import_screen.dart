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
}
