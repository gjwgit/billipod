/// ScheduledScreen — bills with a scheduled payment date.
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
import 'package:billipod/screens/bill_screen_mixin.dart';
import 'package:billipod/services/app_provider.dart';
import 'package:billipod/services/export_service.dart';
import 'package:billipod/widgets/bill_tile.dart';
import 'package:billipod/widgets/bill_total_bar.dart';
import 'package:billipod/widgets/source_toggle_bar.dart';

class ScheduledScreen extends StatefulWidget {
  const ScheduledScreen({super.key});

  @override
  State<ScheduledScreen> createState() => _ScheduledScreenState();
}

class _ScheduledScreenState extends State<ScheduledScreen>
    with BillScreenMixin<ScheduledScreen> {
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

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final tagged = filterTagged(provider.activeScheduledBills);
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
                message: '**Add bill**\n\nAdd a new scheduled bill.',
                child: IconButton(
                  icon: const Icon(Icons.add_circle_outline, size: 20),
                  onPressed: () =>
                      addBill(context, provider, BillStatus.scheduled),
                ),
              ),
              MarkdownTooltip(
                message:
                    '**Export PDF**\n\nSave or print these scheduled bills as a PDF.',
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
                    Icons.schedule_send_outlined,
                    size: 64,
                    color: cs.onSurfaceVariant.withValues(alpha: 0.3),
                  ),
                  const Gap(16),
                  Text(
                    _query.isEmpty
                        ? 'No scheduled payments.'
                        : 'No bills match "$_query".',
                    style: const TextStyle(fontSize: 16),
                  ),
                  if (_query.isEmpty) ...[
                    const Gap(8),
                    Text(
                      'Move a future bill here once payment has been scheduled.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: cs.onSurfaceVariant),
                    ),
                  ],
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
                final outlineColor = t.bill.isOverdue
                    ? null
                    : Colors.green.withValues(alpha: 0.6);

                if (!t.isOwn && t.canEdit) {
                  return sharedEditableTile(
                    context,
                    t,
                    provider,
                    outlineColor: outlineColor,
                    additionalActions: [
                      MarkdownTooltip(
                        message:
                            '**Mark as Paid**\n\nConfirm payment and move this bill to Past.',
                        child: IconButton(
                          icon: const Icon(
                            Icons.check_circle_outline,
                            size: 18,
                          ),
                          onPressed: () => _markPaid(
                            context,
                            t.bill,
                            provider,
                            sharedWebId: t.ownerWebId,
                          ),
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
                  );
                }

                if (!t.isOwn) return sharedReadOnlyTile(t);

                final bill = t.bill;
                return BillTile(
                  bill: bill,
                  outlineColor: outlineColor,
                  onTap: () => editBill(context, bill, provider),
                  onDelete: () => confirmDelete(context, bill, provider),
                  onStar: () {
                    provider.updateBill(
                      bill.copyWith(isStarred: !bill.isStarred),
                    );
                    provider.saveToPod();
                  },
                  actions: [
                    duplicateAction(context, bill, provider),
                    MarkdownTooltip(
                      message:
                          '**Mark as Paid**\n\nConfirm payment and move this bill to Past.',
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
                );
              },
            ),
          ),
      ],
    );
  }

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

  Future<void> _exportPdf(BuildContext context, AppProvider provider) async {
    setState(() => _loading = true);
    final messenger = ScaffoldMessenger.of(context);
    final err = await ExportService.exportPdf(
      context: context,
      bills: provider.scheduledBills,
      title: 'Scheduled Bills',
      prefix: 'scheduled',
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
}
