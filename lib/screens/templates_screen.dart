/// TemplatesScreen — manage recurring bill templates.
///
// Time-stamp: <2026-04-14>
///
/// Copyright (C) 2026, Togaware Pty Ltd
///
/// Licensed under the GNU General Public License, Version 3

library;

import 'package:flutter/material.dart';

import 'package:gap/gap.dart';
import 'package:provider/provider.dart';

import 'package:billipod/models/bill.dart';
import 'package:billipod/pages/bill_edit.dart';
import 'package:billipod/services/app_provider.dart';
import 'package:billipod/widgets/bill_tile.dart';

class TemplatesScreen extends StatelessWidget {
  const TemplatesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final templates = provider.templateBills;

    if (templates.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.repeat,
              size: 64,
              color: Theme.of(context)
                  .colorScheme
                  .onSurfaceVariant
                  .withValues(alpha: 0.3),
            ),
            const Gap(16),
            const Text(
              'No recurring templates.',
              style: TextStyle(fontSize: 16),
            ),
            const Gap(8),
            Text(
              'Add a bill and mark it as a recurring template to\n'
              'auto-generate the next 12 months of instances.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: templates.length,
      separatorBuilder: (_, __) => const Gap(8),
      itemBuilder: (_, i) {
        final bill = templates[i];
        return BillTile(
          bill: bill,
          onTap: () => _editBill(context, bill, provider),
          onDelete: () => _confirmDelete(context, bill, provider),
        );
      },
    );
  }


  Future<void> _duplicateBill(
    BuildContext context,
    Bill bill,
    AppProvider provider,
  ) async {
    // Advance all dates by one payment cycle.
    DateTime? advanceDate(DateTime? d) {
      if (d == null) return null;
      return bill.nextDueDate(d) ?? d;
    }

    final copy = Bill(
      title: bill.title,
      amount: bill.amount,
      dueDate: advanceDate(bill.dueDate),
      frequency: bill.frequency,
      status: BillStatus.future,
      notifiedDate: advanceDate(bill.notifiedDate),
      notificationMethod: bill.notificationMethod,
      paymentMethod: bill.paymentMethod,
      scheduledDate: advanceDate(bill.scheduledDate),
      confirmedPaidDate: advanceDate(bill.confirmedPaidDate),
      note: bill.note,
      isTemplate: false,
    );
    final edited = await showDialog<Bill>(
      context: context,
      barrierDismissible: false,
      builder: (_) => BillEdit(bill: copy),
    );
    if (edited != null && context.mounted) {
      provider.addBill(edited);
      await provider.saveToPod();
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
    AppProvider provider,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete template?'),
        content: Text(
          'Delete "${bill.title}"?\n\n'
          'All auto-generated future instances will also be removed.',
        ),
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
