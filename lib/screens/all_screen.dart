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
import 'package:billipod/pages/bill_edit.dart';
import 'package:billipod/services/app_provider.dart';
import 'package:billipod/widgets/bill_tile.dart';

class AllScreen extends StatefulWidget {
  const AllScreen({super.key});

  @override
  State<AllScreen> createState() => _AllScreenState();
}

class _AllScreenState extends State<AllScreen> {
  final _search = TextEditingController();
  String _query = '';

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
              b.amountStr.contains(q),
        )
        .toList();
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

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final cs = Theme.of(context).colorScheme;

    if (provider.loading) {
      return const Center(child: CircularProgressIndicator());
    }

    final all = _filter(provider.allBills);

    // Group by status label.
    final groups = <String, List<Bill>>{
      'Scheduled': [],
      'Expected': [],
      'Past': [],
    };
    for (final b in all) {
      switch (b.status) {
        case BillStatus.scheduled:
          groups['Scheduled']!.add(b);
        case BillStatus.future:
          groups['Expected']!.add(b);
        case BillStatus.past:
          groups['Past']!.add(b);
      }
    }

    return Column(
      children: [
        // ── Search bar + add button ─────────────────────────────────
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
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                    contentPadding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                  onChanged: (v) => setState(() => _query = v),
                ),
              ),
              const Gap(8),
              MarkdownTooltip(
                message: '**Add bill**\n\nCreate a new bill.',
                child: IconButton(
                  icon: const Icon(Icons.add_circle_outline),
                  color: cs.primary,
                  onPressed: () => _addBill(context, provider),
                ),
              ),
            ],
          ),
        ),
        const Gap(8),

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
                        for (final bill in entry.value)
                          BillTile(
                            bill: bill,
                            outlineColor: switch (entry.key) {
                              'Scheduled' => Colors.green.withValues(
                                alpha: 0.6,
                              ),
                              'Past' => Colors.orange.withValues(alpha: 0.3),
                              _ => null,
                            },
                            onTap: () => _editBill(context, provider, bill),
                            onDelete: () =>
                                _deleteBill(context, provider, bill),
                          ),
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
