/// Import/Export screen widgets for BilliPod.
///
// Time-stamp: <2026-04-20>
///
/// Copyright (C) 2026, Togaware Pty Ltd
///
/// Licensed under the GNU General Public License, Version 3

library;

import 'package:flutter/material.dart';

import 'package:gap/gap.dart';

// ── Action card ───────────────────────────────────────────────────────────────

class ImportActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool loading;
  final VoidCallback onTap;

  const ImportActionCard({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.loading,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Card(
      child: ListTile(
        leading: Icon(icon, color: cs.primary),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
        subtitle: Text(
          subtitle,
          style: TextStyle(color: cs.onSurfaceVariant, fontSize: 12),
        ),
        trailing: loading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Icon(Icons.chevron_right, color: cs.onSurfaceVariant),
        onTap: loading ? null : onTap,
      ),
    );
  }
}

// ── Message banner ────────────────────────────────────────────────────────────

class ImportMessageBanner extends StatelessWidget {
  final String message;
  final bool isError;
  final ColorScheme cs;

  const ImportMessageBanner({
    super.key,
    required this.message,
    required this.isError,
    required this.cs,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isError ? cs.errorContainer : cs.secondaryContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(
            isError ? Icons.error_outline : Icons.check_circle_outline,
            color: isError ? cs.onErrorContainer : cs.onSecondaryContainer,
          ),
          const Gap(8),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color:
                    isError ? cs.onErrorContainer : cs.onSecondaryContainer,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
