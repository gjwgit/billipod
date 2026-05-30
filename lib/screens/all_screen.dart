/// AllScreen — every bill grouped by status.
///
// Time-stamp: <2026-05-03>
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
import 'package:billipod/widgets/shared_read_only_tile.dart';
import 'package:billipod/widgets/source_toggle_bar.dart';

class AllScreen extends StatefulWidget {
  const AllScreen({super.key});

  @override
  State<AllScreen> createState() => _AllScreenState();
}

class _AllScreenState extends State<AllScreen> {
  final _search = TextEditingController();
  String _query = '';
  bool _loading = false;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
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

  Widget _tileFor(
    BuildContext context,
    AppProvider provider,
    TaggedBill t,
    String groupKey,
  ) {
    final outlineColor = switch (groupKey) {
      'Scheduled' => Colors.green.withValues(alpha: 0.6),
      'Past' => Colors.orange.withValues(alpha: 0.3),
      _ => null,
    };

    // Shared bill with write access — editable, saves back to their POD.
    if (!t.isOwn && t.canEdit) {
      final cs = Theme.of(context).colorScheme;
      return BillTile(
        bill: t.bill,
        outlineColor: outlineColor,
        onTap: () async {
          final updated = await showDialog<Bill>(
            context: context,
            barrierDismissible: false,
            builder: (_) => BillEdit(bill: t.bill),
          );
          if (updated != null) {
            final err = await provider.updateSharedBill(t.ownerWebId!, updated);
            if (err != null && context.mounted) {
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(SnackBar(content: Text('Save failed: $err')));
            }
          }
        },
        actions: [
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
                    style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant),
                  ),
                ],
              ),
            ),
          ),
        ],
        onDelete: () async {
          final confirmed = await showDialog<bool>(
            context: context,
            builder: (ctx) => AlertDialog(
              title: const Text('Delete bill?'),
              content: Text('"${t.bill.title}" will be removed.'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  child: const Text('Delete'),
                ),
              ],
            ),
          );
          if (confirmed == true) {
            final err = await provider.deleteSharedBill(
              t.ownerWebId!,
              t.bill.id,
            );
            if (err != null && context.mounted) {
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(SnackBar(content: Text('Delete failed: $err')));
            }
          }
        },
      );
    }

    // Shared bill with read-only access.
    if (!t.isOwn) {
      return SharedReadOnlyTile(bill: t.bill, sourceName: t.sourceName!);
    }

    // Own bill — full editing.
    return BillTile(
      bill: t.bill,
      outlineColor: outlineColor,
      onTap: () => _editBill(context, provider, t.bill),
      onDelete: () => _deleteBill(context, provider, t.bill),
    );
  }

  Future<void> _addBill(BuildContext context, AppProvider provider) async {
    final bill = await showDialog<Bill>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const BillEdit(),
    );
    if (bill != null) {
      provider.addBill(bill);
      await provider.saveToPod();
    }
  }

  Future<void> _editBill(
    BuildContext context,
    AppProvider provider,
    Bill bill,
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

  Future<void> _deleteBill(
    BuildContext context,
    AppProvider provider,
    Bill bill,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete bill?'),
        content: Text('"${bill.title}" will be permanently removed.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
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

  Future<void> _exportPdf(BuildContext context, AppProvider provider) async {
    setState(() => _loading = true);
    final messenger = ScaffoldMessenger.of(context);
    final bills = provider.activeAllBills.map((t) => t.bill).toList();
    final err = await ExportService.previewPdf(
      bills: bills,
      title: 'All Bills',
      prefix: 'all',
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

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final cs = Theme.of(context).colorScheme;

    if (provider.loading) {
      return const Center(child: CircularProgressIndicator());
    }

    final tagged = _filterTagged(provider.activeAllBills);
    final all = tagged.map((t) => t.bill).toList();

    // Group by status label.
    final groups = <String, List<TaggedBill>>{
      'Scheduled': [],
      'Expected': [],
      'Past': [],
    };
    for (final t in tagged) {
      switch (t.bill.status) {
        case BillStatus.scheduled:
          groups['Scheduled']!.add(t);
        case BillStatus.future:
          groups['Expected']!.add(t);
        case BillStatus.past:
          groups['Past']!.add(t);
      }
    }

    return Column(
      children: [
        // ── Search bar + add button ─────────────────────────────────
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
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                    contentPadding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                  onChanged: (v) => setState(() => _query = v),
                ),
              ),
              const Gap(8),
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
                message: '**Add bill**\n\nCreate a new bill.',
                child: IconButton(
                  icon: const Icon(Icons.add_circle_outline, size: 20),
                  onPressed: () => _addBill(context, provider),
                ),
              ),
              MarkdownTooltip(
                message: '**Export PDF**\n\nSave or print all bills as a PDF.',
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
        const Gap(8),
        BillTotalBar(bills: all, label: 'All'),

        // ── Grouped bill list ───────────────────────────────────────
        Expanded(
          child: all.isEmpty
              ? Center(
                  child: Text(
                    _query.isEmpty
                        ? 'No bills yet.'
                        : 'No bills match "$_query".',
                    style: TextStyle(color: cs.onSurfaceVariant),
                  ),
                )
              : ListView(
                  padding: const EdgeInsets.only(bottom: 16),
                  children: [
                    for (final entry in groups.entries)
                      if (entry.value.isNotEmpty) ...[
                        _GroupHeader(
                          label: entry.key,
                          count: entry.value.length,
                          cs: cs,
                        ),
                        for (final t in entry.value)
                          _tileFor(context, provider, t, entry.key),
                      ],
                  ],
                ),
        ),
      ],
    );
  }
}

// ── Group header ──────────────────────────────────────────────────────────────

class _GroupHeader extends StatelessWidget {
  final String label;
  final int count;
  final ColorScheme cs;

  const _GroupHeader({
    required this.label,
    required this.count,
    required this.cs,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Row(
        children: [
          Text(
            label.toUpperCase(),
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.8,
              color: cs.primary,
            ),
          ),
          const Gap(8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
            decoration: BoxDecoration(
              color: cs.primaryContainer,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '$count',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: cs.onPrimaryContainer,
              ),
            ),
          ),
          const Gap(8),
          Expanded(child: Divider(color: cs.outlineVariant, height: 1)),
        ],
      ),
    );
  }
}
