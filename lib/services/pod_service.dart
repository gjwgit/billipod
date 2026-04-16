/// PodService — save and load encrypted bills on a Solid Pod.
///
// Time-stamp: <2026-04-14>
///
/// Copyright (C) 2026, Togaware Pty Ltd
///
/// Licensed under the GNU General Public License, Version 3 (the "License");
///
/// License: https://opensource.org/license/gpl-3-0

library;

import 'dart:convert';

import 'package:flutter/foundation.dart';

import 'package:solidpod/solidpod.dart';

import 'package:billipod/models/bill.dart';

/// Handles reading and writing bills to a Solid Pod.
///
/// Bills are stored as a JSON array embedded as a literal in a Turtle (.ttl)
/// file, encrypted by solidpod.

class PodService {
  PodService._();

  static const _prefixes =
      '@prefix billipod: <https://'
      'billipod.solidcommunity.au/ont/> .\n'
      '@prefix xsd:     <http://'
      'www.w3.org/2001/XMLSchema#> .\n';

  // ── Turtle helpers ────────────────────────────────────────────────────────

  static String _buildTtl(String fileName, String json) =>
      '$_prefixes\n'
      'billipod:${fileName.replaceAll('.', '_')} a billipod:BillList ;\n'
      '  billipod:bills """$json""" .\n';

  static String? _extractJson(String ttl) {
    final match = RegExp(
      r'billipod:bills\s+"""(.*?)"""',
      dotAll: true,
    ).firstMatch(ttl);
    return match?.group(1)?.trim();
  }

  // ── Public API ────────────────────────────────────────────────────────────

  /// Save [bills] to [fileName] on the pod.
  /// Returns an error message on failure, or null on success.
  static Future<String?> saveBills(String fileName, List<Bill> bills) async {
    try {
      final json = jsonEncode(bills.map((b) => b.toJson()).toList());
      final ttl = _buildTtl(fileName, json);
      await writePod(fileName, ttl, overwrite: true);
      return null;
    } catch (e) {
      debugPrint('[PodService] saveBills error: $e');
      return e.toString();
    }
  }

  /// Load bills from [fileName] on the pod.
  /// Returns null on failure, empty list if file not yet created.
  static Future<List<Bill>?> loadBills(String fileName) async {
    try {
      final ttl = await readPod(fileName);
      if (ttl.isEmpty) return [];
      final json = _extractJson(ttl);
      if (json == null || json.isEmpty) return [];
      final list = jsonDecode(json) as List;
      return list.map((j) => Bill.fromJson(j as Map<String, dynamic>)).toList();
    } catch (e) {
      debugPrint('[PodService] loadBills error ($fileName): $e');
      return null;
    }
  }
}
