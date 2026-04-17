/// AppScaffold — SolidScaffold with nav for BillPod.
///
// Time-stamp: <2026-04-14>
///
/// Copyright (C) 2026, Togaware Pty Ltd
///
/// Licensed under the GNU General Public License, Version 3

library;

import 'package:flutter/material.dart';

import 'package:provider/provider.dart';
import 'package:solidpod/solidpod.dart';
import 'package:solidui/solidui.dart';

import 'package:billipod/constants/app.dart';
import 'package:billipod/models/bill.dart';
import 'package:billipod/pages/bill_edit.dart';
import 'package:billipod/screens/expected_screen.dart';
import 'package:billipod/screens/past_screen.dart';
import 'package:billipod/screens/scheduled_screen.dart';
import 'package:billipod/services/app_provider.dart';

class AppScaffold extends StatefulWidget {
  const AppScaffold({super.key});

  @override
  State<AppScaffold> createState() => _AppScaffoldState();
}

class _AppScaffoldState extends State<AppScaffold> {
  bool _isKeySaved = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _initKeys());
  }

  Future<void> _initKeys() async {
    try {
      final webId = await getWebId();
      if (webId == null || webId.isEmpty) return;
      if (!mounted) return;
      await getKeyFromUserIfRequired(context, widget);
      if (!mounted) return;
      setState(() => _isKeySaved = true);
      await context.read<AppProvider>().loadFromPod();
    } on Exception catch (e) {
      debugPrint('[AppScaffold] key/load error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    context.watch<AppProvider>();
    return SolidScaffold(
      showLogout: false,
      showLogin: false,
      themeToggle: const SolidThemeToggleConfig(enabled: true),
      appBar: const SolidAppBarConfig(
        title: appName,
        versionConfig: SolidVersionConfig(
          changelogUrl:
              'https://github.com/gjwgit/billipod/blob/dev/CHANGELOG.md',
        ),
      ),
      menu: [
        const SolidMenuItem(
          title: 'Scheduled',
          icon: Icons.schedule_send_outlined,
          tooltip: '**Scheduled**\n\nPayments that have been scheduled.',
          child: ScheduledScreen(),
        ),
        const SolidMenuItem(
          title: 'Expected',
          icon: Icons.upcoming_outlined,
          tooltip: '**Expected**\n\nBills expected but not yet scheduled.',
          child: ExpectedScreen(),
        ),
        const SolidMenuItem(
          title: 'Past',
          icon: Icons.check_circle_outline,
          tooltip: '**Past**\n\nBills that have been paid.',
          child: PastScreen(),
        ),
      ],
      floatingActionButton: FloatingActionButton(
        onPressed: () => _addBill(context),
        tooltip: 'Add bill',
        child: const Icon(Icons.add),
      ),
      statusBar: SolidStatusBarConfig(
        loginStatus: const SolidLoginStatus(),
        serverInfo: const SolidServerInfo(
          serverUri: SolidConfig.defaultServerUrl,
        ),
        securityKeyStatus: SolidSecurityKeyStatus(
          isKeySaved: _isKeySaved,
          title: 'BilliPod Security Keys',
          onKeyStatusChanged: (hasKey) {
            final was = _isKeySaved;
            setState(() => _isKeySaved = hasKey);
            if (hasKey && !was) {
              context.read<AppProvider>().loadFromPod();
            }
          },
        ),
      ),
    );
  }

  Future<void> _addBill(BuildContext context) async {
    final bill = await showDialog<Bill>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const BillEdit(),
    );
    if (bill != null && context.mounted) {
      context.read<AppProvider>().addBill(bill);
      await context.read<AppProvider>().saveToPod();
    }
  }
}
