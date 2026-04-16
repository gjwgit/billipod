/// Integration tests — BilliPod screens.
///
// Run: flutter test integration_test/screens_test.dart -d linux

library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:billipod/models/bill.dart';

import 'test_app.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  Future<void> pumpApp(WidgetTester tester, [List<Bill>? bills]) async {
    await tester.pumpWidget(buildTestApp(providerWith(bills: bills ?? [])));
    await tester.pumpAndSettle();
  }

  // ── Navigation ─────────────────────────────────────────────────────────────

  group('navigation', () {
    testWidgets('all four nav items are present', (tester) async {
      await pumpApp(tester);
      expect(find.text('Scheduled'), findsOneWidget);
      expect(find.text('Expected'), findsOneWidget);
      expect(find.text('Past'), findsOneWidget);
      expect(find.text('Recurring'), findsOneWidget);
    });

    testWidgets('tapping Expected shows expected screen', (tester) async {
      await pumpApp(tester);
      await tester.tap(find.text('Expected'));
      await tester.pumpAndSettle();
      expect(find.text('No future bills.'), findsOneWidget);
    });

    testWidgets('tapping Past shows past screen', (tester) async {
      await pumpApp(tester);
      await tester.tap(find.text('Past'));
      await tester.pumpAndSettle();
      expect(find.text('No paid bills yet.'), findsOneWidget);
    });

    testWidgets('tapping Recurring shows templates screen', (tester) async {
      await pumpApp(tester);
      await tester.tap(find.text('Recurring'));
      await tester.pumpAndSettle();
      expect(find.text('No recurring templates.'), findsOneWidget);
    });
  });

  // ── Empty states ───────────────────────────────────────────────────────────

  group('empty states', () {
    testWidgets('scheduled empty state', (tester) async {
      await pumpApp(tester);
      expect(find.text('No scheduled payments.'), findsOneWidget);
    });

    testWidgets('expected empty state shows after nav', (tester) async {
      await pumpApp(tester);
      await tester.tap(find.text('Expected'));
      await tester.pumpAndSettle();
      expect(find.text('No future bills.'), findsOneWidget);
    });
  });

  // ── Bill display ───────────────────────────────────────────────────────────

  group('bill display', () {
    testWidgets('scheduled bill appears in scheduled list', (tester) async {
      await pumpApp(tester, [
        makeBill(title: 'Phone bill', status: BillStatus.scheduled),
      ]);
      expect(find.text('Phone bill'), findsOneWidget);
    });

    testWidgets('future bill appears in Expected screen', (tester) async {
      await pumpApp(tester, [
        makeBill(title: 'Electricity', status: BillStatus.future),
      ]);
      await tester.tap(find.text('Expected'));
      await tester.pumpAndSettle();
      expect(find.text('Electricity'), findsOneWidget);
    });

    testWidgets('past bill appears in Past screen', (tester) async {
      await pumpApp(tester, [
        makeBill(title: 'Last month rates', status: BillStatus.past),
      ]);
      await tester.tap(find.text('Past'));
      await tester.pumpAndSettle();
      expect(find.text('Last month rates'), findsOneWidget);
    });

    testWidgets('amount displayed with dollar sign and cents', (tester) async {
      await pumpApp(tester, [
        makeBill(
          title: 'Internet',
          amount: 89.99,
          status: BillStatus.scheduled,
        ),
      ]);
      expect(find.text('\$89.99'), findsOneWidget);
    });

    testWidgets('large amount displayed with comma separator', (tester) async {
      await pumpApp(tester, [
        makeBill(
          title: 'Mortgage',
          amount: 1234.56,
          status: BillStatus.scheduled,
        ),
      ]);
      expect(find.text('\$1,234.56'), findsOneWidget);
    });

    testWidgets('recurring template appears in Recurring screen',
        (tester) async {
      await pumpApp(tester, [
        makeBill(
          title: 'Netflix',
          frequency: BillFrequency.monthly,
          dueDate: DateTime(2026, 1, 1),
          isTemplate: true,
        ),
      ]);
      await tester.tap(find.text('Recurring'));
      await tester.pumpAndSettle();
      expect(find.text('Netflix'), findsOneWidget);
    });

    testWidgets('recurring template generates instances in Expected',
        (tester) async {
      await pumpApp(tester, [
        makeBill(
          title: 'Water bill',
          frequency: BillFrequency.monthly,
          dueDate: DateTime(2026, 1, 1),
          isTemplate: true,
        ),
      ]);
      await tester.tap(find.text('Expected'));
      await tester.pumpAndSettle();
      // At least one instance should appear.
      expect(find.text('Water bill'), findsWidgets);
    });
  });

  // ── Move between sections ──────────────────────────────────────────────────

  group('move between sections', () {
    testWidgets('move to Scheduled button appears on expected bill',
        (tester) async {
      await pumpApp(tester, [
        makeBill(title: 'Council rates', status: BillStatus.future),
      ]);
      await tester.tap(find.text('Expected'));
      await tester.pumpAndSettle();
      // Move to Scheduled button (schedule_send icon).
      expect(find.byIcon(Icons.schedule_send_outlined), findsWidgets);
    });

    testWidgets('Mark as Paid button appears on scheduled bill', (tester) async {
      await pumpApp(tester, [
        makeBill(title: 'Gas bill', status: BillStatus.scheduled),
      ]);
      // check_circle_outline icon is the Mark as Paid button.
      expect(find.byIcon(Icons.check_circle_outline), findsWidgets);
    });
  });

  // ── Add bill dialog ────────────────────────────────────────────────────────

  group('edit bill dialog', () {
    testWidgets('tapping a bill opens edit dialog', (tester) async {
      await pumpApp(tester, [
        makeBill(title: 'Tap me', status: BillStatus.scheduled),
      ]);
      await tester.tap(find.text('Tap me'));
      await tester.pumpAndSettle();
      expect(find.byType(Dialog), findsOneWidget);
      expect(find.text('Edit Bill'), findsOneWidget);
    });

    testWidgets('cancel closes dialog without changes', (tester) async {
      await pumpApp(tester, [
        makeBill(title: 'Cancel test', status: BillStatus.scheduled),
      ]);
      await tester.tap(find.text('Cancel test'));
      await tester.pumpAndSettle();
      await tester.tap(find.descendant(
        of: find.byType(Dialog),
        matching: find.text('Cancel'),
      ));
      await tester.pumpAndSettle();
      expect(find.byType(Dialog), findsNothing);
      expect(find.text('Cancel test'), findsOneWidget);
    });

    testWidgets('barrierDismissible is false — dialog stays open on tap outside',
        (tester) async {
      await pumpApp(tester, [
        makeBill(title: 'Barrier test', status: BillStatus.scheduled),
      ]);
      await tester.tap(find.text('Barrier test'));
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      expect(find.byType(Dialog), findsOneWidget);
    });
  });

  // ── Duplicate ─────────────────────────────────────────────────────────────

  group('duplicate', () {
    testWidgets('duplicate button is present on each bill tile', (tester) async {
      await pumpApp(tester, [
        makeBill(title: 'Duplicate me', status: BillStatus.scheduled),
      ]);
      expect(find.byIcon(Icons.copy_outlined), findsOneWidget);
    });

    testWidgets('tapping duplicate opens editor pre-filled', (tester) async {
      await pumpApp(tester, [
        makeBill(
          title: 'Internet',
          amount: 59.99,
          status: BillStatus.scheduled,
        ),
      ]);
      await tester.tap(find.byIcon(Icons.copy_outlined));
      await tester.pumpAndSettle();
      expect(find.byType(Dialog), findsOneWidget);
      // Title field should be pre-filled with the original title.
      expect(find.text('Internet'), findsWidgets);
    });
  });

  // ── Delete ────────────────────────────────────────────────────────────────

  group('delete', () {
    testWidgets('delete button shows confirmation dialog', (tester) async {
      await pumpApp(tester, [
        makeBill(title: 'Delete me', status: BillStatus.scheduled),
      ]);
      await tester.tap(find.byIcon(Icons.delete_outline).first);
      await tester.pumpAndSettle();
      expect(find.text('Delete bill?'), findsOneWidget);
    });

    testWidgets('cancelling delete keeps the bill', (tester) async {
      final provider = providerWith(bills: [
        makeBill(title: 'Keep me', status: BillStatus.scheduled),
      ]);
      await tester.pumpWidget(buildTestApp(provider));
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.delete_outline).first);
      await tester.pumpAndSettle();
      await tester.tap(find.descendant(
        of: find.byType(AlertDialog),
        matching: find.text('Cancel'),
      ));
      await tester.pumpAndSettle();
      expect(provider.scheduledBills, hasLength(1));
    });
  });
}
