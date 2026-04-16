/// BillTile — a single bill row in the list.
///
// Time-stamp: <2026-04-14>
///
/// Copyright (C) 2026, Togaware Pty Ltd
///
/// Licensed under the GNU General Public License, Version 3

library;

import 'package:flutter/material.dart';

import 'package:gap/gap.dart';
import 'package:intl/intl.dart';

import 'package:billipod/models/bill.dart';

class BillTile extends StatelessWidget {
  final Bill bill;
  final VoidCallback onTap;
  final VoidCallback onDelete;
  final List<Widget>? actions; // extra trailing actions (e.g. move buttons)

  const BillTile({
    super.key,
    required this.bill,
    required this.onTap,
    required this.onDelete,
    this.actions,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final overdue = bill.isOverdue;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(
          color: overdue ? cs.error : cs.outlineVariant,
          width: overdue ? 1.5 : 1,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Status icon ───────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Icon(
                  _statusIcon,
                  size: 20,
                  color: overdue ? cs.error : cs.primary,
                ),
              ),
              const Gap(10),
              // ── Content ───────────────────────────────────────────────────
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
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
                    const Gap(3),
                    Wrap(
                      spacing: 8,
                      runSpacing: 2,
                      children: [
                        if (bill.dueDate != null)
                          _chip(
                            context,
                            Icons.calendar_today_outlined,
                            _fmtDate(bill.dueDate!),
                            overdue
                                ? cs.errorContainer
                                : cs.surfaceContainerHighest,
                            overdue ? cs.onErrorContainer : cs.onSurfaceVariant,
                          ),
                        if (bill.frequency != BillFrequency.oneOff)
                          _chip(
                            context,
                            Icons.repeat,
                            bill.frequency.label,
                            cs.secondaryContainer,
                            cs.onSecondaryContainer,
                          ),
                        if (bill.paymentMethod != null)
                          _chip(
                            context,
                            Icons.payment_outlined,
                            bill.paymentMethod!,
                            cs.surfaceContainerHighest,
                            cs.onSurfaceVariant,
                          ),
                        if (bill.scheduledDate != null)
                          _chip(
                            context,
                            Icons.schedule_outlined,
                            'Scheduled ${_fmtDate(bill.scheduledDate!)}',
                            cs.tertiaryContainer,
                            cs.onTertiaryContainer,
                          ),
                        if (bill.notifiedDate != null)
                          _chip(
                            context,
                            Icons.notifications_outlined,
                            'Notified ${_fmtDate(bill.notifiedDate!)}',
                            cs.surfaceContainerHighest,
                            cs.onSurfaceVariant,
                          ),
                      ],
                    ),
                    if (bill.note != null && bill.note!.isNotEmpty) ...[
                      const Gap(4),
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
                  ],
                ),
              ),
              // ── Trailing ──────────────────────────────────────────────────
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ...?actions,
                  IconButton(
                    icon: const Icon(Icons.delete_outline, size: 18),
                    color: cs.error,
                    tooltip: 'Delete',
                    onPressed: onDelete,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData get _statusIcon => switch (bill.status) {
    BillStatus.future => Icons.upcoming_outlined,
    BillStatus.scheduled => Icons.schedule_send_outlined,
    BillStatus.past => Icons.check_circle_outline,
  };

  Widget _chip(
    BuildContext context,
    IconData icon,
    String label,
    Color bg,
    Color fg,
  ) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
    decoration: BoxDecoration(
      color: bg,
      borderRadius: BorderRadius.circular(4),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 11, color: fg),
        const Gap(3),
        Text(label, style: TextStyle(fontSize: 11, color: fg)),
      ],
    ),
  );

  String _fmtDate(DateTime d) => DateFormat('d MMM yyyy').format(d);
}
