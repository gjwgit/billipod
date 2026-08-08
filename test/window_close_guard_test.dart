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

  testWidgets('editor unregisters its resolver on dispose', (tester) async {
    await tester.pumpWidget(wrap(const BillEdit()));
    await tester.pumpAndSettle();
    await tester.pumpWidget(wrap(const SizedBox()));
    await tester.pumpAndSettle();
    // No editor left registered, so nothing to resolve.
    expect(await SolidWindowCloseGuard.resolveAll(), isTrue);
  });
}
