/// SharedReadOnlyTile — a read-only bill card for bills from external PODs.
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

import 'package:gap/gap.dart';
import 'package:intl/intl.dart';

import 'package:billipod/models/bill.dart';

/// A compact read-only card for a bill sourced from another person's POD.
///
/// Shows title, amount, due date, note, and a footer labelled with
/// [sourceName] (the pod username of the person who shared the bill).

class SharedReadOnlyTile extends StatelessWidget {
  const SharedReadOnlyTile({
    required this.bill,
    required this.sourceName,
    super.key,
  });

  final Bill bill;
  final String sourceName;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final overdue = bill.isOverdue;

    return Card(
      elevation: 0,
      margin: const EdgeInsets.symmetric(horizontal: 0, vertical: 0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(
          color: overdue ? cs.error : cs.outlineVariant,
          width: overdue ? 1.5 : 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 10, 14, 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(_statusIcon, size: 20, color: overdue ? cs.error : cs.primary),
            const Gap(10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Title + amount ──────────────────────────────────────
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          bill.title,
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                            color: overdue ? cs.error : null,
                          ),
                        ),
                      ),
                      if (bill.amount != null)
                        Text(
                          bill.amountStr,
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                            color: overdue ? cs.error : cs.primary,
                          ),
                        ),
                    ],
                  ),

                  // ── Due date ────────────────────────────────────────────
                  if (bill.dueDate != null) ...[
                    const Gap(3),
                    Text(
                      DateFormat('d MMM yyyy').format(bill.dueDate!),
                      style: TextStyle(
                        fontSize: 12,
                        color: overdue ? cs.error : cs.onSurfaceVariant,
                      ),
                    ),
                  ],

                  // ── Note ───────────────────────────────────────────────
                  if (bill.note != null && bill.note!.isNotEmpty) ...[
                    const Gap(3),
                    Text(
                      bill.note!,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                  ],

                  // ── Owner label ─────────────────────────────────────────
                  const Gap(6),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.person_outline,
                        size: 11,
                        color: cs.onSurfaceVariant,
                      ),
                      const Gap(4),
                      Text(
                        sourceName,
                        style: TextStyle(
                          fontSize: 11,
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData get _statusIcon => switch (bill.status) {
    BillStatus.future => Icons.upcoming_outlined,
    BillStatus.scheduled => Icons.schedule_send_outlined,
    BillStatus.past => Icons.check_circle_outline,
  };
}
