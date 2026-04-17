/// Test harness — minimal app that bypasses SolidLogin.

library;

import 'package:flutter/material.dart';

import 'package:provider/provider.dart';

import 'package:billipod/models/bill.dart';
import 'package:billipod/screens/expected_screen.dart';
import 'package:billipod/screens/past_screen.dart';
import 'package:billipod/screens/scheduled_screen.dart';
import 'package:billipod/services/app_provider.dart';

/// Build a testable app with [provider] injected, no SolidLogin/solidui.
Widget buildTestApp(AppProvider provider) =>
    ChangeNotifierProvider<AppProvider>.value(
      value: provider,
      child: MaterialApp(
        title: 'BilliPod Test',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF1A5276)),
          useMaterial3: true,
        ),
        home: const _TestScaffold(),
      ),
    );

/// Create a provider pre-loaded with bills.
AppProvider providerWith({List<Bill> bills = const []}) {
  final p = AppProvider();
  p.loadTestData(bills: bills);
  return p;
}

Bill makeBill({
  String title = 'Test Bill',
  double? amount,
  DateTime? dueDate,
  BillFrequency frequency = BillFrequency.oneOff,
  BillStatus status = BillStatus.future,
  String? note,
  bool isTemplate = false,
}) => Bill(
  title: title,
  amount: amount,
  dueDate: dueDate,
  frequency: frequency,
  status: status,
  note: note,
  isTemplate: isTemplate,
);

// ── Test scaffold ─────────────────────────────────────────────────────────────

class _TestScaffold extends StatefulWidget {
  const _TestScaffold();

  @override
  State<_TestScaffold> createState() => _TestScaffoldState();
}

class _TestScaffoldState extends State<_TestScaffold> {
  int _index = 0;

  static const _titles = ['Scheduled', 'Expected', 'Past'];
  static const _icons = [
    Icons.schedule_send_outlined,
    Icons.upcoming_outlined,
    Icons.check_circle_outline,
  ];
  static const _screens = [ScheduledScreen(), ExpectedScreen(), PastScreen()];

  @override
  Widget build(BuildContext context) => Scaffold(
    body: Row(
      children: [
        NavigationRail(
          selectedIndex: _index,
          onDestinationSelected: (i) => setState(() => _index = i),
          labelType: NavigationRailLabelType.all,
          destinations: [
            for (int i = 0; i < _titles.length; i++)
              NavigationRailDestination(
                icon: Icon(_icons[i]),
                label: Text(_titles[i]),
              ),
          ],
        ),
        const VerticalDivider(thickness: 1, width: 1),
        Expanded(child: _screens[_index]),
      ],
    ),
  );
}
