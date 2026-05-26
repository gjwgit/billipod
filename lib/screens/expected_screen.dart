/// ExpectedScreen — bills expected but not yet scheduled.
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

class ExpectedScreen extends StatefulWidget {
  const ExpectedScreen({super.key});

  @override
  State<ExpectedScreen> createState() => _ExpectedScreenState();
}

class _ExpectedScreenState extends State<ExpectedScreen>
    with BillScreenMixin<ExpectedScreen> {
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
    final tagged = filterTagged(provider.activeFutureBills);
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
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                    contentPadding: const EdgeInsets.symmetric(vertical: 10),
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
                message: '**Add bill**\n\nAdd a new future bill.',
                child: IconButton(
                  icon: const Icon(Icons.add_circle_outline, size: 20),
                  onPressed: () =>
                      addBill(context, provider, BillStatus.future),
                ),
              ),
              MarkdownTooltip(
                message:
                    '**Export PDF**\n\nSave or print these expected bills as a PDF.',
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
                    Icons.upcoming_outlined,
                    size: 64,
                    color: cs.onSurfaceVariant.withValues(alpha: 0.3),
                  ),
                  const Gap(16),
                  Text(
                    _query.isEmpty
                        ? 'No future bills.'
                        : 'No bills match "$_query".',
                    style: const TextStyle(fontSize: 16),
                  ),
                  if (_query.isEmpty) ...[
                    const Gap(8),
                    Text(
                      'Add a bill to get started.',
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

                if (!t.isOwn && t.canEdit) {
                  return sharedEditableTile(
                    context,
                    t,
                    provider,
                    additionalActions: [
                      MarkdownTooltip(
                        message:
                            '**Move to Scheduled**\n\nMark this bill as scheduled'
                            ' — payment has been arranged.',
                        child: IconButton(
                          icon: const Icon(
                            Icons.schedule_send_outlined,
                            size: 18,
                          ),
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
                  );
                }

                if (!t.isOwn) return sharedReadOnlyTile(t);

                final bill = t.bill;
                return BillTile(
                  bill: bill,
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
                          '**Move to Scheduled**\n\nMark this bill as scheduled'
                          ' — payment has been arranged.',
                      child: IconButton(
                        icon: const Icon(
                          Icons.schedule_send_outlined,
                          size: 18,
                        ),
                        onPressed: () {
                          provider.moveToStatus(bill.id, BillStatus.scheduled);
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

  Future<void> _exportPdf(BuildContext context, AppProvider provider) async {
    setState(() => _loading = true);
    final messenger = ScaffoldMessenger.of(context);
    final err = await ExportService.previewPdf(
      bills: provider.futureBills,
      title: 'Expected Bills',
      prefix: 'expected',
      ascending: true,
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
