/// AppScaffold — SolidScaffold with nav for BillPod.
///
// Time-stamp: <Sunday 2026-10-11 15:31:10 +1100 Graham Williams>
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
      // 20261002 gjw Cancel on the security key prompt is not an error, and
      // must not be treated as success.
      //
      // getKeyFromUserIfRequired returns false when the prompt was dismissed
      // (solidui 1.3.0 widened it from void for exactly this). Before that,
      // _isKeySaved was set true unconditionally, so the status bar claimed a
      // cached key that was not there, and the Pod was then read with no key
      // to decrypt it — "You must first set the security key!", once per
      // file.
      //
      // Returning here leaves the user in the app with the prompt dismissed,
      // which is what Cancel should mean. The key can still be entered from
      // the status bar.

      final hasKey = await getKeyFromUserIfRequired(context, widget);
      if (!mounted) return;
      setState(() => _isKeySaved = hasKey);
      if (!hasKey) return;
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
        docsUrl: 'https://gjwgit.github.io/billipod',
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
          title: 'Bills',
          icon: Icons.home,
          tooltip:
              '**Bills**\n\nEvery bill grouped by status: Scheduled, Expected and Past.',
          child: AllScreen(),
        ),
        const SolidMenuItem(
          title: 'Scheduled',
          icon: Icons.schedule_send_outlined,
          tooltip:
              '**Scheduled**\n\nPayments that have been notified and scheduled.',
          child: ScheduledScreen(),
        ),
        const SolidMenuItem(
          title: 'Expected',
          icon: Icons.upcoming_outlined,
          tooltip: '**Expected**\n\nBills expected but not yet notified.',
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
          title: 'Export/Import',
          icon: Icons.save_alt,
          tooltip:
              '**Export/Import**\n\n'
              'Export and import all bills as JSON or view as PDF.',
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
