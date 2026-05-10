/// BillScreenMixin — shared logic for Scheduled, Expected and Past screens.
///
// Time-stamp: <2026-05-10>
///
/// Copyright (C) 2026, Togaware Pty Ltd
///
/// Licensed under the GNU General Public License, Version 3 (the "License");
///
/// License: https://opensource.org/license/gpl-3-0

library;

import 'package:flutter/material.dart';

import 'package:markdown_tooltip/markdown_tooltip.dart';
import 'package:provider/provider.dart';

import 'package:billipod/models/bill.dart';
import 'package:billipod/models/tagged_bill.dart';
import 'package:billipod/pages/bill_edit.dart';
import 'package:billipod/services/app_provider.dart';
import 'package:billipod/widgets/bill_tile.dart';
import 'package:billipod/widgets/duplicate_count_dialog.dart';
import 'package:billipod/widgets/shared_read_only_tile.dart';

/// Mixin applied to the State classes of Scheduled, Expected and Past screens.
///
/// Provides the common search-filter, CRUD, and shared-bill methods so they
/// only need to be written once. Each screen must implement [billQuery] to
/// expose its current search query string.

mixin BillScreenMixin<T extends StatefulWidget> on State<T> {
  /// The screen's current search query — overridden by each screen's state.
  String get billQuery;

  // ── Filtering ──────────────────────────────────────────────────────────────

  List<Bill> filterBills(List<Bill> bills) {
    if (billQuery.isEmpty) return bills;
    final q = billQuery.toLowerCase();
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

  List<TaggedBill> filterTagged(List<TaggedBill> tagged) {
    if (billQuery.isEmpty) return tagged;
    final q = billQuery.toLowerCase();
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

  // ── Shared-bill helpers ────────────────────────────────────────────────────

  /// Runs [action]; shows a snackbar on failure or, optionally, on success.
  Future<void> saveSharedOrError(
    BuildContext context,
    Future<String?> Function() action, {
    String? successMessage,
  }) async {
    final err = await action();
    if (!context.mounted) return;
    if (err != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Save failed: $err')),
      );
    } else if (successMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            successMessage,
            style: const TextStyle(color: Colors.white),
          ),
          backgroundColor: Colors.green.shade600,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> editSharedBill(
    BuildContext context,
    TaggedBill t,
    AppProvider provider,
  ) async {
    final updated = await showDialog<Bill>(
      context: context,
      barrierDismissible: false,
      builder: (_) => BillEdit(bill: t.bill),
    );
    if (updated != null && context.mounted) {
      await saveSharedOrError(
        context,
        () => provider.updateSharedBill(t.ownerWebId!, updated),
        successMessage: "Changes saved to ${t.sourceName}'s POD.",
      );
    }
  }

  // ── Own-bill helpers ───────────────────────────────────────────────────────

  Future<void> editBill(
    BuildContext context,
    Bill bill,
    AppProvider provider,
  ) async {
    final updated = await showDialog<Bill>(
      context: context,
      barrierDismissible: false,
      builder: (_) => BillEdit(bill: bill),
    );
    if (updated != null && context.mounted) {
      provider.updateBill(updated);
      await provider.saveToPod();
    }
  }

  Future<void> confirmDelete(
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
    if (confirmed == true && context.mounted) {
      if (sharedWebId != null) {
        await saveSharedOrError(
          context,
          () => provider.deleteSharedBill(sharedWebId, bill.id),
        );
      } else {
        provider.deleteBill(bill.id);
        await provider.saveToPod();
      }
    }
  }

  Future<void> duplicateBill(
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

    final newBills = <Bill>[
      for (int i = 1; i <= count; i++)
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
    ];

    if (sharedWebId != null) {
      await saveSharedOrError(
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

  Future<void> addBill(
    BuildContext context,
    AppProvider provider,
    BillStatus defaultStatus,
  ) async {
    final bill = await showDialog<Bill>(
      context: context,
      barrierDismissible: false,
      builder: (_) => BillEdit(
        bill: Bill(
          title: billQuery.trim().isNotEmpty ? billQuery.trim() : 'New bill',
          status: defaultStatus,
        ),
      ),
    );
    if (bill != null && context.mounted) {
      provider.addBill(bill);
      await provider.saveToPod();
    }
  }

  // ── Widget builders ────────────────────────────────────────────────────────

  /// Small owner label widget — placed as first entry in BillTile actions so
  /// the pod username floats left while the action buttons stay right.
  Widget ownerLabel(BuildContext context, String sourceName) {
    final cs = Theme.of(context).colorScheme;
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.only(left: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.person_outline, size: 11, color: cs.onSurfaceVariant),
            const SizedBox(width: 4),
            Text(
              sourceName,
              style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }

  /// Builds the BillTile for a shared bill the user has write access to.
  ///
  /// [additionalActions] are the screen-specific buttons (mark paid, move
  /// status, etc.) appended after the duplicate button.
  Widget sharedEditableTile(
    BuildContext context,
    TaggedBill t,
    AppProvider provider, {
    Color? outlineColor,
    List<Widget> additionalActions = const [],
  }) {
    final appProvider = context.read<AppProvider>();
    return BillTile(
      bill: t.bill,
      outlineColor: outlineColor,
      onTap: () => editSharedBill(context, t, provider),
      onDelete: () =>
          confirmDelete(context, t.bill, provider, sharedWebId: t.ownerWebId),
      onStar: () => saveSharedOrError(
        context,
        () => appProvider.updateSharedBill(
          t.ownerWebId!,
          t.bill.copyWith(isStarred: !t.bill.isStarred),
        ),
      ),
      actions: [
        ownerLabel(context, t.sourceName!),
        Builder(
          builder: (ctx) {
            final missing =
                !provider.hasFollowOnInSource(t.ownerWebId!, t.bill);
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
                onPressed: () => duplicateBill(
                  context,
                  t.bill,
                  provider,
                  sharedWebId: t.ownerWebId,
                ),
              ),
            );
          },
        ),
        ...additionalActions,
      ],
    );
  }

  /// Builds a read-only tile for a shared bill without write access.
  Widget sharedReadOnlyTile(TaggedBill t) =>
      SharedReadOnlyTile(bill: t.bill, sourceName: t.sourceName!);

  /// Builds the duplicate action button for own bills.
  Widget duplicateAction(
    BuildContext context,
    Bill bill,
    AppProvider provider,
  ) {
    return Builder(
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
              color:
                  missing ? Colors.green : Colors.grey.withValues(alpha: 0.4),
            ),
            onPressed: () => duplicateBill(context, bill, provider),
          ),
        );
      },
    );
  }
}
