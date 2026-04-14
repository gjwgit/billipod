/// BillPod app-wide constants.
///
// Time-stamp: <2026-04-14>
///
/// Copyright (C) 2026, Togaware Pty Ltd
///
/// Licensed under the GNU General Public License, Version 3

library;

const String appName = 'BillPod';
const String appDirectory = 'billpod';
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
