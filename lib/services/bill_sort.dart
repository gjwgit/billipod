/// Bill sorting helpers.
///
// Time-stamp: <2026-05-20>
///
/// Copyright (C) 2026, Togaware Pty Ltd
///
/// Licensed under the GNU General Public License, Version 3

library;

import 'package:billipod/models/bill.dart';

/// Return [bills] sorted ascending by due date. Bills without a due date
/// sink to the end (stable relative order is not guaranteed for nulls).
List<Bill> sortedByDueAsc(List<Bill> bills) {
  final copy = List<Bill>.from(bills);
  copy.sort((a, b) {
    if (a.dueDate == null && b.dueDate == null) return 0;
    if (a.dueDate == null) return 1;
    if (b.dueDate == null) return -1;
    return a.dueDate!.compareTo(b.dueDate!);
  });
  return copy;
}

/// Return [bills] sorted descending by due date (most recent first).
/// Bills without a due date sink to the end.
List<Bill> sortedByDueDesc(List<Bill> bills) {
  final copy = List<Bill>.from(bills);
  copy.sort((a, b) {
    if (a.dueDate == null && b.dueDate == null) return 0;
    if (a.dueDate == null) return 1;
    if (b.dueDate == null) return -1;
    return b.dueDate!.compareTo(a.dueDate!);
  });
  return copy;
}
