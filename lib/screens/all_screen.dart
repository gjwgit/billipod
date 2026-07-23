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
import 'package:billipod/screens/bill_screen_mixin.dart';
import 'package:billipod/services/app_provider.dart';
import 'package:billipod/services/export_service.dart';
import 'package:billipod/widgets/bill_tile.dart';
import 'package:billipod/widgets/bill_total_bar.dart';
import 'package:billipod/widgets/source_toggle_bar.dart';
import 'package:billipod/widgets/startup_overlay.dart';

class AllScreen extends StatefulWidget {
  const AllScreen({super.key});

  @override
  State<AllScreen> createState() => _AllScreenState();
}

class _AllScreenState extends State<AllScreen> with BillScreenMixin<AllScreen> {
  final _search = TextEditingController();
  String _query = '';
  bool _loading = false;

  @override
  String get billQuery => _query;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  // ── Status-move actions ──────────────────────────────────────────────────
  //
  // Each group's tiles carry the same action buttons as the dedicated
  // Scheduled / Expected / Past screens. 20260724 gjw: added so the grouped
  // BILLS listing offers the same per-bill functions, not just delete.

  Future<void> _markPaid(
    BuildContext context,
    Bill bill,
    AppProvider provider, {
    String? sharedWebId,
  }) async {
    final paid = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Mark as paid?'),
        content: Text('Confirm payment of "${bill.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
    if (paid == true && context.mounted) {
      final updated = bill.copyWith(
        status: BillStatus.past,
        confirmedPaidDate: DateTime.now(),
      );
      if (sharedWebId != null) {
        await saveSharedOrError(
          context,
          () => provider.updateSharedBill(sharedWebId, updated),
        );
      } else {
        provider.updateBill(updated);
        await provider.saveToPod();
      }
    }
  }

  /// Own-bill action buttons for the given group.
  List<Widget> _ownActions(
    BuildContext context,
    AppProvider provider,
    Bill bill,
    String groupKey,
  ) {
    return switch (groupKey) {
      'Scheduled' => [
        duplicateAction(context, bill, provider),
        MarkdownTooltip(
          message:
              '**Mark as Paid**\n\nConfirm the payment, record the date of the confirmation, and change this bill to be a Past bill.',
          child: IconButton(
            icon: const Icon(Icons.check_circle_outline, size: 18),
            onPressed: () => _markPaid(context, bill, provider),
          ),
        ),
        MarkdownTooltip(
          message:
              '**Move back to Expected**\n\nReturn this bill to the Expected list.',
          child: IconButton(
            icon: const Icon(Icons.upcoming_outlined, size: 18),
            onPressed: () {
              provider.moveToStatus(bill.id, BillStatus.future);
              provider.saveToPod();
            },
          ),
        ),
      ],
      'Expected' => [
        duplicateAction(context, bill, provider),
        MarkdownTooltip(
          message:
              '**Move to Scheduled**\n\nMark this bill as scheduled'
              ' — payment has been arranged.',
          child: IconButton(
            icon: const Icon(Icons.schedule_send_outlined, size: 18),
            onPressed: () {
              provider.moveToStatus(bill.id, BillStatus.scheduled);
              provider.saveToPod();
            },
          ),
        ),
      ],
      _ => [duplicateAction(context, bill, provider)],
    };
  }

  /// Shared-editable action buttons for the given group.
  List<Widget> _sharedActions(
    BuildContext context,
    AppProvider provider,
    TaggedBill t,
    String groupKey,
  ) {
    return switch (groupKey) {
      'Scheduled' => [
        MarkdownTooltip(
          message:
              '**Mark as Paid**\n\nConfirm the payment, record the date of the confirmation, and change this bill to be a Past bill.',
          child: IconButton(
            icon: const Icon(Icons.check_circle_outline, size: 18),
            onPressed: () =>
                _markPaid(context, t.bill, provider, sharedWebId: t.ownerWebId),
          ),
        ),
        MarkdownTooltip(
          message:
              '**Move back to Expected**\n\nReturn this bill to the Expected list.',
          child: IconButton(
            icon: const Icon(Icons.upcoming_outlined, size: 18),
            onPressed: () => saveSharedOrError(
              context,
              () => provider.updateSharedBill(
                t.ownerWebId!,
                t.bill.copyWith(status: BillStatus.future),
              ),
            ),
          ),
        ),
      ],
      'Expected' => [
        MarkdownTooltip(
          message:
              '**Move to Scheduled**\n\nMark this bill as scheduled'
              ' — payment has been arranged.',
          child: IconButton(
            icon: const Icon(Icons.schedule_send_outlined, size: 18),
            onPressed: () => saveSharedOrError(
              context,
              () => provider.updateSharedBill(
                t.ownerWebId!,
                t.bill.copyWith(status: BillStatus.scheduled),
              ),
            ),
          ),
        ),
      ],
      _ => const [],
    };
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
      return sharedEditableTile(
        context,
        t,
        provider,
        outlineColor: outlineColor,
        additionalActions: _sharedActions(context, provider, t, groupKey),
      );
    }

    // Shared bill with read-only access.
    if (!t.isOwn) return sharedReadOnlyTile(t);

    // Own bill — full editing with the group's action buttons.
    final bill = t.bill;
    return BillTile(
      bill: bill,
      outlineColor: outlineColor,
      onTap: () => editBill(context, bill, provider),
      onDelete: () => confirmDelete(context, bill, provider),
      onStar: () {
        provider.updateBill(bill.copyWith(isStarred: !bill.isStarred));
        provider.saveToPod();
      },
      actions: _ownActions(context, provider, bill, groupKey),
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
    final phase = provider.startupPhase;

    if (provider.busy) {
      return StartupOverlay(phase: phase, child: const SizedBox.expand());
    }

    final tagged = filterTagged(provider.activeAllBills);
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
