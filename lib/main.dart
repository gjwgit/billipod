/// BillPod — bill management with Solid Pod storage.
///
// Time-stamp: <2026-04-14>
///
/// Copyright (C) 2026, Togaware Pty Ltd
///
/// Licensed under the GNU General Public License, Version 3

library;

import 'package:flutter/material.dart';

import 'package:provider/provider.dart';
import 'package:solidui/solidui.dart';

import 'package:billpod/app_scaffold.dart';
import 'package:billpod/constants/app.dart';
import 'package:billpod/services/app_provider.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SolidSecurityKeyCentralManager.instance;
  runApp(
    ChangeNotifierProvider(
      create: (_) => AppProvider(),
      child: const BillPodApp(),
    ),
  );
}

class BillPodApp extends StatefulWidget {
  const BillPodApp({super.key});

  @override
  State<BillPodApp> createState() => _BillPodAppState();
}

class _BillPodAppState extends State<BillPodApp> {
  @override
  void initState() {
    super.initState();
    _initTheme();
    solidThemeNotifier.addListener(() => setState(() {}));
  }

  Future<void> _initTheme() async {
    await solidThemeNotifier.initialize();
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: appName,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF1A5276)),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1A5276),
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      themeMode: solidThemeNotifier.themeMode,
      home: SolidLogin(
        required: false,
        appDirectory: appDirectory,
        title: appName.toUpperCase(),
        image: const AssetImage('assets/images/app_image.jpg'),
        logo: const AssetImage('assets/images/app_icon.png'),
        link: 'https://github.com/gjwgit/billpod',
        child: const AppScaffold(),
      ),
    );
  }
}
