/// BillScheduleFields — the dates, methods and auto-paid inputs for the
/// bill editor.
///
/// Extracted from bill_edit.dart to keep that file within the project
/// line-count limit.
///
// Time-stamp: <2026-08-08>
///
/// Copyright (C) 2026, Togaware Pty Ltd
///
/// Licensed under the GNU General Public License, Version 3

library;

import 'package:flutter/material.dart';

import 'package:gap/gap.dart';
import 'package:markdown_tooltip/markdown_tooltip.dart';

import 'package:billipod/constants/app.dart';
import 'package:billipod/pages/bill_date_row.dart';

/// The notified/scheduled/due/confirmed-paid dates, the notification and
/// payment methods, and the auto-paid checkbox.
///
/// The editor keeps ownership of the values: each input reports its new value
/// through a callback so the editor can apply its own status promotion rules.
class BillScheduleFields extends StatelessWidget {
  final DateTime? notifiedDate;
  final String? notificationMethod;
  final String? paymentMethod;
  final bool isAutoPaid;
  final DateTime? scheduledDate;
  final DateTime? dueDate;
  final DateTime? confirmedPaidDate;

  /// Opens a date picker seeded with the supplied date.
  final Future<DateTime?> Function(DateTime?) pickDate;

  final ValueChanged<DateTime?> onNotifiedDate;
  final ValueChanged<String?> onNotificationMethod;
  final ValueChanged<String?> onPaymentMethod;
  final ValueChanged<bool> onAutoPaid;
  final ValueChanged<DateTime?> onScheduledDate;
  final ValueChanged<DateTime?> onDueDate;
  final ValueChanged<DateTime?> onConfirmedPaidDate;

  const BillScheduleFields({
    super.key,
    required this.notifiedDate,
    required this.notificationMethod,
    required this.paymentMethod,
    required this.isAutoPaid,
    required this.scheduledDate,
    required this.dueDate,
    required this.confirmedPaidDate,
    required this.pickDate,
    required this.onNotifiedDate,
    required this.onNotificationMethod,
    required this.onPaymentMethod,
    required this.onAutoPaid,
    required this.onScheduledDate,
    required this.onDueDate,
    required this.onConfirmedPaidDate,
  });

  /// A date row that reports the picked date, or null when cleared.
  Widget _dateRow(String label, DateTime? date, ValueChanged<DateTime?> onSet) {
    return BillDateRow(
      label: label,
      date: date,
      onPick: () async {
        final d = await pickDate(date);
        if (d != null) onSet(d);
      },
      onClear: () => onSet(null),
    );
  }

  /// A method dropdown with a leading '—' entry meaning "not set".
  Widget _methodField(
    String label,
    String? value,
    List<String> options,
    ValueChanged<String?> onChanged,
  ) {
    return DropdownButtonFormField<String?>(
      initialValue: value,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        isDense: true,
      ),
      items: [
        const DropdownMenuItem(value: null, child: Text('—')),
        ...options.map((m) => DropdownMenuItem(value: m, child: Text(m))),
      ],
      onChanged: onChanged,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Notified date + method
        _dateRow('Notified date', notifiedDate, onNotifiedDate),
        const Gap(8),
        _methodField(
          'Notification method',
          notificationMethod,
          notificationMethods,
          onNotificationMethod,
        ),
        const Gap(12),
        // Payment method
        _methodField(
          'Payment method',
          paymentMethod,
          paymentMethods,
          onPaymentMethod,
        ),
        const Gap(8),
        // Payment type checkboxes
        MarkdownTooltip(
          message: '''

**Auto-paid**

Check this if the payment is made automatically, for example
by credit card direct debit or bank auto-payment.

The bill will show an **Auto-paid** chip in the listing.

''',
          child: CheckboxListTile(
            value: isAutoPaid,
            onChanged: (v) => onAutoPaid(v ?? false),
            title: const Text('Auto-paid'),
            subtitle: const Text(
              'Payment is made automatically (e.g. credit card direct debit).',
            ),
            controlAffinity: ListTileControlAffinity.leading,
            contentPadding: EdgeInsets.zero,
            dense: true,
          ),
        ),
        const Gap(8),
        // Scheduled date
        _dateRow('Scheduled date', scheduledDate, onScheduledDate),
        const Gap(8),
        // Due date
        _dateRow('Due date', dueDate, onDueDate),
        const Gap(8),
        // Confirmed paid date
        _dateRow('Confirmed paid date', confirmedPaidDate, onConfirmedPaidDate),
      ],
    );
  }
}
