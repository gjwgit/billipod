/// Tests for the Bill model — serialisation, copyWith, amountStr, nextDueDate.
///
// Run: flutter test test/bill_model_test.dart

library;

import 'package:flutter_test/flutter_test.dart';

import 'package:billipod/models/bill.dart';

void main() {
  // ── Helpers ────────────────────────────────────────────────────────────────

  Bill make({
    String? id,
    String title = 'Test bill',
    double? amount,
    DateTime? dueDate,
    BillFrequency frequency = BillFrequency.oneOff,
    BillStatus status = BillStatus.future,
    DateTime? notifiedDate,
    String? notificationMethod,
    String? paymentMethod,
    DateTime? scheduledDate,
    DateTime? confirmedPaidDate,
    String? note,
    String? parentId,
    bool isTemplate = false,
  }) => Bill(
    id: id,
    title: title,
    amount: amount,
    dueDate: dueDate,
    frequency: frequency,
    status: status,
    notifiedDate: notifiedDate,
    notificationMethod: notificationMethod,
    paymentMethod: paymentMethod,
    scheduledDate: scheduledDate,
    confirmedPaidDate: confirmedPaidDate,
    note: note,
    parentId: parentId,
    isTemplate: isTemplate,
  );

  // ── amountStr ──────────────────────────────────────────────────────────────

  group('amountStr', () {
    test('null amount returns empty string', () {
      expect(make().amountStr, '');
    });

    test('small amount formatted with 2 decimal places', () {
      expect(make(amount: 9.99).amountStr, '\$9.99');
    });

    test('thousands separator applied', () {
      expect(make(amount: 1234.56).amountStr, '\$1,234.56');
    });

    test('large amount gets multiple separators', () {
      expect(make(amount: 1234567.89).amountStr, '\$1,234,567.89');
    });

    test('whole dollar amount shows cents', () {
      expect(make(amount: 100).amountStr, '\$100.00');
    });
  });

  // ── isOverdue ──────────────────────────────────────────────────────────────

  group('isOverdue', () {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    final tomorrow = DateTime.now().add(const Duration(days: 1));

    test('past due and not paid is overdue', () {
      expect(
        make(dueDate: yesterday, status: BillStatus.future).isOverdue,
        isTrue,
      );
    });

    test('past status is never overdue', () {
      expect(
        make(dueDate: yesterday, status: BillStatus.past).isOverdue,
        isFalse,
      );
    });

    test('no due date is not overdue', () {
      expect(make().isOverdue, isFalse);
    });

    test('future due date is not overdue', () {
      expect(make(dueDate: tomorrow).isOverdue, isFalse);
    });

    test('scheduled with past due date is still overdue', () {
      expect(
        make(dueDate: yesterday, status: BillStatus.scheduled).isOverdue,
        isTrue,
      );
    });
  });

  // ── nextDueDate ────────────────────────────────────────────────────────────

  group('nextDueDate', () {
    final base = DateTime(2026, 1, 15);

    test('one-off returns null', () {
      expect(make(frequency: BillFrequency.oneOff).nextDueDate(base), isNull);
    });

    test('monthly adds 1 month', () {
      final bill = make(frequency: BillFrequency.monthly);
      expect(bill.nextDueDate(base), DateTime(2026, 2, 15));
    });

    test('every 28 days adds 28 days', () {
      final bill = make(frequency: BillFrequency.every28Days);
      expect(bill.nextDueDate(base), DateTime(2026, 2, 12));
    });

    test('quarterly adds 3 months', () {
      final bill = make(frequency: BillFrequency.quarterly);
      expect(bill.nextDueDate(base), DateTime(2026, 4, 15));
    });

    test('semi-annual adds 6 months', () {
      final bill = make(frequency: BillFrequency.semiAnnual);
      expect(bill.nextDueDate(base), DateTime(2026, 7, 15));
    });

    test('annual adds 1 year', () {
      final bill = make(frequency: BillFrequency.annual);
      expect(bill.nextDueDate(base), DateTime(2027, 1, 15));
    });
  });

  // ── JSON round-trip ────────────────────────────────────────────────────────

  group('JSON round-trip', () {
    test('full bill survives toJson/fromJson', () {
      final original = make(
        id: 'abc-123',
        title: 'Internet',
        amount: 89.99,
        dueDate: DateTime(2026, 5, 1),
        frequency: BillFrequency.monthly,
        status: BillStatus.scheduled,
        notifiedDate: DateTime(2026, 4, 20),
        notificationMethod: 'Email',
        paymentMethod: 'Direct Debit',
        scheduledDate: DateTime(2026, 4, 25),
        note: 'Check the invoice',
      );
      final restored = Bill.fromJson(original.toJson());
      expect(restored.id, original.id);
      expect(restored.title, original.title);
      expect(restored.amount, original.amount);
      expect(restored.dueDate, original.dueDate);
      expect(restored.frequency, original.frequency);
      expect(restored.status, original.status);
      expect(restored.notifiedDate, original.notifiedDate);
      expect(restored.notificationMethod, original.notificationMethod);
      expect(restored.paymentMethod, original.paymentMethod);
      expect(restored.scheduledDate, original.scheduledDate);
      expect(restored.note, original.note);
    });

    test('null optional fields omitted from JSON', () {
      final json = make(title: 'Minimal').toJson();
      expect(json.containsKey('amount'), isFalse);
      expect(json.containsKey('dueDate'), isFalse);
      expect(json.containsKey('note'), isFalse);
      expect(json.containsKey('parentId'), isFalse);
    });

    test('fromJson tolerates missing optional fields', () {
      final json = {
        'id': 'x',
        'title': 'Bare',
        'frequency': 'oneOff',
        'status': 'future',
        'isTemplate': false,
      };
      final b = Bill.fromJson(json);
      expect(b.amount, isNull);
      expect(b.dueDate, isNull);
      expect(b.isTemplate, isFalse);
    });

    test('unknown frequency falls back to oneOff', () {
      final json = {
        'id': 'x',
        'title': 'X',
        'frequency': 'unknownFreq',
        'status': 'future',
        'isTemplate': false,
      };
      expect(Bill.fromJson(json).frequency, BillFrequency.oneOff);
    });
  });

  // ── copyWith ───────────────────────────────────────────────────────────────

  group('copyWith', () {
    test('unchanged fields are preserved', () {
      final b = make(
        title: 'Electricity',
        amount: 120.0,
        frequency: BillFrequency.quarterly,
        note: 'Check meter',
      );
      final copy = b.copyWith(amount: 130.0);
      expect(copy.title, 'Electricity');
      expect(copy.frequency, BillFrequency.quarterly);
      expect(copy.note, 'Check meter');
      expect(copy.amount, 130.0);
    });

    test('id is always preserved', () {
      final b = make(id: 'fixed-id');
      expect(b.copyWith(title: 'New').id, 'fixed-id');
    });

    test('nullable fields can be cleared', () {
      final b = make(amount: 50.0, note: 'test', dueDate: DateTime(2026, 1, 1));
      final cleared = b.copyWith(amount: null, note: null, dueDate: null);
      expect(cleared.amount, isNull);
      expect(cleared.note, isNull);
      expect(cleared.dueDate, isNull);
    });

    test('status can be changed', () {
      final b = make(status: BillStatus.future);
      expect(b.copyWith(status: BillStatus.past).status, BillStatus.past);
    });
  });

  // ── BillFrequency labels ───────────────────────────────────────────────────

  group('BillFrequency labels', () {
    test('all frequencies have non-empty labels', () {
      for (final f in BillFrequency.values) {
        expect(f.label, isNotEmpty);
      }
    });

    test('label values are human readable', () {
      expect(BillFrequency.oneOff.label, 'One-off');
      expect(BillFrequency.monthly.label, 'Monthly');
      expect(BillFrequency.every28Days.label, 'Every 28 days');
      expect(BillFrequency.quarterly.label, 'Quarterly');
      expect(BillFrequency.semiAnnual.label, 'Every 6 months');
      expect(BillFrequency.annual.label, 'Annually');
    });
  });
  // ── isAutoPaid and isStarred round-trip ────────────────────────────────────

  group('isAutoPaid', () {
    test('defaults to false', () {
      expect(make().isAutoPaid, isFalse);
    });

    test('round-trips through JSON when true', () {
      final b = make(title: 'Auto').copyWith(isAutoPaid: true);
      expect(Bill.fromJson(b.toJson()).isAutoPaid, isTrue);
    });

    test('not written to JSON when false', () {
      expect(make().toJson().containsKey('isAutoPaid'), isFalse);
    });

    test('copyWith preserves when not specified', () {
      final b = make().copyWith(isAutoPaid: true);
      expect(b.copyWith(title: 'New').isAutoPaid, isTrue);
    });
  });

  group('isStarred preserved on edit (regression)', () {
    test('copyWith preserves isStarred when not specified', () {
      final b = make().copyWith(isStarred: true);
      // Simulates _buildBill creating a new Bill — isStarred must be carried over.
      final edited = b.copyWith(title: 'Edited title');
      expect(
        edited.isStarred,
        isTrue,
        reason: 'isStarred must be preserved when editing a bill',
      );
    });

    test('copyWith preserves isAutoPaid when not specified', () {
      final b = make().copyWith(isAutoPaid: true);
      final edited = b.copyWith(title: 'Edited title');
      expect(
        edited.isAutoPaid,
        isTrue,
        reason: 'isAutoPaid must be preserved when editing a bill',
      );
    });
  });
}
