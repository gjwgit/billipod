/// AppProvider — state management for BillPod.
///
// Time-stamp: <2026-04-14>
///
/// Copyright (C) 2026, Togaware Pty Ltd
///
/// Licensed under the GNU General Public License, Version 3

library;

import 'dart:async';

import 'package:flutter/foundation.dart';

import 'package:solidpod/solidpod.dart';

import 'package:billipod/constants/app.dart';
import 'package:billipod/models/bill.dart';
import 'package:billipod/models/tagged_bill.dart';
import 'package:billipod/services/bill_sort.dart';
import 'package:billipod/services/pod_service.dart';

class AppProvider extends ChangeNotifier {
  List<Bill> _bills = [];
  bool _loading = false;
  String? _error;

  // ── Shared source state ───────────────────────────────────────────────────

  String _ownName = '';
  bool _ownActive = true;
  final List<SharedSource> _sharedSources = [];

  String get ownName => _ownName;
  bool get ownActive => _ownActive;
  List<SharedSource> get sharedSources => List.unmodifiable(_sharedSources);
  bool get hasSharedSources => _sharedSources.isNotEmpty;

  void toggleOwn() {
    _ownActive = !_ownActive;
    notifyListeners();
  }

  void toggleSharedSource(String webId) {
    final src = _sharedSources.firstWhere((s) => s.webId == webId);
    src.isActive = !src.isActive;
    notifyListeners();
  }

  /// Loads the list of PODs that have shared their bills.ttl with the current
  /// user, then asynchronously loads their bills in the background.
  Future<void> loadSharedSources() async {
    // Resolve own pod username.
    final webId = await getWebId();
    if (webId != null && webId.isNotEmpty) {
      _ownName = _podName(webId);
    }
    // Fetch shared resource map filtered to bills.ttl.
    final result = await sharedResources(billsFileName, null);
    if (result is! Map || result.isEmpty) {
      notifyListeners();
      return;
    }
    _sharedSources.clear();
    for (final key in result.keys) {
      final fileUrl = key as String;
      final entry = result[key] as Map<dynamic, dynamic>;
      final ownerWebId =
          entry[PermissionLogLiteral.owner] as String? ?? fileUrl;
      final permissions =
          entry[PermissionLogLiteral.permissions] as String? ?? '';
      final p = permissions.toLowerCase();
      final canEdit =
          p.contains(AccessMode.write.mode.toLowerCase()) ||
          p.contains(AccessMode.control.mode.toLowerCase());
      _sharedSources.add(
        SharedSource(
          webId: ownerWebId,
          name: _podName(ownerWebId),
          fileUrl: fileUrl,
          canEdit: canEdit,
        ),
      );
    }
    notifyListeners();
    // Load bills for each source in the background.
    for (final src in _sharedSources) {
      unawaited(_loadSourceBills(src));
    }
  }

  Future<void> _loadSourceBills(SharedSource src) async {
    src.isLoading = true;
    notifyListeners();
    final bills = await PodService.loadBillsFromUrl(src.fileUrl);
    src.bills = bills ?? [];
    src.isLoading = false;
    notifyListeners();
  }

  static String _podName(String webId) {
    try {
      final segments = Uri.parse(
        webId,
      ).pathSegments.where((s) => s.isNotEmpty).toList();
      return segments.isNotEmpty ? segments.first : webId;
    } catch (_) {
      return webId;
    }
  }

  // ── Tagged bill computed properties ───────────────────────────────────────

  /// Bills tagged with their source, combined from all active sources.
  List<TaggedBill> get activeScheduledBills =>
      _taggedByStatus(BillStatus.scheduled);

  List<TaggedBill> get activeFutureBills => _taggedByStatus(BillStatus.future);

  List<TaggedBill> get activePastBills =>
      _taggedByStatus(BillStatus.past, desc: true);

  List<TaggedBill> get activeAllBills {
    final result = <TaggedBill>[
      ..._taggedByStatus(BillStatus.scheduled),
      ..._taggedByStatus(BillStatus.future),
      ..._taggedByStatus(BillStatus.past, desc: true),
    ];
    return result;
  }

  List<TaggedBill> _taggedByStatus(BillStatus status, {bool desc = false}) {
    final result = <TaggedBill>[];
    if (_ownActive) {
      final own = switch (status) {
        BillStatus.scheduled => scheduledBills,
        BillStatus.future => futureBills,
        BillStatus.past => pastBills,
      };
      result.addAll(own.map((b) => TaggedBill(b, null)));
    }
    for (final src in _sharedSources.where((s) => s.isActive && !s.isLoading)) {
      final srcBills = src.bills
          .where((b) => b.status == status && !b.isTemplate)
          .toList();
      result.addAll(
        srcBills.map(
          (b) => TaggedBill(
            b,
            src.name,
            canEdit: src.canEdit,
            fileUrl: src.fileUrl,
            ownerWebId: src.webId,
          ),
        ),
      );
    }
    result.sort((a, b) {
      if (a.bill.dueDate == null && b.bill.dueDate == null) return 0;
      if (a.bill.dueDate == null) return 1;
      if (b.bill.dueDate == null) return -1;
      return desc
          ? b.bill.dueDate!.compareTo(a.bill.dueDate!)
          : a.bill.dueDate!.compareTo(b.bill.dueDate!);
    });
    return result;
  }

  bool get loading => _loading;
  String? get error => _error;

  /// All bills sorted by due date (nulls last).
  /// True when there is already a future or scheduled bill with the same title
  /// whose due date falls around the next frequency cycle of [bill].
  /// Returns false for one-off bills (they have no follow-on concept).
  bool hasFollowOn(Bill bill) {
    if (bill.frequency == BillFrequency.oneOff) return false;
    final next = bill.nextDueDate(bill.dueDate ?? DateTime.now());
    if (next == null) return false;
    final window = const Duration(days: 5);
    return _bills.any(
      (b) =>
          b.id != bill.id &&
          b.status != BillStatus.past &&
          b.title == bill.title &&
          b.dueDate != null &&
          (b.dueDate!.difference(next)).abs() <= window,
    );
  }

  List<Bill> get allBills => List.unmodifiable(_bills);

  List<Bill> get futureBills => sortedByDueAsc(
    _bills
        .where((b) => b.status == BillStatus.future && !b.isTemplate)
        .toList(),
  );

  List<Bill> get scheduledBills => sortedByDueAsc(
    _bills.where((b) => b.status == BillStatus.scheduled).toList(),
  );

  List<Bill> get pastBills => sortedByDueDesc(
    _bills.where((b) => b.status == BillStatus.past).toList(),
  );

  List<Bill> get templateBills => _bills.where((b) => b.isTemplate).toList();

  // ── Load / Save ────────────────────────────────────────────────────────────

  /// Load bills directly — used in tests to avoid requiring a live pod.
  void loadTestData({required List<Bill> bills}) {
    _testMode = true;
    _bills = bills;
    _expandRecurring();
    _loading = false;
    notifyListeners();
  }

  bool _testMode = false;

  Future<void> loadFromPod() async {
    _loading = true;
    _error = null;
    notifyListeners();
    final loaded = await PodService.loadBills(billsFileName);
    if (loaded == null) {
      _error = 'Could not load bills from Pod.';
    } else {
      _bills = loaded;
      _expandRecurring();
    }
    _loading = false;
    notifyListeners();
    // Load shared sources in background — own bills are already visible.
    unawaited(loadSharedSources());
  }

  /// Add one or more bills to a shared source and save once.
  Future<String?> addSharedBills(String ownerWebId, List<Bill> bills) async {
    final src = _sharedSources.firstWhere((s) => s.webId == ownerWebId);
    src.bills = [...src.bills, ...bills];
    notifyListeners();
    return PodService.saveBillsToUrl(src.fileUrl, src.webId, src.bills);
  }

  /// Like [hasFollowOn] but checks within a shared source's bill list.
  bool hasFollowOnInSource(String ownerWebId, Bill bill) {
    if (bill.frequency == BillFrequency.oneOff) return false;
    final next = bill.nextDueDate(bill.dueDate ?? DateTime.now());
    if (next == null) return false;
    final src = _sharedSources.firstWhere(
      (s) => s.webId == ownerWebId,
      orElse: () =>
          SharedSource(webId: '', name: '', fileUrl: '', canEdit: false),
    );
    const window = Duration(days: 5);
    return src.bills.any(
      (b) =>
          b.id != bill.id &&
          b.status != BillStatus.past &&
          b.title == bill.title &&
          b.dueDate != null &&
          (b.dueDate!.difference(next)).abs() <= window,
    );
  }

  /// Update a single bill in a shared source and save back to their POD.
  /// Returns an error message on failure, or null on success.
  Future<String?> updateSharedBill(String ownerWebId, Bill updated) async {
    final src = _sharedSources.firstWhere((s) => s.webId == ownerWebId);
    src.bills = [for (final b in src.bills) b.id == updated.id ? updated : b];
    notifyListeners();
    return PodService.saveBillsToUrl(src.fileUrl, src.webId, src.bills);
  }

  /// Delete a single bill from a shared source and save back to their POD.
  /// Returns an error message on failure, or null on success.
  Future<String?> deleteSharedBill(String ownerWebId, String billId) async {
    final src = _sharedSources.firstWhere((s) => s.webId == ownerWebId);
    src.bills = src.bills.where((b) => b.id != billId).toList();
    notifyListeners();
    return PodService.saveBillsToUrl(src.fileUrl, src.webId, src.bills);
  }

  Future<String?> saveToPod() async {
    if (_testMode) return null;
    final err = await PodService.saveBills(billsFileName, _bills);
    if (err != null) {
      _error = err;
      notifyListeners();
    }
    return err;
  }

  // ── CRUD ───────────────────────────────────────────────────────────────────

  void addBill(Bill bill) {
    _bills = [bill, ..._bills];
    if (bill.isTemplate) _expandRecurring();
    notifyListeners();
  }

  void updateBill(Bill bill) {
    _bills = [for (final b in _bills) b.id == bill.id ? bill : b];
    if (bill.isTemplate) _expandRecurring();
    notifyListeners();
  }

  void deleteBill(String id) {
    final bill = _bills.firstWhere((b) => b.id == id);
    // If deleting a template, also remove its expanded instances.
    if (bill.isTemplate) {
      _bills = _bills.where((b) => b.id != id && b.parentId != id).toList();
    } else {
      _bills = _bills.where((b) => b.id != id).toList();
    }
    notifyListeners();
  }

  /// Move a bill to a new status.
  void moveToStatus(String id, BillStatus newStatus) {
    _bills = [
      for (final b in _bills)
        if (b.id == id) b.copyWith(status: newStatus) else b,
    ];
    notifyListeners();
  }

  // ── Recurring expansion ────────────────────────────────────────────────────

  /// Expand recurring bill templates into individual Future instances for
  /// the next [expansionMonths] months, removing stale expansions first.
  void _expandRecurring() {
    final templates = _bills.where((b) => b.isTemplate).toList();
    // Remove existing auto-generated instances.
    _bills = _bills
        .where((b) => b.parentId == null || !_isAutoGenerated(b))
        .toList();

    final now = DateTime.now();

    for (final tmpl in templates) {
      if (tmpl.frequency == BillFrequency.oneOff) continue;
      if (tmpl.dueDate == null) continue;

      // For annual/semi-annual bills the standard 12-month window may not
      // include even a single occurrence, so extend to cover at least 2 cycles.
      final cycleMonths = switch (tmpl.frequency) {
        BillFrequency.annual => 13,
        BillFrequency.semiAnnual => 7,
        BillFrequency.quarterly => 4,
        _ => expansionMonths,
      };
      final cutoff = now.add(Duration(days: cycleMonths * 31));

      // If the template has a notified date, compute its offset from the due
      // date so each expansion gets a proportionally adjusted notified date.
      final notifyOffset = (tmpl.notifiedDate != null)
          ? tmpl.notifiedDate!.difference(tmpl.dueDate!).inDays
          : null;

      var next = tmpl.dueDate!;
      // Advance to the first future occurrence.
      while (next.isBefore(now)) {
        final n = tmpl.nextDueDate(next);
        if (n == null) break;
        next = n;
      }

      // Expand up to the cutoff.
      while (next.isBefore(cutoff)) {
        // Only add if no manual entry already exists for this date+parent.
        final alreadyExists = _bills.any(
          (b) =>
              b.parentId == tmpl.id &&
              b.dueDate != null &&
              _sameDay(b.dueDate!, next),
        );
        if (!alreadyExists) {
          _bills.add(
            Bill(
              title: tmpl.title,
              amount: tmpl.amount,
              dueDate: next,
              frequency: tmpl.frequency,
              status: BillStatus.future,
              notifiedDate: notifyOffset != null
                  ? next.add(Duration(days: notifyOffset))
                  : null,
              notificationMethod: tmpl.notificationMethod,
              paymentMethod: tmpl.paymentMethod,
              note: tmpl.note,
              parentId: tmpl.id,
              isTemplate: false,
              isAutoPaid: tmpl.isAutoPaid,
            ),
          );
        }
        final n = tmpl.nextDueDate(next);
        if (n == null) break;
        next = n;
      }

      // Guarantee at least one future occurrence exists regardless of frequency.
      // This handles e.g. an annual bill whose next date falls beyond the cutoff.
      final hasAny = _bills.any(
        (b) => b.parentId == tmpl.id && b.status == BillStatus.future,
      );
      if (!hasAny) {
        final alreadyExists = _bills.any(
          (b) =>
              b.parentId == tmpl.id &&
              b.dueDate != null &&
              _sameDay(b.dueDate!, next),
        );
        if (!alreadyExists) {
          _bills.add(
            Bill(
              title: tmpl.title,
              amount: tmpl.amount,
              dueDate: next,
              frequency: tmpl.frequency,
              status: BillStatus.future,
              notifiedDate: notifyOffset != null
                  ? next.add(Duration(days: notifyOffset))
                  : null,
              notificationMethod: tmpl.notificationMethod,
              paymentMethod: tmpl.paymentMethod,
              note: tmpl.note,
              parentId: tmpl.id,
              isTemplate: false,
              isAutoPaid: tmpl.isAutoPaid,
            ),
          );
        }
      }
    }
  }

  /// Auto-generated instances have a parentId AND status == future.
  /// (Manual entries derived from a template also have parentId but have been
  /// individually edited — we never auto-delete those.)
  /// Returns true if [b] is an auto-generated (not manually edited) expansion.
  /// Manual edits are indicated by a notified date, scheduled date, a note
  /// that differs from the parent template, a starred flag, or an isAutoPaid
  /// value that differs from the template.
  bool _isAutoGenerated(Bill b) {
    if (b.parentId == null) return false;
    if (b.status != BillStatus.future) return false;
    if (b.notifiedDate != null) return false;
    if (b.scheduledDate != null) return false;
    // A starred instance has been individually marked — preserve it.
    if (b.isStarred) return false;
    // If note or isAutoPaid differs from parent template it has been manually edited.
    final parent = _bills.where((t) => t.id == b.parentId).firstOrNull;
    if (b.note != (parent?.note)) return false;
    if (b.isAutoPaid != (parent?.isAutoPaid ?? false)) return false;
    return true;
  }

  bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
}
