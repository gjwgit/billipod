/// ShareScreen — grant and revoke access to bills.ttl for another WebID.
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

import 'package:solidui/solidui.dart';

import 'package:billipod/constants/app.dart';

/// Screen for sharing the bills file with another Solid WebID.
///
/// Uses solidui's [GrantPermissionUi] to present a self-contained interface
/// for entering a WebID, granting read access to [billsFileName], and
/// revoking access when no longer needed.

class ShareScreen extends StatelessWidget {
  const ShareScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const GrantPermissionUi(
      resourceNames: [billsFileName],
      title: 'Share Bills',
      showAppBar: false,
      child: SizedBox.shrink(),
    );
  }
}
