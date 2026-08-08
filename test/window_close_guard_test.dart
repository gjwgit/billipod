/// Tests for SolidWindowCloseGuard as wired up by BillEdit — the
/// window-close confirmation path (save / discard / keep editing).
///
// Runs without a live Pod: only rendering / state behaviour.
//
// Run: flutter test test/window_close_guard_test.dart

library;

import 'dart:async';

import 'package:flutter/material.dart';

import 'package:flutter_test/flutter_test.dart';
import 'package:solidui/solidui.dart';

import 'package:billipod/pages/bill_edit.dart';

Widget wrap(Widget child) => MaterialApp(home: child);

void main() {
  testWidgets('resolveAll succeeds with no prompt when nothing changed', (
    tester,
  ) async {
    await tester.pumpWidget(wrap(const BillEdit()));
    await tester.pumpAndSettle();
    expect(await SolidWindowCloseGuard.resolveAll(), isTrue);
    expect(find.text('Unsaved changes'), findsNothing);
  });

  testWidgets('resolveAll prompts and resolves true on Discard', (
    tester,
  ) async {
    await tester.pumpWidget(wrap(const BillEdit()));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).first, 'New title');
    await tester.pump();

    final future = SolidWindowCloseGuard.resolveAll();
    await tester.pumpAndSettle();
    expect(find.text('Unsaved changes'), findsOneWidget);

    await tester.tap(find.text('Discard'));
    await tester.pumpAndSettle();
    expect(await future, isTrue);
  });

  testWidgets('resolveAll prompts and resolves false on Keep editing', (
    tester,
  ) async {
    await tester.pumpWidget(wrap(const BillEdit()));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).first, 'New title');
    await tester.pump();

    final future = SolidWindowCloseGuard.resolveAll();
    await tester.pumpAndSettle();

    await tester.tap(find.text('Keep editing'));
    await tester.pumpAndSettle();
    expect(await future, isFalse);
    // The editor is still open with the unsaved title intact.
    expect(find.text('New title'), findsOneWidget);
  });

  // Regression: BillEdit used to pop the bill and let the caller persist it,
  // so the Pod write was not awaited. resolveAll() returned immediately, the
  // window was destroyed mid-write, and the new bill was lost despite the
  // user tapping Save.
  testWidgets('window-close Save waits for the Pod write to finish', (
    tester,
  ) async {
    final podWrite = Completer<void>();
    var written = false;

    await tester.pumpWidget(
      wrap(
        BillEdit(
          onSave: (bill) async {
            await podWrite.future;
            written = true;
          },
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).first, 'New title');
    await tester.pump();

    var resolved = false;
    final future = SolidWindowCloseGuard.resolveAll()
      ..then((_) => resolved = true);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    // The Pod write is still in flight, so the guard must NOT have resolved
    // — otherwise the caller would destroy the window and lose the bill.
    expect(resolved, isFalse);
    expect(written, isFalse);

    podWrite.complete();
    await tester.pumpAndSettle();

    expect(await future, isTrue);
    expect(written, isTrue);
  });

  // Regression: saveUnsavedChanges used to return Future<void>, so the guard
  // assumed a save that completed had landed. A failed Pod write closed the
  // window anyway and the bill was lost despite the user tapping Save.
  testWidgets('a failed save aborts the close and keeps the bill', (
    tester,
  ) async {
    await tester.pumpWidget(
      wrap(BillEdit(onSave: (b) async => throw Exception('pod unreachable'))),
    );
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).first, 'New title');
    await tester.pump();

    // Save via the window-close prompt.
    final future = SolidWindowCloseGuard.resolveAll();
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    // The write failed, so the close must be aborted — resolving true here
    // would destroy the window over the top of the unsaved bill.
    expect(await future, isFalse);
    // The editor is still open with the unsaved title intact.
    expect(find.text('New title'), findsOneWidget);

    // Still dirty, so a second close attempt has to prompt again rather than
    // discard silently.
    final second = SolidWindowCloseGuard.resolveAll();
    await tester.pumpAndSettle();
    expect(find.text('Unsaved changes'), findsOneWidget);

    await tester.tap(find.text('Discard'));
    await tester.pumpAndSettle();
    expect(await second, isTrue);
  });

  // A failed save from the Add/Save button must leave the dialog open too, so
  // the user can retry rather than lose the bill to a dialog that popped
  // anyway. Opened as a real dialog route so the pop under test is real.
  testWidgets('a failed save leaves the editor open', (tester) async {
    await tester.pumpWidget(
      wrap(
        Builder(
          builder: (context) => TextButton(
            onPressed: () => showDialog<void>(
              context: context,
              builder: (_) => BillEdit(
                onSave: (b) async => throw Exception('pod unreachable'),
              ),
            ),
            child: const Text('Open'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).first, 'New title');
    await tester.pump();

    await tester.tap(find.text('Add Bill'));
    await tester.pumpAndSettle();

    expect(find.byType(BillEdit), findsOneWidget);
    expect(find.text('New title'), findsOneWidget);
  });

  testWidgets('editor unregisters its resolver on dispose', (tester) async {
    await tester.pumpWidget(wrap(const BillEdit()));
    await tester.pumpAndSettle();
    await tester.pumpWidget(wrap(const SizedBox()));
    await tester.pumpAndSettle();
    // No editor left registered, so nothing to resolve.
    expect(await SolidWindowCloseGuard.resolveAll(), isTrue);
  });

  // canSaveUnsavedChanges mirrors the form's validators by hand rather than
  // calling validate(), which mutates field state. These pin the two together:
  // add a validator to any other field and the second test fails, flagging
  // that the hand-written gate needs updating too.

  testWidgets('a filled title is all the form requires', (tester) async {
    await tester.pumpWidget(wrap(const BillEdit()));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).first, 'Rates');
    await tester.pump();

    final form = tester.state<FormState>(find.byType(Form));
    expect(form.validate(), isTrue);
  });

  testWidgets('an empty title is the only thing that fails the form', (
    tester,
  ) async {
    await tester.pumpWidget(wrap(const BillEdit()));
    await tester.pumpAndSettle();

    final form = tester.state<FormState>(find.byType(Form));
    expect(form.validate(), isFalse);
  });

  testWidgets('window-close Save on an untitled bill keeps the editor open', (
    tester,
  ) async {
    var saved = false;
    await tester.pumpWidget(wrap(BillEdit(onSave: (b) async => saved = true)));
    await tester.pumpAndSettle();
    // Dirty but invalid: a note, no title.
    await tester.enterText(find.byType(TextFormField).last, 'some note');
    await tester.pump();

    final future = SolidWindowCloseGuard.resolveAll();
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    // Nothing saveable, so the close is aborted rather than losing the edit.
    expect(await future, isFalse);
    expect(saved, isFalse);
  });
}
