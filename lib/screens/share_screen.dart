/// ShareScreen — grant/revoke access to your bills, and open bills shared
/// with you by others.
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
import 'package:solidpod/solidpod.dart';
import 'package:solidui/solidui.dart';

import 'package:billipod/constants/app.dart';
import 'package:billipod/screens/shared_bills_view_screen.dart';

/// A two-tab screen:
///
/// **Manage Access** — `GrantPermissionUi` to grant/revoke access to your
///   own `bills.ttl` file.
///
/// **Shared With Me** — lists everyone who has shared their `bills.ttl`
///   with you, showing the permission level, and lets you open their bills
///   in a read-only or read/write view depending on the granted access.

class ShareScreen extends StatelessWidget {
  const ShareScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const DefaultTabController(
      length: 2,
      child: Column(
        children: [
          TabBar(
            tabs: [
              Tab(icon: Icon(Icons.share_outlined), text: 'Manage Access'),
              Tab(icon: Icon(Icons.inbox_outlined), text: 'Shared With Me'),
            ],
          ),
          Expanded(
            child: TabBarView(
              children: [_ManageAccessTab(), _SharedWithMeTab()],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Tab 1: Manage Access ──────────────────────────────────────────────────────

class _ManageAccessTab extends StatelessWidget {
  const _ManageAccessTab();

  @override
  Widget build(BuildContext context) {
    return const GrantPermissionUi(
      resourceNames: [billsFileName],
      title: 'Share Bills',
      showAppBar: false,
      child: SizedBox.shrink(),
    );
  }
}

// ── Tab 2: Shared With Me ─────────────────────────────────────────────────────

class _SharedWithMeTab extends StatefulWidget {
  const _SharedWithMeTab();

  @override
  State<_SharedWithMeTab> createState() => _SharedWithMeTabState();
}

class _SharedWithMeTabState extends State<_SharedWithMeTab> {
  Future<Map<dynamic, dynamic>>? _future;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  void _refresh() {
    setState(() {
      _future = sharedResources(
        billsFileName,
        null,
      ).then((result) => result is Map ? result : <dynamic, dynamic>{});
    });
  }

  bool _canEdit(String permissions) {
    final p = permissions.toLowerCase();
    return p.contains(AccessMode.write.mode.toLowerCase()) ||
        p.contains(AccessMode.control.mode.toLowerCase());
  }

  String _displayName(String webId) {
    try {
      final segments = Uri.parse(
        webId,
      ).pathSegments.where((s) => s.isNotEmpty).toList();
      return segments.isNotEmpty ? segments.first : webId;
    } catch (_) {
      return webId;
    }
  }

  void _openSharedBills(
    BuildContext context,
    String fileUrl,
    String ownerWebId,
    bool canEdit,
  ) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => SharedBillsViewScreen(
          fileUrl: fileUrl,
          ownerWebId: ownerWebId,
          canEdit: canEdit,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return FutureBuilder<Map<dynamic, dynamic>>(
      future: _future,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final sharedResMap = snapshot.data!;

        if (sharedResMap.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.inbox_outlined,
                  size: 48,
                  color: cs.onSurfaceVariant,
                ),
                const Gap(12),
                Text(
                  'No one has shared their bills with you yet.',
                  style: TextStyle(color: cs.onSurfaceVariant),
                ),
                const Gap(16),
                FilledButton.tonal(
                  onPressed: _refresh,
                  child: const Text('Refresh'),
                ),
              ],
            ),
          );
        }

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 8, 0),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      '${sharedResMap.length} shared '
                      '${sharedResMap.length == 1 ? "file" : "files"}',
                      style: TextStyle(
                        fontSize: 12,
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.refresh, size: 20),
                    tooltip: 'Refresh',
                    onPressed: _refresh,
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(12, 4, 12, 16),
                itemCount: sharedResMap.length,
                itemBuilder: (context, index) {
                  final fileUrl = sharedResMap.keys.elementAt(index) as String;
                  final entry = sharedResMap[fileUrl] as Map<dynamic, dynamic>;
                  final ownerWebId =
                      entry[PermissionLogLiteral.owner] as String? ?? fileUrl;
                  final permissions =
                      entry[PermissionLogLiteral.permissions] as String? ?? '';
                  final canEdit = _canEdit(permissions);

                  return Card(
                    elevation: 0,
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                      side: BorderSide(color: cs.outlineVariant),
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
                      leading: CircleAvatar(
                        backgroundColor: canEdit
                            ? cs.primaryContainer
                            : cs.surfaceContainerHighest,
                        child: Icon(
                          canEdit
                              ? Icons.edit_outlined
                              : Icons.visibility_outlined,
                          size: 20,
                          color: canEdit
                              ? cs.onPrimaryContainer
                              : cs.onSurfaceVariant,
                        ),
                      ),
                      title: Text(
                        _displayName(ownerWebId),
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Gap(2),
                          Text(
                            ownerWebId,
                            style: TextStyle(
                              fontSize: 11,
                              color: cs.onSurfaceVariant,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const Gap(4),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: canEdit
                                  ? cs.primaryContainer
                                  : cs.surfaceContainerHighest,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              canEdit ? 'Read / Write' : 'Read only',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                                color: canEdit
                                    ? cs.onPrimaryContainer
                                    : cs.onSurfaceVariant,
                              ),
                            ),
                          ),
                        ],
                      ),
                      trailing: FilledButton.tonal(
                        onPressed: () => _openSharedBills(
                          context,
                          fileUrl,
                          ownerWebId,
                          canEdit,
                        ),
                        child: Text(canEdit ? 'Edit' : 'View'),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}
