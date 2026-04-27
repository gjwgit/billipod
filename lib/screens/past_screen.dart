/// PastScreen — bills that have been paid.
///
// Time-stamp: <2026-04-17>
///
/// Copyright (C) 2026, Togaware Pty Ltd
///
/// Licensed under the GNU General Public License, Version 3

library;

import 'package:flutter/material.dart';

import 'package:gap/gap.dart';
import 'package:markdown_tooltip/markdown_tooltip.dart';
import 'package:provider/provider.dart';

import 'package:billipod/models/bill.dart';
import 'package:billipod/pages/bill_edit.dart';
import 'package:billipod/services/app_provider.dart';
import 'package:billipod/services/export_service.dart';
import 'package:billipod/widgets/bill_tile.dart';
import 'package:billipod/widgets/duplicate_count_dialog.dart';

class PastScreen extends StatefulWidget {
  const PastScreen({super.key});

  @override
  State<PastScreen> createState() => _PastScreenState();
}

class _PastScreenState extends State<PastScreen> {
  final _search = TextEditingController();
  String _query = '';
  bool _loading = false;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  List<Bill> _filter(List<Bill> bills) {
    if (_query.isEmpty) return bills;
    final q = _query.toLowerCase();
    return bills
        .where(
          (b) =>
              b.title.toLowerCase().contains(q) ||
              (b.note?.toLowerCase().contains(q) ?? false) ||
              (b.paymentMethod?.toLowerCase().contains(q) ?? false) ||
              (b.notificationMethod?.toLowerCase().contains(q) ?? false) ||
              b.amountStr.contains(q),
        )
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final bills = _filter(provider.pastBills);
    final cs = Theme.of(context).colorScheme;

    if (provider.loading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _search,
                  decoration: InputDecoration(
                    hintText: 'Search bills…',
                    prefixIcon: const Icon(Icons.search, size: 20),
                    suffixIcon: _query.isEmpty
                        ? null
                        : IconButton(
                            icon: const Icon(Icons.clear, size: 18),
                            onPressed: () {
                              _search.clear();
                              setState(() => _query = '');
                            },
                          ),
                    isDense: true,
                    border: const OutlineInputBorder(),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                  ),
                  onChanged: (v) => setState(() => _query = v),
                ),
              ),
              const Gap(4),
              const MarkdownTooltip(
                message: '''

**Search tips**

- Plain text — searches title, note, payment method and amount
- Starred items show with a gold background
- Tap any bill to edit it

''',
                child: Icon(Icons.help_outline, size: 18),
              ),
              MarkdownTooltip(
                message: '**Add bill**\n\nAdd a new past bill.',
                child: IconButton(
                  icon: const Icon(Icons.add_circle_outline, size: 20),
                  onPressed: () => _addBill(context, provider, BillStatus.past),
                ),
              ),
              MarkdownTooltip(
                message:
                    '**Export PDF**\n\nSave or print these past bills as a PDF.',
                child: IconButton(
                  icon: const Icon(Icons.picture_as_pdf_outlined, size: 20),
                  onPressed: _loading
                      ? null
                      : () => _exportPdf(context, provider),
                ),
              ),
            ],
          ),
        ),
        if (bills.isEmpty)
          Expanded(
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.check_circle_outline,
                    size: 64,
                    color: cs.onSurfaceVariant.withValues(alpha: 0.3),
                  ),
                  const Gap(16),
                  Text(
                    _query.isEmpty
                        ? 'No paid bills yet.'
                        : 'No bills match "$_query".',
                    style: const TextStyle(fontSize: 16),
                  ),
                ],
              ),
            ),
          )
        else
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: bills.length,
              separatorBuilder: (_, _) => const Gap(8),
              itemBuilder: (_, i) {
                final bill = bills[i];
                return BillTile(
                  bill: bill,
                  onTap: () => _editBill(context, bill, provider),
                  onDelete: () => _confirmDelete(context, bill, provider),
                  onStar: () {
                    provider.updateBill(
                      bill.copyWith(isStarred: !bill.isStarred),
                    );
                    provider.saveToPod();
                  },
                  actions: [
                    MarkdownTooltip(
                      message:
                          '**Duplicate**\n\nCreate one or more copies of this bill,'
                          ' each advanced by one frequency cycle.',
                      child: IconButton(
                        icon: const Icon(Icons.copy_outlined, size: 18),
                        onPressed: () =>
                            _duplicateBill(context, bill, provider),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
      ],
    );
  }

  Future<void> _exportPdf(BuildContext context, AppProvider provider) async {
    setState(() => _loading = true);
    final messenger = ScaffoldMessenger.of(context);
    final err = await ExportService.exportPdf(
      context: context,
      bills: provider.pastBills,
      title: 'Past Bills',
      prefix: 'past',
    );
    if (mounted) {
      setState(() => _loading = false);
      if (err != null) {
        messenger.showSnackBar(
          SnackBar(content: Text('PDF export failed: $err')),
        );
      }
    }
  }

  Future<void> _addBill(
    BuildContext context,
    AppProvider provider,
    BillStatus defaultStatus,
  ) async {
    final bill = await showDialog<Bill>(
      context: context,
      barrierDismissible: false,
      builder: (_) => BillEdit(
        bill: Bill(
          title: _query.trim().isNotEmpty ? _query.trim() : 'New bill',
          status: defaultStatus,
        ),
      ),
    );
    if (bill != null && context.mounted) {
      provider.addBill(bill);
      await provider.saveToPod();
    }
  }

  Future<void> _duplicateBill(
    BuildContext context,
    Bill bill,
    AppProvider provider,
  ) async {
    final count = await showDialog<int>(
      context: context,
      builder: (ctx) => DuplicateCountDialog(bill: bill),
    );
    if (count == null || count < 1 || !context.mounted) return;

    DateTime? advance(DateTime? d, int cycles) {
      if (d == null) return null;
      var result = d;
      for (int i = 0; i < cycles; i++) {
        result = bill.nextDueDate(result) ?? result;
      }
      return result;
    }

    for (int i = 1; i <= count; i++) {
      provider.addBill(
        Bill(
          title: bill.title,
          amount: bill.amount,
          dueDate: advance(bill.dueDate, i),
          frequency: bill.frequency,
          status: BillStatus.future,
          notifiedDate: advance(bill.notifiedDate, i),
          notificationMethod: bill.notificationMethod,
          paymentMethod: bill.paymentMethod,
          note: bill.note,
          isTemplate: false,
          isAutoPaid: bill.isAutoPaid,
        ),
      );
    }
    await provider.saveToPod();
  }

  Future<void> _editBill(
    BuildContext context,
    Bill bill,
    AppProvider provider,
  ) async {
    final updated = await showDialog<Bill>(
      context: context,
      barrierDismissible: false,
      builder: (_) => BillEdit(bill: bill),
    );
    if (updated != null) {
      provider.updateBill(updated);
      await provider.saveToPod();
    }
  }

  Future<void> _confirmDelete(
    BuildContext context,
    Bill bill,
    AppProvider provider,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete bill?'),
        content: Text('Delete "${bill.title}"? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      provider.deleteBill(bill.id);
      await provider.saveToPod();
    }
  }
}
