/// Bill — core data model for BillPod.
///
// Time-stamp: <2026-04-14>
///
/// Copyright (C) 2026, Togaware Pty Ltd
///
/// Licensed under the GNU General Public License, Version 3

library;

import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

const _uuid = Uuid();

// ── Enums ─────────────────────────────────────────────────────────────────────

/// How often a bill recurs.
enum BillFrequency {
  oneOff,
  monthly,
  every28Days,
  quarterly,
  semiAnnual,
  annual;

  String get label => switch (this) {
    oneOff => 'One-off',
    monthly => 'Monthly',
    every28Days => 'Every 28 days',
    quarterly => 'Quarterly',
    semiAnnual => 'Every 6 months',
    annual => 'Annually',
  };

  /// Approximate days between payments (used for expansion).
  int? get days => switch (this) {
    oneOff => null,
    monthly => null, // use month arithmetic
    every28Days => 28,
    quarterly => null,
    semiAnnual => null,
    annual => null,
  };
}

/// Where a bill sits in its lifecycle.
enum BillStatus {
  future,
  scheduled,
  past;

  String get label => switch (this) {
    future => 'Expected',
    scheduled => 'Scheduled',
    past => 'Past',
  };
}

// ── Bill model ────────────────────────────────────────────────────────────────

class Bill {
  final String id;
  final String title;
  final double? amount;
  final DateTime? dueDate;
  final BillFrequency frequency;
  final BillStatus status;

  // Notification
  final DateTime? notifiedDate;
  final String? notificationMethod;

  // Payment
  final String? paymentMethod;
  final DateTime? scheduledDate;
  final String? scheduledBy;
  final DateTime? confirmedPaidDate;

  final double? transactionFee;
  final String? note;

  /// For expanded recurring instances, points to the template bill id.
  final String? parentId;

  /// True if this is a recurring template (not a concrete instance).
  final bool isTemplate;

  /// True if the user has starred/highlighted this bill.
  final bool isStarred;

  /// True if this bill is paid automatically (e.g. via credit card).
  final bool isAutoPaid;

  Bill({
    String? id,
    required this.title,
    this.amount,
    this.dueDate,
    this.frequency = BillFrequency.oneOff,
    this.status = BillStatus.future,
    this.notifiedDate,
    this.notificationMethod,
    this.paymentMethod,
    this.scheduledDate,
    this.scheduledBy,
    this.confirmedPaidDate,
    this.transactionFee,
    this.note,
    this.parentId,
    this.isTemplate = false,
    this.isStarred = false,
    this.isAutoPaid = false,
  }) : id = id ?? _uuid.v4();

  // ── Serialisation ──────────────────────────────────────────────────────────

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    if (amount != null) 'amount': amount,
    if (dueDate != null) 'dueDate': dueDate!.toIso8601String(),
    'frequency': frequency.name,
    'status': status.name,
    if (notifiedDate != null) 'notifiedDate': notifiedDate!.toIso8601String(),
    if (notificationMethod != null) 'notificationMethod': notificationMethod,
    if (paymentMethod != null) 'paymentMethod': paymentMethod,
    if (scheduledDate != null)
      'scheduledDate': scheduledDate!.toIso8601String(),
    if (scheduledBy != null) 'scheduledBy': scheduledBy,
    if (confirmedPaidDate != null)
      'confirmedPaidDate': confirmedPaidDate!.toIso8601String(),
    if (transactionFee != null) 'transactionFee': transactionFee,
    if (note != null) 'note': note,
    if (parentId != null) 'parentId': parentId,
    'isTemplate': isTemplate,
    if (isStarred) 'isStarred': isStarred,
    if (isAutoPaid) 'isAutoPaid': isAutoPaid,
  };

  factory Bill.fromJson(Map<String, dynamic> j) => Bill(
    id: j['id'] as String,
    title: j['title'] as String,
    amount: (j['amount'] as num?)?.toDouble(),
    dueDate: j['dueDate'] != null
        ? DateTime.parse(j['dueDate'] as String)
        : null,
    frequency: BillFrequency.values.firstWhere(
      (e) => e.name == j['frequency'],
      orElse: () => BillFrequency.oneOff,
    ),
    status: BillStatus.values.firstWhere(
      (e) => e.name == j['status'],
      orElse: () => BillStatus.future,
    ),
    notifiedDate: j['notifiedDate'] != null
        ? DateTime.parse(j['notifiedDate'] as String)
        : null,
    notificationMethod: j['notificationMethod'] as String?,
    paymentMethod: j['paymentMethod'] as String?,
    scheduledDate: j['scheduledDate'] != null
        ? DateTime.parse(j['scheduledDate'] as String)
        : null,
    scheduledBy: j['scheduledBy'] as String?,
    confirmedPaidDate: j['confirmedPaidDate'] != null
        ? DateTime.parse(j['confirmedPaidDate'] as String)
        : null,
    transactionFee: (j['transactionFee'] as num?)?.toDouble(),
    note: j['note'] as String?,
    parentId: j['parentId'] as String?,
    isTemplate: j['isTemplate'] as bool? ?? false,
    isStarred: j['isStarred'] as bool? ?? false,
    isAutoPaid: j['isAutoPaid'] as bool? ?? false,
  );

  Bill copyWith({
    String? title,
    Object? amount = _sentinel,
    Object? dueDate = _sentinel,
    BillFrequency? frequency,
    BillStatus? status,
    Object? notifiedDate = _sentinel,
    Object? notificationMethod = _sentinel,
    Object? paymentMethod = _sentinel,
    Object? scheduledDate = _sentinel,
    Object? scheduledBy = _sentinel,
    Object? confirmedPaidDate = _sentinel,
    Object? transactionFee = _sentinel,
    Object? note = _sentinel,
    Object? parentId = _sentinel,
    bool? isTemplate,
    bool? isStarred,
    bool? isAutoPaid,
  }) => Bill(
    id: id,
    title: title ?? this.title,
    amount: amount == _sentinel ? this.amount : amount as double?,
    dueDate: dueDate == _sentinel ? this.dueDate : dueDate as DateTime?,
    frequency: frequency ?? this.frequency,
    status: status ?? this.status,
    notifiedDate: notifiedDate == _sentinel
        ? this.notifiedDate
        : notifiedDate as DateTime?,
    notificationMethod: notificationMethod == _sentinel
        ? this.notificationMethod
        : notificationMethod as String?,
    paymentMethod: paymentMethod == _sentinel
        ? this.paymentMethod
        : paymentMethod as String?,
    scheduledDate: scheduledDate == _sentinel
        ? this.scheduledDate
        : scheduledDate as DateTime?,
    scheduledBy: scheduledBy == _sentinel
        ? this.scheduledBy
        : scheduledBy as String?,
    confirmedPaidDate: confirmedPaidDate == _sentinel
        ? this.confirmedPaidDate
        : confirmedPaidDate as DateTime?,
    transactionFee: transactionFee == _sentinel
        ? this.transactionFee
        : transactionFee as double?,
    note: note == _sentinel ? this.note : note as String?,
    parentId: parentId == _sentinel ? this.parentId : parentId as String?,
    isTemplate: isTemplate ?? this.isTemplate,
    isStarred: isStarred ?? this.isStarred,
    isAutoPaid: isAutoPaid ?? this.isAutoPaid,
  );

  // ── Helpers ────────────────────────────────────────────────────────────────

  /// True if this bill is overdue (due date in the past, not yet paid).
  bool get isOverdue {
    if (status == BillStatus.past) return false;
    if (dueDate == null) return false;
    return dueDate!.isBefore(DateTime.now());
  }

  /// Formatted transaction fee string.
  String get feeStr => transactionFee != null
      ? '+ \$${NumberFormat('#,##0.00').format(transactionFee!)} fee'
      : '';

  /// Formatted amount string.
  String get amountStr =>
      amount != null ? '\$${NumberFormat('#,##0.00').format(amount!)}' : '';

  /// Compute the next due date for a recurring bill given a base date.
  DateTime? nextDueDate(DateTime base) => switch (frequency) {
    BillFrequency.oneOff => null,
    BillFrequency.monthly => DateTime(base.year, base.month + 1, base.day),
    BillFrequency.every28Days => base.add(const Duration(days: 28)),
    BillFrequency.quarterly => DateTime(base.year, base.month + 3, base.day),
    BillFrequency.semiAnnual => DateTime(base.year, base.month + 6, base.day),
    BillFrequency.annual => DateTime(base.year + 1, base.month, base.day),
  };
}

const _sentinel = Object();
