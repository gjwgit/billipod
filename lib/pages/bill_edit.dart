/// BillEdit — add/edit bill dialog.
///
// Time-stamp: <Tuesday 2026-05-05 15:21:58 +1000 Graham Williams>
///
/// Copyright (C) 2026, Togaware Pty Ltd
///
/// Licensed under the GNU General Public License, Version 3

library;

import 'package:flutter/material.dart';

import 'package:emacs_text_field/emacs_text_field.dart';
import 'package:gap/gap.dart';
import 'package:solidui/solidui.dart';

import 'package:billipod/models/bill.dart';
import 'package:billipod/pages/edit_fields/bill_schedule_fields.dart';

class BillEdit extends StatefulWidget {
  final Bill? bill;

  /// Called with the edited bill when the user saves. The caller is
  /// responsible for adding/updating it in the provider and writing it to
  /// the Pod — own bills and shared bills persist differently.
  ///
  /// Returns a future that completes when the Pod write is done. It MUST be
  /// awaited by the caller's implementation: closing the app window waits on
  /// this before quitting, so a fire-and-forget write would be killed
  /// mid-flight and the bill silently lost.
  ///
  /// A failed write MUST throw rather than report and swallow: the editor
  /// stays open on a failure, so closing over the top of unsaved work is
  /// only avoided when the failure reaches it.
  final Future<void> Function(Bill)? onSave;

  const BillEdit({super.key, this.bill, this.onSave});

  @override
  State<BillEdit> createState() => _BillEditState();
}

class _BillEditState extends State<BillEdit> with UnsavedChangesMixin {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _title;
  late final TextEditingController _amount;
  late final TextEditingController _fee;
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

  // Snapshot of the initial values, used to detect whether anything has
  // changed so the Save button can be enabled only when there is something
  // to save.
  late final String _initTitle;
  late final String _initAmount;
  late final String _initFee;
  late final String _initNote;
  late final BillFrequency _initFrequency;
  late final BillStatus _initStatus;
  late final DateTime? _initDueDate;
  late final DateTime? _initNotifiedDate;
  late final String? _initNotificationMethod;
  late final String? _initPaymentMethod;
  late final DateTime? _initScheduledDate;
  late final DateTime? _initConfirmedPaidDate;
  late final bool _initIsAutoPaid;

  bool get _isNew => widget.bill == null;

  /// Whether any editable field differs from its initial value. Drives the
  /// enabled state of the Save button.
  bool get _hasChanges =>
      _title.text != _initTitle ||
      _amount.text != _initAmount ||
      _fee.text != _initFee ||
      _note.text != _initNote ||
      _frequency != _initFrequency ||
      _status != _initStatus ||
      _dueDate != _initDueDate ||
      _notifiedDate != _initNotifiedDate ||
      _notificationMethod != _initNotificationMethod ||
      _paymentMethod != _initPaymentMethod ||
      _scheduledDate != _initScheduledDate ||
      _confirmedPaidDate != _initConfirmedPaidDate ||
      _isAutoPaid != _initIsAutoPaid;

  @override
  void initState() {
    super.initState();
    final b = widget.bill;
    _title = TextEditingController(text: b?.title ?? '');
    _amount = TextEditingController(
      text: b?.amount != null ? b!.amount!.toStringAsFixed(2) : '',
    );
    _fee = TextEditingController(
      text: b?.transactionFee != null
          ? b!.transactionFee!.toStringAsFixed(2)
          : '',
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

    // Record the initial state for change detection.
    _initTitle = _title.text;
    _initAmount = _amount.text;
    _initFee = _fee.text;
    _initNote = _note.text;
    _initFrequency = _frequency;
    _initStatus = _status;
    _initDueDate = _dueDate;
    _initNotifiedDate = _notifiedDate;
    _initNotificationMethod = _notificationMethod;
    _initPaymentMethod = _paymentMethod;
    _initScheduledDate = _scheduledDate;
    _initConfirmedPaidDate = _confirmedPaidDate;
    _initIsAutoPaid = _isAutoPaid;

    // Rebuild when text fields change so the Save button updates.
    for (final c in [_title, _amount, _fee, _note]) {
      c.addListener(_onChanged);
    }
  }

  /// Called whenever a tracked field changes; rebuilds so the Save button's
  /// enabled state reflects [_hasChanges].
  void _onChanged() => setState(() {});

  @override
  void dispose() {
    for (final c in [_title, _amount, _fee, _note]) {
      c.removeListener(_onChanged);
    }
    _title.dispose();
    _amount.dispose();
    _fee.dispose();
    _note.dispose();
    super.dispose();
  }

  Bill _buildBill() => Bill(
    id: widget.bill?.id,
    title: _title.text.trim(),
    amount: double.tryParse(_amount.text.replaceAll(',', '')),
    transactionFee: double.tryParse(_fee.text.replaceAll(',', '')),
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

  /// Set the scheduled date, promoting Expected → Scheduled automatically
  /// when a scheduled date is set, and demoting Scheduled → Expected
  /// automatically when the scheduled date is removed.
  void _setScheduledDate(DateTime? d) => setState(() {
    _scheduledDate = d;
    if (d != null && _status == BillStatus.future) {
      _status = BillStatus.scheduled;
    } else if (d == null && _status == BillStatus.scheduled) {
      _status = BillStatus.future;
    }
  });

  /// Set the confirmed paid date. A confirmed payment date means the bill is
  /// paid.
  void _setConfirmedPaidDate(DateTime? d) => setState(() {
    _confirmedPaidDate = d;
    if (d != null && _status == BillStatus.scheduled) {
      _status = BillStatus.past;
    }
  });

  Future<DateTime?> _pickDate(DateTime? initial) => showDatePicker(
    context: context,
    initialDate: initial ?? DateTime.now(),
    firstDate: DateTime(2000),
    lastDate: DateTime(2100),
  );

  /// Hand the edited bill to the caller to persist, and report whether the
  /// write actually reached the Pod.
  ///
  /// Awaited so a window close can wait for the Pod write to complete.
  Future<bool> _save() async {
    try {
      await widget.onSave?.call(_buildBill());

      return true;
    } catch (e) {
      SolidWriteFailures.report('Failed saving the bill.\n\n$e');

      return false;
    }
  }

  /// Validate, save, and close the dialog.
  ///
  /// Only closes once the write has landed: popping over a failed write loses
  /// the bill the user asked to keep.
  Future<void> _saveAndClose() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (!await _save()) return;
    if (mounted) Navigator.pop(context);
  }

  // The window-close prompt comes from UnsavedChangesMixin, which needs to
  // know what counts as unsaved, whether it is valid to save, and how to save
  // it. The mixin never pops the Navigator — the window is closing, not just
  // this dialog.

  @override
  bool get hasUnsavedChanges => _hasChanges;

  /// Title is the form's only required field, so this mirrors its validator
  /// without calling [FormState.validate], which marks fields as a side
  /// effect and has no business running from a getter. Kept honest by
  /// `window_close_guard_test.dart`, which fails if the form ever gains a
  /// validator this does not account for.

  @override
  bool get canSaveUnsavedChanges => _title.text.trim().isNotEmpty;

  @override
  Future<bool> saveUnsavedChanges() => _save();

  /// Close the editor, but if there are unsaved changes first ask the user
  /// whether to save, discard, or keep editing.
  Future<void> _confirmDiscard() async {
    if (!_hasChanges) {
      Navigator.pop(context);
      return;
    }
    final action = await showUnsavedChangesDialog(context);
    if (!mounted) return;
    switch (action) {
      case UnsavedChangesAction.save:
        await _saveAndClose();
      case UnsavedChangesAction.discard:
        Navigator.pop(context);
      case UnsavedChangesAction.keepEditing:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      // Intercept Escape / the system back button so we can warn about
      // unsaved changes. canPop is false when there are changes; the
      // onPopInvoked handler then runs our confirmation flow.
      canPop: !_hasChanges,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _confirmDiscard();
      },
      child: Dialog(
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
                      onPressed: _confirmDiscard,
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
                          validator: (v) => (v == null || v.trim().isEmpty)
                              ? 'Required'
                              : null,
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
                        // Transaction fee
                        TextFormField(
                          controller: _fee,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          decoration: const InputDecoration(
                            labelText: 'Transaction fee (optional)',
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
                        // Dates, methods and auto-paid
                        BillScheduleFields(
                          notifiedDate: _notifiedDate,
                          notificationMethod: _notificationMethod,
                          paymentMethod: _paymentMethod,
                          isAutoPaid: _isAutoPaid,
                          scheduledDate: _scheduledDate,
                          dueDate: _dueDate,
                          confirmedPaidDate: _confirmedPaidDate,
                          pickDate: _pickDate,
                          onNotifiedDate: (d) =>
                              setState(() => _notifiedDate = d),
                          onNotificationMethod: (v) =>
                              setState(() => _notificationMethod = v),
                          onPaymentMethod: (v) =>
                              setState(() => _paymentMethod = v),
                          onAutoPaid: (v) => setState(() => _isAutoPaid = v),
                          onScheduledDate: _setScheduledDate,
                          onDueDate: (d) => setState(() => _dueDate = d),
                          onConfirmedPaidDate: _setConfirmedPaidDate,
                        ),
                        const Gap(12),
                        // Note
                        EmacsTextField(
                          controller: _note,
                          minLines: 3,
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
                      onPressed: _confirmDiscard,
                      child: const Text('Cancel'),
                    ),
                    const Gap(8),
                    FilledButton(
                      onPressed: _hasChanges ? _saveAndClose : null,
                      child: Text(_isNew ? 'Add Bill' : 'Save'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
