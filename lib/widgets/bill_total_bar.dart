/// BillTotalBar — shows the summed total of a filtered list of bills.
///
// Time-stamp: <2026-05-03>
///
/// Copyright (C) 2026, Togaware Pty Ltd
///
/// Licensed under the GNU General Public License, Version 3

library;

import 'package:flutter/material.dart';

import 'package:intl/intl.dart';

import 'package:billipod/models/bill.dart';

class BillTotalBar extends StatelessWidget {
  final List<Bill> bills;
  final String? label;

  const BillTotalBar({super.key, required this.bills, this.label});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final total = bills.fold<double>(
      0,
      (sum, b) => sum + (b.amount ?? 0) + (b.transactionFee ?? 0),
    );
    final fmt = NumberFormat('#,##0.00');
    final count = bills.length;
    final plural = count == 1 ? 'bill' : 'bills';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      color: cs.surfaceContainerLow,
      child: Row(
        children: [
          Text(
            label != null ? '$label: ' : '',
            style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
          ),
          Text(
            '$count $plural',
            style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
          ),
          const Spacer(),
          if (total > 0)
            Text(
              'Total  \$${fmt.format(total)}',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: cs.primary,
              ),
            ),
        ],
      ),
    );
  }
}
