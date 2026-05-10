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
import 'package:billipod/models/tagged_bill.dart';
import 'package:billipod/pages/bill_edit.dart';
import 'package:billipod/services/app_provider.dart';
import 'package:billipod/services/export_service.dart';
import 'package:billipod/widgets/bill_tile.dart';
import 'package:billipod/widgets/bill_total_bar.dart';
import 'package:billipod/widgets/duplicate_count_dialog.dart';
import 'package:billipod/widgets/shared_read_only_tile.dart';
import 'package:billipod/widgets/source_toggle_bar.dart';

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

  List<TaggedBill> _filterTagged(List<TaggedBill> tagged) {
    if (_query.isEmpty) return tagged;
    final q = _query.toLowerCase();
    return tagged
        .where(
          (t) =>
              t.bill.title.toLowerCase().contains(q) ||
              (t.bill.note?.toLowerCase().contains(q) ?? false) ||
              (t.bill.paymentMethod?.toLowerCase().contains(q) ?? false) ||
              t.bill.amountStr.contains(q),
        )
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final tagged = _filterTagged(provider.activePastBills);
    final bills = tagged.map((t) => t.bill).toList();
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
              if (provider.hasSharedSources) ...[
                const Flexible(
                  flex: 2,
                  fit: FlexFit.loose,
                  child: SourceToggleBar(),
                ),
                const SizedBox(width: 6),
              ],
              Expanded(
                flex: 3,
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
        BillTotalBar(bills: bills),
        if (tagged.isEmpty)
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
              itemCount: tagged.length,
              separatorBuilder: (_, _) => const Gap(8),
              itemBuilder: (_, i) {
                final t = tagged[i];
                if (!t.isOwn && t.canEdit) {
                  return BillTile(
                    bill: t.bill,
                    outlineColor: Colors.orange.withValues(alpha: 0.3),
                    onTap: () => _editSharedBill(context, t, provider),
                    onDelete: () => _confirmDelete(
                      context,
                      t.bill,
                      provider,
                      sharedWebId: t.ownerWebId,
                    ),
                    onStar: () => _saveSharedOrError(
                      context,
                      () => provider.updateSharedBill(
                        t.ownerWebId!,
                        t.bill.copyWith(isStarred: !t.bill.isStarred),
                      ),
                    ),
                    actions: [
                      // Owner label on the left of the action row.
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(left: 4),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.person_outline,
                                size: 11,
                                color: cs.onSurfaceVariant,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                t.sourceName!,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: cs.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      Builder(
                        builder: (ctx) {
                          final missing = !provider.hasFollowOnInSource(
                            t.ownerWebId!,
                            t.bill,
                          );
                          return MarkdownTooltip(
                            message: missing
                                ? '**No follow-on bill**\n\n'
                                      'There is no bill scheduled for the next '
                                      'frequency cycle. Tap to create one.'
                                : '**Duplicate**\n\nCreate one or more copies of '
                                      'this bill, each advanced by one frequency cycle.',
                            child: IconButton(
                              icon: Icon(
                                Icons.copy_outlined,
                                size: 18,
                                color: missing
                                    ? Colors.green
                                    : Colors.grey.withValues(alpha: 0.4),
                              ),
                              onPressed: () => _duplicateBill(
                                context,
                                t.bill,
                                provider,
                                sharedWebId: t.ownerWebId,
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  );
                }
                if (!t.isOwn) {
                  return SharedReadOnlyTile(
                    bill: t.bill,
                    sourceName: t.sourceName!,
                  );
                }
                final bill = t.bill;
                return BillTile(
                  bill: bill,
                  outlineColor: Colors.orange.withValues(alpha: 0.3),
                  onTap: () => _editBill(context, bill, provider),
                  onDelete: () => _confirmDelete(context, bill, provider),
                  onStar: () {
                    provider.updateBill(
                      bill.copyWith(isStarred: !bill.isStarred),
                    );
                    provider.saveToPod();
                  },
                  actions: [
                    Builder(
                      builder: (ctx) {
                        final missing = !provider.hasFollowOn(bill);
                        return MarkdownTooltip(
                          message: missing
                              ? '**No follow-on bill**\n\n'
                                    'There is no bill scheduled for the next '
                                    'frequency cycle. Tap to create one.'
                              : '**Duplicate**\n\nCreate one or more copies of '
                                    'this bill, each advanced by one frequency cycle.',
                          child: IconButton(
                            icon: Icon(
                              Icons.copy_outlined,
                              size: 18,
                              color: missing
                                  ? Colors.green
                                  : Colors.grey.withValues(alpha: 0.4),
                            ),
                            onPressed: () =>
                                _duplicateBill(context, bill, provider),
                          ),
                        );
                      },
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
    AppProvider provider, {
    String? sharedWebId,
  }) async {
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

    final newBills = <Bill>[];
    for (int i = 1; i <= count; i++) {
      newBills.add(
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
    if (sharedWebId != null) {
      await _saveSharedOrError(
        context,
        () => provider.addSharedBills(sharedWebId, newBills),
      );
    } else {
      for (final b in newBills) {
        provider.addBill(b);
      }
      await provider.saveToPod();
    }
  }

  Future<void> _saveSharedOrError(
    BuildContext context,
    Future<String?> Function() action, {
    String? successMessage,
  }) async {
    final err = await action();
    if (!context.mounted) return;
    if (err != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Save failed: $err')));
    } else if (successMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(successMessage),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _editSharedBill(
    BuildContext context,
    TaggedBill t,
    AppProvider provider,
  ) async {
    final updated = await showDialog<Bill>(
      context: context,
      barrierDismissible: false,
      builder: (_) => BillEdit(bill: t.bill),
    );
    if (updated != null) {
      await _saveSharedOrError(
        context,
        () => provider.updateSharedBill(t.ownerWebId!, updated),
        successMessage: "Changes saved to ${t.sourceName}'s POD.",
      );
    }
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
    AppProvider provider, {
    String? sharedWebId,
  }) async {
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
      if (sharedWebId != null) {
        await _saveSharedOrError(
          context,
          () => provider.deleteSharedBill(sharedWebId, bill.id),
        );
      } else {
        provider.deleteBill(bill.id);
        await provider.saveToPod();
      }
    }
  }
}
