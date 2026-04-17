/// DuplicateCountDialog — ask how many copies to duplicate a bill into.
///
// Time-stamp: <2026-04-17>
///
/// Copyright (C) 2026, Togaware Pty Ltd
///
/// Licensed under the GNU General Public License, Version 3

library;

import 'package:flutter/material.dart';

import 'package:gap/gap.dart';

import 'package:billipod/models/bill.dart';

class DuplicateCountDialog extends StatefulWidget {
  final Bill bill;
  const DuplicateCountDialog({super.key, required this.bill});

  @override
  State<DuplicateCountDialog> createState() => _DuplicateCountDialogState();
}

class _DuplicateCountDialogState extends State<DuplicateCountDialog> {
  int _count = 1;

  String get _frequencyLabel => widget.bill.frequency == BillFrequency.oneOff
      ? 'copy'
      : '${widget.bill.frequency.label.toLowerCase()} cycle';

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Duplicate bill'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'How many copies of "${widget.bill.title}"?',
            style: const TextStyle(fontSize: 14),
          ),
          if (widget.bill.frequency != BillFrequency.oneOff) ...[
            const Gap(4),
            Text(
              'Each copy advances dates by one $_frequencyLabel.',
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
          const Gap(16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.remove_circle_outline),
                onPressed: _count > 1 ? () => setState(() => _count--) : null,
              ),
              const Gap(8),
              SizedBox(
                width: 48,
                child: Text(
                  '$_count',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
              ),
              const Gap(8),
              IconButton(
                icon: const Icon(Icons.add_circle_outline),
                onPressed: _count < 24 ? () => setState(() => _count++) : null,
              ),
            ],
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, _count),
          child: Text('Create $_count ${_count == 1 ? 'copy' : 'copies'}'),
        ),
      ],
    );
  }
}
