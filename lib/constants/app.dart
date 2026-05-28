/// BillPod - app-wide constants.
///
// Time-stamp: <Thursday 2026-05-28 14:10:23 +1000 Graham Williams>
///
/// Copyright (C) 2026, Togaware Pty Ltd
///
/// Licensed under the GNU General Public License, Version 3 (the "License");
///
/// License: https://opensource.org/license/gpl-3-0
//
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
// this program.  If not, see <https://opensource.org/license/gpl-3-0>.
///
/// Authors: Graham Williams

library;

const String appName = 'BilliPod';

/// Application title displayed as the window title.

const String appTitle = 'BilliPod - Manage Your Bills';

/// Text shown in the SolidScaffold About dialog (accessed via the appbar
/// info button). Supports basic Markdown.

const String aboutText =
    'BilliPod supports the management of your bills, whether that might be upcoming, scheduled, '
    'or past bills. A common workflow is to add a regular bill scheduled for the '
    'next payment. When you verify the payment within the app '
    'tap the **Duplicate** button to place the next bill according to the **Frequency** in the '
    '**Expected** list so that you can monitor it.';

const String appDirectory = 'billipod';
const String billsFileName = 'bills.ttl';

/// How many months ahead to expand recurring bills.
const int expansionMonths = 12;

/// Payment method options.
const List<String> paymentMethods = [
  'Direct Debit',
  'BPAY',
  'Bank Transfer',
  'Credit Card',
  'Debit Card',
  'Cheque',
  'Cash',
  'PayPal',
  'Other',
];

/// Notification method options.
const List<String> notificationMethods = [
  'Email',
  'Post',
  'SMS',
  'App',
  'None',
  'Other',
];
