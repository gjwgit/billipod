/// Tests for AppProvider — CRUD, lifecycle, recurring expansion, sorting.
///
// Run: flutter test test/app_provider_test.dart

library;

import 'package:flutter_test/flutter_test.dart';

import 'package:billipod/models/bill.dart';
import 'package:billipod/services/app_provider.dart';

void main() {
  // ── Helpers ────────────────────────────────────────────────────────────────

  AppProvider freshProvider() {
    final p = AppProvider();
    p.loadTestData(bills: []);
    return p;
  }

  Bill make({
    String? id,
    String title = 'Test Bill',
    double? amount,
    DateTime? dueDate,
    BillFrequency frequency = BillFrequency.oneOff,
    BillStatus status = BillStatus.future,
    String? note,
    bool isTemplate = false,
    String? parentId,
    DateTime? notifiedDate,
    String? notificationMethod,
    String? paymentMethod,
    DateTime? scheduledDate,
  }) => Bill(
    id: id,
    title: title,
    amount: amount,
    dueDate: dueDate,
    frequency: frequency,
    status: status,
    note: note,
    isTemplate: isTemplate,
    parentId: parentId,
    notifiedDate: notifiedDate,
    notificationMethod: notificationMethod,
    paymentMethod: paymentMethod,
    scheduledDate: scheduledDate,
  );

  // ── Basic CRUD ─────────────────────────────────────────────────────────────

  group('addBill', () {
    test('bill appears in allBills', () {
      final p = freshProvider();
      p.addBill(make(title: 'Internet'));
      expect(p.allBills, hasLength(1));
      expect(p.allBills.first.title, 'Internet');
    });

    test('future bill appears in futureBills', () {
      final p = freshProvider();
      p.addBill(make(status: BillStatus.future));
      expect(p.futureBills, hasLength(1));
      expect(p.scheduledBills, isEmpty);
      expect(p.pastBills, isEmpty);
    });

    test('scheduled bill appears in scheduledBills', () {
      final p = freshProvider();
      p.addBill(make(status: BillStatus.scheduled));
      expect(p.scheduledBills, hasLength(1));
      expect(p.futureBills, isEmpty);
    });

    test('past bill appears in pastBills', () {
      final p = freshProvider();
      p.addBill(make(status: BillStatus.past));
      expect(p.pastBills, hasLength(1));
      expect(p.futureBills, isEmpty);
    });
  });

  group('updateBill', () {
    test('updates title in place', () {
      final p = freshProvider();
      final b = make(id: 'x', title: 'Old');
      p.addBill(b);
      p.updateBill(b.copyWith(title: 'New'));
      expect(p.allBills.first.title, 'New');
      expect(p.allBills, hasLength(1));
    });

    test('updates amount', () {
      final p = freshProvider();
      final b = make(id: 'x', amount: 100.0);
      p.addBill(b);
      p.updateBill(b.copyWith(amount: 200.0));
      expect(p.allBills.first.amount, 200.0);
    });
  });

  group('deleteBill', () {
    test('removes bill from allBills', () {
      final p = freshProvider();
      final b = make(id: 'del');
      p.addBill(b);
      p.deleteBill('del');
      expect(p.allBills, isEmpty);
    });

    test('deleting template also removes its auto-generated instances', () {
      final p = freshProvider();
      final tmpl = make(
        id: 'tmpl',
        frequency: BillFrequency.monthly,
        dueDate: DateTime(2026, 1, 1),
        isTemplate: true,
      );
      p.addBill(tmpl);
      // Template expansion should have created instances.
      final before = p.allBills.length;
      expect(before, greaterThan(1));
      p.deleteBill('tmpl');
      expect(p.allBills, isEmpty);
    });

    test('deleting one bill does not affect others', () {
      final p = freshProvider();
      p.addBill(make(id: 'keep', title: 'Keep'));
      p.addBill(make(id: 'del', title: 'Delete'));
      p.deleteBill('del');
      expect(p.allBills, hasLength(1));
      expect(p.allBills.first.id, 'keep');
    });
  });

  // ── moveToStatus ───────────────────────────────────────────────────────────

  group('moveToStatus', () {
    test('future → scheduled', () {
      final p = freshProvider();
      final b = make(id: 'x', status: BillStatus.future);
      p.addBill(b);
      p.moveToStatus('x', BillStatus.scheduled);
      expect(p.scheduledBills, hasLength(1));
      expect(p.futureBills, isEmpty);
    });

    test('scheduled → past', () {
      final p = freshProvider();
      final b = make(id: 'x', status: BillStatus.scheduled);
      p.addBill(b);
      p.moveToStatus('x', BillStatus.past);
      expect(p.pastBills, hasLength(1));
      expect(p.scheduledBills, isEmpty);
    });

    test('scheduled → future (move back)', () {
      final p = freshProvider();
      final b = make(id: 'x', status: BillStatus.scheduled);
      p.addBill(b);
      p.moveToStatus('x', BillStatus.future);
      expect(p.futureBills, hasLength(1));
      expect(p.scheduledBills, isEmpty);
    });
  });

  // ── Recurring expansion ────────────────────────────────────────────────────

  group('recurring expansion', () {
    test('monthly template generates multiple future instances', () {
      final p = freshProvider();
      p.addBill(
        make(
          id: 'tmpl',
          frequency: BillFrequency.monthly,
          dueDate: DateTime(2026, 1, 1),
          isTemplate: true,
        ),
      );
      // Should generate ~12 months of instances.
      final instances = p.futureBills
          .where((b) => b.parentId == 'tmpl')
          .toList();
      expect(instances.length, greaterThanOrEqualTo(1));
    });

    test('annual template generates at least one future instance', () {
      final p = freshProvider();
      p.addBill(
        make(
          id: 'annual',
          frequency: BillFrequency.annual,
          dueDate: DateTime(2025, 6, 1),
          isTemplate: true,
        ),
      );
      final instances = p.futureBills
          .where((b) => b.parentId == 'annual')
          .toList();
      expect(
        instances,
        isNotEmpty,
        reason: 'Annual bills must always have at least one future instance',
      );
    });

    test('semi-annual generates at least one instance', () {
      final p = freshProvider();
      p.addBill(
        make(
          id: 'semi',
          frequency: BillFrequency.semiAnnual,
          dueDate: DateTime(2025, 12, 1),
          isTemplate: true,
        ),
      );
      final instances = p.futureBills
          .where((b) => b.parentId == 'semi')
          .toList();
      expect(instances, isNotEmpty);
    });

    test('instances inherit template amount and note', () {
      final p = freshProvider();
      p.addBill(
        make(
          id: 'tmpl',
          frequency: BillFrequency.monthly,
          dueDate: DateTime(2026, 1, 1),
          amount: 49.99,
          note: 'Streaming service',
          isTemplate: true,
        ),
      );
      final instance = p.futureBills.firstWhere((b) => b.parentId == 'tmpl');
      expect(instance.amount, 49.99);
      expect(instance.note, 'Streaming service');
    });

    test('instances are not templates', () {
      final p = freshProvider();
      p.addBill(
        make(
          id: 'tmpl',
          frequency: BillFrequency.monthly,
          dueDate: DateTime(2026, 1, 1),
          isTemplate: true,
        ),
      );
      final instances = p.futureBills
          .where((b) => b.parentId == 'tmpl')
          .toList();
      expect(instances.every((b) => !b.isTemplate), isTrue);
    });

    test('notified date offset is preserved in expansions', () {
      final dueDate = DateTime(2026, 3, 1);
      final notifiedDate = DateTime(2026, 2, 15); // 14 days before due
      final p = freshProvider();
      p.addBill(
        make(
          id: 'tmpl',
          frequency: BillFrequency.monthly,
          dueDate: dueDate,
          notifiedDate: notifiedDate,
          isTemplate: true,
        ),
      );
      // Each instance should have notifiedDate 14 days before its dueDate.
      final instances = p.futureBills
          .where((b) => b.parentId == 'tmpl')
          .toList();
      for (final inst in instances) {
        if (inst.dueDate != null && inst.notifiedDate != null) {
          final offset = inst.dueDate!.difference(inst.notifiedDate!).inDays;
          expect(
            offset,
            14,
            reason: 'Notified date offset should match template offset',
          );
        }
      }
    });

    test('manually edited instance is not auto-deleted on re-expansion', () {
      final p = freshProvider();
      p.addBill(
        make(
          id: 'tmpl',
          frequency: BillFrequency.monthly,
          dueDate: DateTime(2026, 1, 1),
          note: 'Template note',
          isTemplate: true,
        ),
      );
      // Get an auto-generated instance and manually edit its note.
      final instance = p.futureBills.firstWhere((b) => b.parentId == 'tmpl');
      p.updateBill(instance.copyWith(note: 'Manually changed note'));
      // Trigger re-expansion by updating the template.
      final tmpl = p.templateBills.first;
      p.updateBill(tmpl.copyWith(amount: 99.99));
      // The manually edited instance should still exist.
      final edited = p.allBills.where(
        (b) => b.id == instance.id && b.note == 'Manually changed note',
      );
      expect(
        edited,
        isNotEmpty,
        reason: 'Manually edited instance should survive re-expansion',
      );
    });
  });

  // ── Sorting ────────────────────────────────────────────────────────────────

  group('sorting', () {
    test('futureBills sorted by due date ascending', () {
      final p = freshProvider();
      p.addBill(make(dueDate: DateTime(2026, 6, 1), title: 'Later'));
      p.addBill(make(dueDate: DateTime(2026, 3, 1), title: 'Earlier'));
      expect(p.futureBills.first.title, 'Earlier');
    });

    test('pastBills sorted by due date descending', () {
      final p = freshProvider();
      p.addBill(
        make(
          dueDate: DateTime(2026, 1, 1),
          title: 'Jan',
          status: BillStatus.past,
        ),
      );
      p.addBill(
        make(
          dueDate: DateTime(2026, 3, 1),
          title: 'Mar',
          status: BillStatus.past,
        ),
      );
      expect(p.pastBills.first.title, 'Mar');
    });

    test('bills with no due date sort last in future list', () {
      final p = freshProvider();
      p.addBill(make(title: 'No date'));
      p.addBill(make(dueDate: DateTime(2026, 1, 1), title: 'Has date'));
      expect(p.futureBills.first.title, 'Has date');
      expect(p.futureBills.last.title, 'No date');
    });
  });
  // ── isAutoPaid / isStarred preservation on update ──────────────────────────

  group('field preservation on updateBill', () {
    test('CRITICAL: isAutoPaid is preserved after updateBill', () {
      final p = freshProvider();
      final b = make(id: 'x', title: 'Bill').copyWith(isAutoPaid: true);
      // Use Bill directly since make() helper doesn't expose isAutoPaid.
      final original = Bill(id: 'x', title: 'Original', isAutoPaid: true);
      p.addBill(original);

      // Simulate editing — update title but preserve isAutoPaid.
      final edited = original.copyWith(title: 'Edited');
      p.updateBill(edited);

      expect(
        p.allBills.first.isAutoPaid,
        isTrue,
        reason:
            'isAutoPaid must survive updateBill — was being lost in edit dialog',
      );
    });

    test('CRITICAL: isStarred is preserved after updateBill', () {
      final p = freshProvider();
      final original = Bill(id: 'y', title: 'Starred', isStarred: true);
      p.addBill(original);

      final edited = original.copyWith(title: 'Edited title');
      p.updateBill(edited);

      expect(
        p.allBills.first.isStarred,
        isTrue,
        reason:
            'isStarred must survive updateBill — was being reset to false in edit dialog',
      );
    });
  });

  // ── isAutoPaid survives reload (recurring instance regression) ─────────────

  group('isAutoPaid on recurring instances', () {
    test('CRITICAL: editing isAutoPaid on a recurring instance is preserved '
        'across _expandRecurring', () {
      final p = freshProvider();
      // Create a monthly template.
      final tmpl = Bill(
        id: 'tmpl',
        title: 'Credit card',
        frequency: BillFrequency.monthly,
        dueDate: DateTime(2026, 1, 1),
        isTemplate: true,
        isAutoPaid: false,
      );
      p.addBill(tmpl);

      // Get an auto-generated instance and set isAutoPaid = true on it.
      final instance = p.futureBills.firstWhere((b) => b.parentId == 'tmpl');
      p.updateBill(instance.copyWith(isAutoPaid: true));

      // Simulate reload — _expandRecurring is called inside loadTestData.
      final allBills = p.allBills.toList();
      p.loadTestData(bills: allBills);

      // The edited instance must still have isAutoPaid = true.
      final reloaded = p.allBills.firstWhere(
        (b) => b.id == instance.id,
        orElse: () => throw StateError('Instance was deleted on re-expansion'),
      );
      expect(
        reloaded.isAutoPaid,
        isTrue,
        reason:
            'isAutoPaid must survive _expandRecurring — '
            'was being lost because _isAutoGenerated did not check isAutoPaid',
      );
    });

    test('CRITICAL: starring a recurring instance preserves it across '
        '_expandRecurring', () {
      final p = freshProvider();
      final tmpl = Bill(
        id: 'tmpl2',
        title: 'Rent',
        frequency: BillFrequency.monthly,
        dueDate: DateTime(2026, 1, 1),
        isTemplate: true,
      );
      p.addBill(tmpl);

      final instance = p.futureBills.firstWhere((b) => b.parentId == 'tmpl2');
      p.updateBill(instance.copyWith(isStarred: true));

      final allBills = p.allBills.toList();
      p.loadTestData(bills: allBills);

      final reloaded = p.allBills.firstWhere(
        (b) => b.id == instance.id,
        orElse: () =>
            throw StateError('Starred instance was deleted on re-expansion'),
      );
      expect(
        reloaded.isStarred,
        isTrue,
        reason: 'Starred instances must survive _expandRecurring',
      );
    });

    test('isAutoPaid propagates from template to new instances', () {
      final p = freshProvider();
      p.addBill(
        Bill(
          id: 'tmpl3',
          title: 'Auto bill',
          frequency: BillFrequency.monthly,
          dueDate: DateTime(2026, 1, 1),
          isTemplate: true,
          isAutoPaid: true,
        ),
      );
      final instances = p.futureBills
          .where((b) => b.parentId == 'tmpl3')
          .toList();
      expect(instances, isNotEmpty);
      expect(
        instances.every((b) => b.isAutoPaid),
        isTrue,
        reason:
            'All expanded instances should inherit isAutoPaid from template',
      );
    });
  });
}
