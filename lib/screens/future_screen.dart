/// FutureScreen — bills expected but not yet scheduled.
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

import 'package:billpod/models/bill.dart';
import 'package:billpod/pages/bill_edit.dart';
import 'package:billpod/services/app_provider.dart';
import 'package:billpod/widgets/bill_tile.dart';

class FutureScreen extends StatelessWidget {
  const FutureScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final bills = provider.futureBills;

    if (provider.loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (bills.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.upcoming_outlined,
              size: 64,
              color: Theme.of(context)
                  .colorScheme
                  .onSurfaceVariant
                  .withValues(alpha: 0.3),
            ),
            const Gap(16),
            const Text('No future bills.', style: TextStyle(fontSize: 16)),
            const Gap(8),
            Text(
              'Add a bill or recurring template to get started.',
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
      itemCount: bills.length,
      separatorBuilder: (_, __) => const Gap(8),
      itemBuilder: (_, i) {
        final bill = bills[i];
        return BillTile(
          bill: bill,
          onTap: () => _editBill(context, bill, provider),
          onDelete: () => _confirmDelete(context, bill, provider),
          actions: [
            IconButton(
              icon: const Icon(Icons.schedule_send_outlined, size: 18),
              tooltip: 'Move to Scheduled',
              onPressed: () {
                provider.moveToStatus(bill.id, BillStatus.scheduled);
                provider.saveToPod();
              },
            ),
          ],
        );
      },
    );
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
