/// BillEdit — add/edit bill dialog.
///
// Time-stamp: <Thursday 2026-04-16 15:54:56 +1000 Graham Williams>
///
/// Copyright (C) 2026, Togaware Pty Ltd
///
/// Licensed under the GNU General Public License, Version 3

library;

import 'package:flutter/material.dart';

import 'package:gap/gap.dart';
import 'package:intl/intl.dart';

import 'package:billipod/constants/app.dart';
import 'package:markdown_tooltip/markdown_tooltip.dart';
import 'package:billipod/models/bill.dart';

class BillEdit extends StatefulWidget {
  final Bill? bill;
  const BillEdit({super.key, this.bill});

  @override
  State<BillEdit> createState() => _BillEditState();
}

class _BillEditState extends State<BillEdit> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _title;
  late final TextEditingController _amount;
  late final TextEditingController _note;
  late BillFrequency _frequency;
  late BillStatus _status;
  DateTime? _dueDate;
  DateTime? _notifiedDate;
  String? _notificationMethod;
  String? _paymentMethod;
  DateTime? _scheduledDate;
  DateTime? _confirmedPaidDate;
  late bool _isAutoPaid;

  bool get _isNew => widget.bill == null;

  @override
  void initState() {
    super.initState();
    final b = widget.bill;
    _title = TextEditingController(text: b?.title ?? '');
    _amount = TextEditingController(
      text: b?.amount != null ? b!.amount!.toStringAsFixed(2) : '',
    );
    _note = TextEditingController(text: b?.note ?? '');
    _frequency = b?.frequency ?? BillFrequency.oneOff;
    _status = b?.status ?? BillStatus.future;
    _dueDate = b?.dueDate;
    _notifiedDate = b?.notifiedDate;
    _notificationMethod = b?.notificationMethod;
    _paymentMethod = b?.paymentMethod;
    _scheduledDate = b?.scheduledDate;
    _confirmedPaidDate = b?.confirmedPaidDate;
    _isAutoPaid = b?.isAutoPaid ?? false;
  }

  @override
  void dispose() {
    _title.dispose();
    _amount.dispose();
    _note.dispose();
    super.dispose();
  }

  Bill _buildBill() => Bill(
    id: widget.bill?.id,
    title: _title.text.trim(),
    amount: double.tryParse(_amount.text.replaceAll(',', '')),
    dueDate: _dueDate,
    frequency: _frequency,
    status: _status,
    notifiedDate: _notifiedDate,
    notificationMethod: _notificationMethod,
    paymentMethod: _paymentMethod,
    scheduledDate: _scheduledDate,
    confirmedPaidDate: _confirmedPaidDate,
    note: _note.text.trim().isEmpty ? null : _note.text.trim(),
    parentId: widget.bill?.parentId,
    isTemplate: false,
    isStarred: widget.bill?.isStarred ?? false,
    isAutoPaid: _isAutoPaid,
  );

  Future<DateTime?> _pickDate(DateTime? initial) => showDatePicker(
    context: context,
    initialDate: initial ?? DateTime.now(),
    firstDate: DateTime(2000),
    lastDate: DateTime(2100),
  );

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 540),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Header ────────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 8, 0),
              child: Row(
                children: [
                  Text(
                    _isNew ? 'New Bill' : 'Edit Bill',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            // ── Form ──────────────────────────────────────────────────────
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title
                      TextFormField(
                        controller: _title,
                        autofocus: _isNew,
                        decoration: const InputDecoration(
                          labelText: 'Title',
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                        validator: (v) =>
                            (v == null || v.trim().isEmpty) ? 'Required' : null,
                      ),
                      const Gap(12),
                      // Amount
                      TextFormField(
                        controller: _amount,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: const InputDecoration(
                          labelText: 'Amount',
                          border: OutlineInputBorder(),
                          isDense: true,
                          prefixText: '\$ ',
                        ),
                      ),
                      const Gap(12),
                      // Frequency
                      DropdownButtonFormField<BillFrequency>(
                        initialValue: _frequency,
                        decoration: const InputDecoration(
                          labelText: 'Frequency',
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                        items: BillFrequency.values
                            .map(
                              (f) => DropdownMenuItem(
                                value: f,
                                child: Text(f.label),
                              ),
                            )
                            .toList(),
                        onChanged: (v) => setState(() => _frequency = v!),
                      ),
                      const Gap(12),
                      // Status
                      DropdownButtonFormField<BillStatus>(
                        initialValue: _status,
                        decoration: const InputDecoration(
                          labelText: 'Status',
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                        items: BillStatus.values
                            .map(
                              (s) => DropdownMenuItem(
                                value: s,
                                child: Text(s.label),
                              ),
                            )
                            .toList(),
                        onChanged: (v) => setState(() => _status = v!),
                      ),
                      const Gap(12),
                      // Notified date + method
                      _DateRow(
                        label: 'Notified date',
                        date: _notifiedDate,
                        onPick: () async {
                          final d = await _pickDate(_notifiedDate);
                          if (d != null) setState(() => _notifiedDate = d);
                        },
                        onClear: () => setState(() => _notifiedDate = null),
                      ),
                      const Gap(8),
                      DropdownButtonFormField<String?>(
                        initialValue: _notificationMethod,
                        decoration: const InputDecoration(
                          labelText: 'Notification method',
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                        items: [
                          const DropdownMenuItem(value: null, child: Text('—')),
                          ...notificationMethods.map(
                            (m) => DropdownMenuItem(value: m, child: Text(m)),
                          ),
                        ],
                        onChanged: (v) =>
                            setState(() => _notificationMethod = v),
                      ),
                      const Gap(12),
                      // Payment method
                      DropdownButtonFormField<String?>(
                        initialValue: _paymentMethod,
                        decoration: const InputDecoration(
                          labelText: 'Payment method',
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                        items: [
                          const DropdownMenuItem(value: null, child: Text('—')),
                          ...paymentMethods.map(
                            (m) => DropdownMenuItem(value: m, child: Text(m)),
                          ),
                        ],
                        onChanged: (v) => setState(() => _paymentMethod = v),
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
                          value: _isAutoPaid,
                          onChanged: (v) =>
                              setState(() => _isAutoPaid = v ?? false),
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
                      _DateRow(
                        label: 'Scheduled date',
                        date: _scheduledDate,
                        onPick: () async {
                          final d = await _pickDate(_scheduledDate);
                          if (d != null) setState(() => _scheduledDate = d);
                        },
                        onClear: () => setState(() => _scheduledDate = null),
                      ),
                      const Gap(8),
                      // Due date
                      _DateRow(
                        label: 'Due date',
                        date: _dueDate,
                        onPick: () async {
                          final d = await _pickDate(_dueDate);
                          if (d != null) setState(() => _dueDate = d);
                        },
                        onClear: () => setState(() => _dueDate = null),
                      ),
                      const Gap(8),
                      // Confirmed paid date
                      _DateRow(
                        label: 'Confirmed paid date',
                        date: _confirmedPaidDate,
                        onPick: () async {
                          final d = await _pickDate(_confirmedPaidDate);
                          if (d != null) setState(() => _confirmedPaidDate = d);
                        },
                        onClear: () =>
                            setState(() => _confirmedPaidDate = null),
                      ),
                      const Gap(12),
                      // Note
                      TextFormField(
                        controller: _note,
                        maxLines: 3,
                        decoration: const InputDecoration(
                          labelText: 'Note',
                          border: OutlineInputBorder(),
                          isDense: true,
                          alignLabelWithHint: true,
                        ),
                      ),
                      const Gap(4),
                    ],
                  ),
                ),
              ),
            ),
            // ── Actions ───────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                  const Gap(8),
                  FilledButton(
                    onPressed: () {
                      if (_formKey.currentState!.validate()) {
                        Navigator.pop(context, _buildBill());
                      }
                    },
                    child: Text(_isNew ? 'Add Bill' : 'Save'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Date row helper ───────────────────────────────────────────────────────────

class _DateRow extends StatelessWidget {
  final String label;
  final DateTime? date;
  final VoidCallback onPick;
  final VoidCallback onClear;

  const _DateRow({
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
