/// BilliPod — home page with a welcome/overview card.
///
// Time-stamp: <Sunday 2026-06-14 08:50:44 +1000 Graham Williams>
///
/// Copyright (C) 2026, Togaware Pty Ltd
///
/// Licensed under the GNU General Public License, Version 3 (the "License").
///
/// License: https://opensource.org/license/gpl-3-0
//
// This program is free software: you can redistribute it and/or modify it under
// the terms of the GNU General Public License as published by the Free Software
// Foundation, either version 3 of the License, or (at your option) any later
// version.
//
// This program is distributed in the hope that it will be useful, but WITHOUT
// ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
// FOR A PARTICULAR PURPOSE. See the GNU General Public License for more
// details.
//
// You should have received a copy of the GNU General Public License along with
// this program. If not, see <https://opensource.org/license/gpl-3-0>.
///
/// Authors: Graham Williams

library;

import 'package:flutter/material.dart';

import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';

import 'package:billipod/constants/app.dart';

/// The landing page, showing a welcome card describing the app.
///
/// Security-key bootstrap and the initial Pod load are handled by
/// [AppScaffold], so this page is purely informational.
class Home extends StatelessWidget {
  const Home({super.key, required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Center(
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.receipt_long,
                      size: 48,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        title,
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                MarkdownBody(
                  data:
                      '## Welcome to BilliPod!\n'
                      '\n'
                      'BilliPod helps you track your bills — expected, '
                      'scheduled, and paid — with everything stored encrypted '
                      'in your personal Solid Pod, so your data stays under '
                      'your control.\n'
                      '\n'
                      'A common workflow is to add a regular bill scheduled '
                      'for the next payment. When you verify the payment '
                      'within the app tap the **Duplicate** button to place '
                      'the next bill according to the **Frequency** in the '
                      '**Expected** list so that you can monitor it.\n'
                      '\n'
                      '### Key features\n'
                      '\n'
                      '- Scheduled, Expected and Past views of your bills\n'
                      '- Due dates, amounts, fees and payment methods\n'
                      '- Recurring and one-off bills\n'
                      '- PDF view of your bills for any date range\n'
                      '- Backup and restore all bills as JSON\n'
                      '- Share bills with other Pod owners\n'
                      '- Security key management for encrypted data\n'
                      '- Theme switching (light / dark / system)\n'
                      '\n'
                      'Use the navigation menu to get started.',
                  styleSheet: MarkdownStyleSheet.fromTheme(Theme.of(context)),
                ),
                const SizedBox(height: 16),
                Text(
                  appName,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
