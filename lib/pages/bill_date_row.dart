/// BillDateRow — a tappable date field row used in the bill editor.
///
/// Extracted from bill_edit.dart to keep that file within the project
/// line-count limit.
///
// Time-stamp: <2026-06-12>
///
/// Copyright (C) 2026, Togaware Pty Ltd
///
/// Licensed under the GNU General Public License, Version 3

library;

import 'package:flutter/material.dart';

import 'package:intl/intl.dart';

/// A read-only date display that opens a picker on tap, with a clear button
/// when a date is set.
class BillDateRow extends StatelessWidget {
  final String label;
  final DateTime? date;
  final VoidCallback onPick;
  final VoidCallback onClear;

  const BillDateRow({
    super.key,
    required this.label,
    required this.date,
    required this.onPick,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onPick,
      borderRadius: BorderRadius.circular(4),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          isDense: true,
          suffixIcon: date != null
              ? IconButton(
                  icon: const Icon(Icons.clear, size: 16),
                  onPressed: onClear,
                )
              : const Icon(Icons.calendar_today_outlined, size: 16),
        ),
        child: Text(
          date != null ? DateFormat('d MMM yyyy').format(date!) : '—',
          style: TextStyle(color: date != null ? null : cs.onSurfaceVariant),
        ),
      ),
    );
  }
}
