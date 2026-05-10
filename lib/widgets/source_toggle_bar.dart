/// SourceToggleBar — compact FilterChip row for switching bill sources on/off.
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

import 'package:provider/provider.dart';

import 'package:billipod/services/app_provider.dart';

/// A horizontally scrollable row of [FilterChip]s, one per bill source.
///
/// The first chip is always the current user's own bills (labelled with their
/// pod username). Additional chips appear for each person who has shared their
/// bills.ttl with the current user.
///
/// Returns an empty [SizedBox] when no shared sources have been loaded, so
/// callers can include it unconditionally without any visual overhead.

class SourceToggleBar extends StatelessWidget {
  const SourceToggleBar({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    if (!provider.hasSharedSources) return const SizedBox.shrink();

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 2),
      child: Row(
        children: [
          // ── Own bills chip ──────────────────────────────────────────────
          FilterChip(
            avatar: const Icon(Icons.person, size: 14),
            label: Text(
              provider.ownName.isEmpty ? 'Me' : provider.ownName,
              style: const TextStyle(fontSize: 12),
            ),
            selected: provider.ownActive,
            visualDensity: VisualDensity.compact,
            onSelected: (_) => provider.toggleOwn(),
          ),

          // ── Shared source chips ─────────────────────────────────────────
          for (final src in provider.sharedSources) ...[
            const SizedBox(width: 6),
            FilterChip(
              avatar: src.isLoading
                  ? const SizedBox(
                      width: 12,
                      height: 12,
                      child: CircularProgressIndicator(strokeWidth: 1.5),
                    )
                  : Icon(
                      src.canEdit
                          ? Icons.edit_outlined
                          : Icons.visibility_outlined,
                      size: 14,
                    ),
              label: Text(src.name, style: const TextStyle(fontSize: 12)),
              selected: src.isActive,
              visualDensity: VisualDensity.compact,
              onSelected: src.isLoading
                  ? null
                  : (_) => provider.toggleSharedSource(src.webId),
            ),
          ],
        ],
      ),
    );
  }
}
