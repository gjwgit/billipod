/// AppScaffold — SolidScaffold with nav for BillPod.
///
// Time-stamp: <Sunday 2026-06-14 09:24:25 +1000 Graham Williams>
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
import 'package:billipod/screens/all_screen.dart';
import 'package:billipod/screens/expected_screen.dart';
import 'package:billipod/screens/import_screen.dart';
import 'package:billipod/screens/past_screen.dart';
import 'package:billipod/screens/scheduled_screen.dart';
import 'package:billipod/screens/share_screen.dart';
import 'package:billipod/services/app_provider.dart'
    show AppProvider, StartupPhase;
import 'package:billipod/widgets/pod_refresh_action.dart';

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
    final provider = context.read<AppProvider>();
    provider.setStartupPhase(StartupPhase.unlocking);
    try {
      final webId = await getWebId();
      if (webId == null || webId.isEmpty) return;
      if (!mounted) return;
      await getKeyFromUserIfRequired(context, widget);
      if (!mounted) return;
      setState(() => _isKeySaved = true);
      provider.setStartupPhase(StartupPhase.loading);
      await provider.loadFromPod();
    } on Exception catch (e) {
      debugPrint('[AppScaffold] key/load error: $e');
    } finally {
      provider.setStartupPhase(StartupPhase.ready);
    }
  }

  @override
  Widget build(BuildContext context) {
    context.watch<AppProvider>();
    return SolidScaffold(
      showLogout: false,
      showLogin: false,
      themeToggle: const SolidThemeToggleConfig(enabled: true),
      aboutConfig: const SolidAboutConfig(
        applicationName: appName,
        applicationIcon: Icon(Icons.receipt_long, size: 64),
        applicationLegalese: '© 2026 Togaware Pty Ltd',
        text: aboutText,
        readmeUrl: 'https://gjwgit.github.io/billipod',
      ),
      appBar: SolidAppBarConfig(
        title: appName,
        versionConfig: const SolidVersionConfig(
          changelogUrl:
              'https://github.com/gjwgit/billipod/blob/dev/CHANGELOG.md',
        ),
        actions: [
          buildPodRefreshAction(
            context: context,
            onRefresh: context.read<AppProvider>().refreshFromPod,
          ),
        ],
      ),
      menu: [
        const SolidMenuItem(
          title: 'Home',
          icon: Icons.home,
          tooltip:
              '**Home**\n\nEvery bill grouped by status: Scheduled, Expected and Past.',
          child: AllScreen(),
        ),
        const SolidMenuItem(
          title: 'Schedule',
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
        const SolidMenuItem(
          title: 'Share',
          icon: Icons.share_outlined,
          tooltip:
              '**Share**\n\n'
              'Grant or revoke access to your bills for another Solid WebID.',
          child: ShareScreen(),
        ),
        const SolidMenuItem(
          title: 'Backup',
          icon: Icons.save_alt,
          tooltip:
              '**Backup**\n\n'
              'Back up and restore all bills, or view bills as a PDF.',
          child: ImportScreen(),
        ),
      ],
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
}
