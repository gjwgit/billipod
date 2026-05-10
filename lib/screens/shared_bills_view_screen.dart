/// SharedBillsViewScreen — view (and optionally edit) bills from a shared POD.
///
// Time-stamp: <2026-05-10>
///
/// Copyright (C) 2026, Togaware Pty Ltd
///
/// Licensed under the GNU General Public License, Version 3 (the "License");
///
/// License: https://opensource.org/license/gpl-3-0

library;

import 'package:flutter/material.dart';

import 'package:gap/gap.dart';
import 'package:markdown_tooltip/markdown_tooltip.dart';

import 'package:billipod/models/bill.dart';
import 'package:billipod/pages/bill_edit.dart';
import 'package:billipod/services/pod_service.dart';
import 'package:billipod/widgets/bill_tile.dart';
import 'package:billipod/widgets/bill_total_bar.dart';
import 'package:billipod/widgets/shared_read_only_tile.dart';

/// Displays the bills from a shared POD file.
///
/// [fileUrl] is the full URL of the bills.ttl file on the owner's POD.
/// [ownerWebId] is the WebID of the person who shared their bills with us.
/// [canEdit] is true when the permission includes write (or control) access.

class SharedBillsViewScreen extends StatefulWidget {
  const SharedBillsViewScreen({
    required this.fileUrl,
    required this.ownerWebId,
    required this.canEdit,
    super.key,
  });

  final String fileUrl;
  final String ownerWebId;
  final bool canEdit;

  @override
  State<SharedBillsViewScreen> createState() => _SharedBillsViewScreenState();
}

class _SharedBillsViewScreenState extends State<SharedBillsViewScreen> {
  List<Bill>? _bills;
  bool _loading = true;
  String? _error;
  String _query = '';
  final _search = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final bills = await PodService.loadBillsFromUrl(widget.fileUrl);
    if (!mounted) return;
    setState(() {
      _loading = false;
      if (bills == null) {
        _error = 'Could not load bills from ${widget.ownerWebId}';
      } else {
        _bills = bills;
      }
    });
  }

  Future<void> _save() async {
    if (_bills == null) return;
    final err = await PodService.saveBillsToUrl(
      widget.fileUrl,
      widget.ownerWebId,
      _bills!,
    );
    if (!mounted) return;
    if (err != null) {
      await showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Save failed'),
          content: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Text(err),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Saved to their POD.')));
    }
  }

  Future<void> _addBill() async {
    final bill = await showDialog<Bill>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const BillEdit(),
    );
    if (bill != null) {
      setState(() => _bills = [bill, ..._bills!]);
      await _save();
    }
  }

  Future<void> _editBill(Bill bill) async {
    final updated = await showDialog<Bill>(
      context: context,
      barrierDismissible: false,
      builder: (_) => BillEdit(bill: bill),
    );
    if (updated != null) {
      setState(() {
        _bills = [
          for (final b in _bills!)
            if (b.id == updated.id) updated else b,
        ];
      });
      await _save();
    }
  }

  Future<void> _deleteBill(Bill bill) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete bill?'),
        content: Text('"${bill.title}" will be permanently removed.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      setState(() => _bills = _bills!.where((b) => b.id != bill.id).toList());
      await _save();
    }
  }

  List<Bill> get _filtered {
    final bills = _bills ?? [];
    if (_query.isEmpty) return bills;
    final q = _query.toLowerCase();
    return bills
        .where(
          (b) =>
              b.title.toLowerCase().contains(q) ||
              (b.note?.toLowerCase().contains(q) ?? false) ||
              b.amountStr.contains(q),
        )
        .toList();
  }

  /// Short display name extracted from a WebID URL.
  String _displayName(String webId) {
    try {
      final uri = Uri.parse(webId);
      final segments = uri.pathSegments.where((s) => s.isNotEmpty).toList();
      // Typically: /username/profile/card  → take first segment
      return segments.isNotEmpty ? segments.first : webId;
    } catch (_) {
      return webId;
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final displayName = _displayName(widget.ownerWebId);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          "${widget.canEdit ? 'Edit' : 'View'}: $displayName's Bills",
        ),
        actions: [
          MarkdownTooltip(
            message: '**Refresh**\n\nReload bills from their POD.',
            child: IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _load,
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // ── Owner banner ─────────────────────────────────────────────────
          Container(
            width: double.infinity,
            color: widget.canEdit
                ? cs.primaryContainer
                : cs.surfaceContainerHighest,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Icon(
                  widget.canEdit
                      ? Icons.edit_outlined
                      : Icons.visibility_outlined,
                  size: 16,
                  color: cs.onSurfaceVariant,
                ),
                const Gap(8),
                Expanded(
                  child: Text(
                    widget.canEdit
                        ? 'You have read/write access to ${widget.ownerWebId}'
                        : 'Read-only access to ${widget.ownerWebId}',
                    style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
                  ),
                ),
              ],
            ),
          ),

          if (_loading)
            const Expanded(child: Center(child: CircularProgressIndicator()))
          else if (_error != null)
            Expanded(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.error_outline, color: cs.error, size: 40),
                    const Gap(12),
                    Text(
                      _error!,
                      textAlign: TextAlign.center,
                      style: TextStyle(color: cs.error),
                    ),
                    const Gap(16),
                    FilledButton.tonal(
                      onPressed: _load,
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            )
          else ...[
            // ── Search bar ─────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _search,
                      decoration: InputDecoration(
                        hintText: 'Search bills…',
                        prefixIcon: const Icon(Icons.search, size: 20),
                        suffixIcon: _query.isEmpty
                            ? null
                            : IconButton(
                                icon: const Icon(Icons.clear, size: 18),
                                onPressed: () {
                                  _search.clear();
                                  setState(() => _query = '');
                                },
                              ),
                        isDense: true,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 10,
                        ),
                      ),
                      onChanged: (v) => setState(() => _query = v),
                    ),
                  ),
                  if (widget.canEdit) ...[
                    const Gap(8),
                    MarkdownTooltip(
                      message: '**Add bill**\n\nCreate a new bill.',
                      child: IconButton(
                        icon: const Icon(Icons.add_circle_outline),
                        color: cs.primary,
                        onPressed: _addBill,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const Gap(8),
            BillTotalBar(bills: _filtered),

            // ── Grouped bill list ──────────────────────────────────────────
            Expanded(
              child: _filtered.isEmpty
                  ? Center(
                      child: Text(
                        _query.isEmpty
                            ? 'No bills in this shared file.'
                            : 'No bills match "$_query".',
                        style: TextStyle(color: cs.onSurfaceVariant),
                      ),
                    )
                  : _buildGroupedList(cs),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildGroupedList(ColorScheme cs) {
    final all = _filtered;
    final groups = <String, List<Bill>>{
      'Scheduled': [],
      'Expected': [],
      'Past': [],
    };
    for (final b in all) {
      switch (b.status) {
        case BillStatus.scheduled:
          groups['Scheduled']!.add(b);
        case BillStatus.future:
          groups['Expected']!.add(b);
        case BillStatus.past:
          groups['Past']!.add(b);
      }
    }
    return ListView(
      padding: const EdgeInsets.only(bottom: 16),
      children: [
        for (final entry in groups.entries)
          if (entry.value.isNotEmpty) ...[
            _groupHeader(entry.key, entry.value.length, cs),
            for (final bill in entry.value)
              widget.canEdit
                  ? _withOwnerFooter(
                      BillTile(
                        bill: bill,
                        outlineColor: switch (entry.key) {
                          'Scheduled' => Colors.green.withValues(alpha: 0.6),
                          'Past' => Colors.orange.withValues(alpha: 0.3),
                          _ => null,
                        },
                        onTap: () => _editBill(bill),
                        onDelete: () => _deleteBill(bill),
                      ),
                      cs,
                    )
                  : SharedReadOnlyTile(
                      bill: bill,
                      sourceName: _displayName(widget.ownerWebId),
                    ),
          ],
      ],
    );
  }

  /// Wraps [tile] (a BillTile Card) with a subtle owner footer strip.
  Widget _withOwnerFooter(Widget tile, ColorScheme cs) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        tile,
        Transform.translate(
          offset: const Offset(0, -6),
          child: Container(
            margin: const EdgeInsets.fromLTRB(12, 0, 12, 4),
            padding: const EdgeInsets.fromLTRB(10, 6, 10, 4),
            decoration: BoxDecoration(
              color: cs.surfaceContainerHighest,
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(10),
                bottomRight: Radius.circular(10),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.person_outline,
                  size: 11,
                  color: cs.onSurfaceVariant,
                ),
                const Gap(4),
                Text(
                  _displayName(widget.ownerWebId),
                  style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _groupHeader(String label, int count, ColorScheme cs) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Row(
        children: [
          Text(
            label.toUpperCase(),
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.8,
              color: cs.primary,
            ),
          ),
          const Gap(8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
            decoration: BoxDecoration(
              color: cs.primaryContainer,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '$count',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: cs.onPrimaryContainer,
              ),
            ),
          ),
          const Gap(8),
          Expanded(child: Divider(color: cs.outlineVariant, height: 1)),
        ],
      ),
    );
  }
}
