/// TaggedBill and SharedSource — models for mixing own and shared bills.
///
// Time-stamp: <2026-05-10>
///
/// Copyright (C) 2026, Togaware Pty Ltd
///
/// Licensed under the GNU General Public License, Version 3 (the "License");
///
/// License: https://opensource.org/license/gpl-3-0

library;

import 'package:billipod/models/bill.dart';

/// A bill annotated with its source.
///
/// [sourceName] is null for the user's own bills, or the pod username of the
/// person who shared the bill when it comes from an external POD.

class TaggedBill {
  const TaggedBill(
    this.bill,
    this.sourceName, {
    this.canEdit = false,
    this.fileUrl,
    this.ownerWebId,
  });

  final Bill bill;

  /// Null for own bills; the pod username (e.g. `alice`) for shared bills.
  final String? sourceName;

  /// True when the shared source has write or control permission.
  final bool canEdit;

  /// Full URL to the source bills.ttl — needed to save edits back.
  final String? fileUrl;

  /// The WebID of the shared source owner — needed by writeExternalPod.
  final String? ownerWebId;

  bool get isOwn => sourceName == null;
}

/// Represents a Solid POD that has shared its bills.ttl with the current user.

class SharedSource {
  SharedSource({
    required this.webId,
    required this.name,
    required this.fileUrl,
    required this.canEdit,
    this.bills = const [],
    this.isActive = true,
    this.isLoading = false,
  });

  /// The full WebID of the owner, used as the unique identifier.
  final String webId;

  /// Pod username extracted from the WebID (first path segment).
  final String name;

  /// Full URL to their bills.ttl file.
  final String fileUrl;

  /// True when the granted permissions include write or control access.
  final bool canEdit;

  /// Bills loaded from their POD.
  List<Bill> bills;

  /// Whether their bills are currently included in the active views.
  bool isActive;

  /// True while their bills are being loaded.
  bool isLoading;
}
