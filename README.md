# BilliPod

> Bill Management with Secure and Private Solid Pod Storage

BilliPod helps you keep on top of your bills — what's expected, what's
scheduled, and what's been paid — with all data stored privately in
your own [Solid Pod](https://solidproject.org/). Your Pod sits in a
personal Data Vault on a Solid server in the cloud, where everything
is stored encrypted and stays within the Pod. No data leaves the Pod
unless you explicitly export it, so you stay in control.

---

[![Flutter](https://img.shields.io/badge/Flutter-%2302569B.svg?style=for-the-badge&logo=Flutter&logoColor=white)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/dart-%230175C2.svg?style=for-the-badge&logo=dart&logoColor=white)](https://dart.dev)

[![Github Docs](https://img.shields.io/badge/GitHub-Pages-green?logo=gitbook)](https://gjwgit.github.io/billipod)
[![GitHub Repo](https://img.shields.io/badge/GitHub-Repo-blue?logo=github)](https://github.com/gjwgit/billipod)
[![GitHub License](https://img.shields.io/github/license/gjwgit/billipod)](https://raw.githubusercontent.com/gjwgit/billipod/dev/LICENSE)
[![Github Version](https://img.shields.io/badge/dynamic/yaml?url=https://raw.githubusercontent.com/gjwgit/billipod/master/pubspec.yaml&query=$.version&label=version)](https://github.com/gjwgit/billipod/blob/dev/CHANGELOG.md)
[![Github Last Updated](https://img.shields.io/github/last-commit/gjwgit/billipod?label=last%20updated)](https://github.com/gjwgit/billipod/commits/dev/)
[![GitHub Commit Activity (dev)](https://img.shields.io/github/commit-activity/w/gjwgit/billipod/dev)](https://github.com/gjwgit/rattle/commits/dev/)
[![GitHub Issues](https://img.shields.io/github/issues/gjwgit/billipod)](https://github.com/gjwgit/billipod/issues)

[BilliPod](https://gjwgit.github.io/billipod/) is an app to manage
your bills, viewing bills through list of upcoming bills, scheduled
bills, and a history of bills paid. All bill details are securely and
privately stored encrypted on your own personal online data store
([Pod](https://solidproject.org/about)). The app is supported by
[Togaware](https://togaware.com) and implemented by [Graham
Williams](https://togaware.com/Graham.Williams.html) pair coding with
[Claude Code](https://claude.com/product/claude-code) using
[Flutter](https://flutter.dev)'s
[SolidUI](https://github.com/anusii/solidui) package for cross
platform development.

Solid Pods are a new approach to handling your personal data on the
World Wide Web and is the latest innovation from the inventor of the
WWW, Sir Tim Berners-Lee. Obtain a Pod for yourself on any Solid
server and link it to your app.

We make this project available for free so if you appreciate the app
then please show some ❤️ and tap on the star at
[GitHub](https://github.com/gjwgit/billipod) to support our work. See
the [AU Solid Community](https://solidcommunity.au) **showcase** for
many more apps using the Solid ecosystem.

The latest version of the app can be run online at
[billipod.solidcommunity.au](https://billipod.solidcommunity.au) with no
installation required though requiring a Solid login, or downloaded
and installed for your platform from the [Solid Community
AU](https://solidcommunity.au) repository:

<!-- markdownlint-disable MD036 -->
+ **Web**
  [solidcommunity](https://billipod.solidcommunity.au/);
+ **Android**
  [aab](https://solidcommunity.au/installers/billipod.aab) or
  [apk](https://solidcommunity.au/installers/billipod.apk);
+ **GNU/Linux**
  [deb](https://solidcommunity.au/installers/billipod_amd64.deb) or
  [snap](https://solidcommunity.au/installers/billipod_amd64.snap) or
  [zip](https://solidcommunity.au/installers/billipod-linux.zip);
+ **macOS**
  [dmg](https://solidcommunity.au/installers/billipod-macos.dmg) or
  [zip](https://solidcommunity.au/installers/billipod-macos.zip);
+ **Windows**
  [inno](https://solidcommunity.au/installers/billipod-windows-inno.exe) or
  [zip](https://solidcommunity.au/installers/billipod-windows.zip).

[Installation
details](https://github.com/gjwgit/billipod/blob/dev/installers/README.md)
are available for all platforms.

Contributions are welcome. Visit
[github](https://github.com/gjwgit/billipod) to submit an issue or,
even better, fork the repository yourself, update the code, and submit
a Pull Request. The app is implemented in
[Flutter](https://flutter.dev) using
[solidui](https://pub.dev/packages/solidui). Thanks.

## Introduction

Billi Pod is a Solid Flutter app to manage bills, past, scheduled, and
upcoming. It is particularly useful for recurring bills and so knowing
when bill payments are expected. You can view your Bills as filtered
lists, recording dates of notification, schedule, and due, how the
bill is to be paid, and other useful information associated with the bill.

## Quick start

The typical workflow is:

1. **Add** a regular bill, scheduled for its next payment.
2. **Mark it scheduled** once you've set up the payment.
3. **Verify the payment**, then tap the **Duplicate** button to roll the
   next instance forward into the **Expected** list, where you can monitor
   it until the next cycle.

Each bill carries forward its title, amount, frequency, payment method
and notes; only the due date advances.

---

## The five screens

A left-hand menu (or bottom navigation on narrow screens) gives you:

### Scheduled

Bills you've committed to pay — the next payment is locked in. Use this
view in the run-up to a payment date.

### Expected

Bills that you know are coming but haven't yet scheduled. The natural
landing place for newly-duplicated bills from a paid one.

### Past

Bills you've paid. Useful for record-keeping and PDF reports.

### All Bills

Everything grouped by status (Scheduled · Expected · Past), with a single
search box across all three groups. Quick way to find anything when you're
not sure which bucket it's in.

### Import / Export

Backup and restore via JSON, plus PDF export with a date-range filter.
See [Backup and report export](#backup-and-report-export) below.

---

## Adding and editing a bill

Tap the **+** button in any of the four list screens to add a bill. The
edit form captures:

+ **Title** — e.g. "Electricity", "Internet", "Rent"
+ **Amount** — formatted as a dollar value
+ **Due date** — the date you need to pay by
+ **Frequency** — one-off, monthly, every 28 days, quarterly, semi-annual,
  annual, first-of-month, last-of-month
+ **Status** — Expected / Scheduled / Past
+ **Payment method** — Direct Debit, BPAY, Bank Transfer, Credit/Debit
  Card, Cheque, Cash, PayPal, Other
+ **Notification method** — Email, Post, SMS, App, None, Other
+ **Notified date** — when the bill arrived
+ **Scheduled date** — when you set up the payment
+ **Confirmed paid date** — when the payment cleared
+ **Transaction fee** — captured separately from the amount
+ **Note** — free text for anything else
+ **Star** — mark important bills (they show with a gold background)
+ **Auto-paid** — flag bills paid automatically (e.g. by credit card)

Tap any bill to edit it. The same form opens.

---

## The Duplicate workflow

On a paid bill, look for the **copy** icon (📋). Its colour tells you what
will happen:

+ **Green** — there is no follow-on bill for the next cycle yet. Tap to
  create one in the **Expected** list, advanced by one frequency.
+ **Grey** — a follow-on bill already exists. Tapping still lets you
  create extra copies if needed.

A small dialog asks how many copies you want. This is the main way you
move from "paid" back to "expected" for the next cycle, without having
to retype the bill details.

---

## Search

Every list page has a rounded search box. Plain-text search matches:

+ Title
+ Note
+ Payment method
+ Amount (as displayed)

Clear the search with the × on the right of the field, or just delete
the text. The list updates as you type.

A help icon (?) next to the search shows these tips on long-press.

---

## Sharing bills with others

Use the **Share** screen to:

+ **Manage Access** — grant or revoke access to your `bills.ttl` for
  another Solid WebID. You choose read-only or read/write.
+ **Shared With Me** — open bills that other Pod owners have shared
  with you. Permission level (read or read/write) is shown alongside
  each source.

Shared bills appear inline in the lists with a small person-outline icon
and the source name. If you have write access, you can edit and delete
them; they save back to the owner's Pod. Read-only bills are shown but
not editable.

The **source toggle bar** at the top of each list lets you switch between
seeing only your own bills, only shared bills, or all of them combined.

---

## Backup and report export

### JSON backup

The standard way to back up. The export saves all your bills (excluding
template entries) as a single JSON file with a timestamped name like
`billipod_backup_20260520_2207.json`. Import merges entries back in,
skipping any whose IDs already exist (so re-importing a backup over an
existing list is safe).

### PDF report

Choose what to include:

+ **Scope selector** — All bills, Expected, Scheduled, or Past
+ **Date range** — optional From / To dates that filter by due date
  (inclusive). Leave either blank for an open-ended range. Bills with no
  due date are excluded when a range is set.

The PDF contains:

+ **Title block** on page 1 with the date, bill count, total dollar
  amount, and period (first–last due date)
+ **Sortable rows**, most recent due date first
+ **Total row** at the bottom showing the dollar total and the period
  length (e.g. `2 years 3 months`)
+ **Repeating column headers** on every page
+ **Page numbers** in the footer (`Page 1 of 3`)

After saving, a SnackBar offers a **View** action to open the PDF in your
system's default viewer.

For quick on-screen viewing without saving, tap the **PDF** icon (📄) on
any of the four list pages. It opens the PDF directly in the system
viewer with no save prompt — handy for a quick check or to print.

---

## About info

Tap the **info** (ℹ) button in the top app bar at any time to see a brief
about-the-app dialog with the version number and a short summary of how
BilliPod works.

---

## Data and privacy

All bills are stored in your Solid Pod as a Turtle file (`bills.ttl`) in
the `billipod/` directory. You authenticate to your Pod when you start
the app, and your security key (used to read/write the encrypted data)
is managed through the standard SolidPod flow shown in the status bar.

If you log into a fresh Pod, BilliPod creates the directory and an
empty bill file on first save. Nothing about your bills ever leaves
your Pod unless you explicitly share it with another Pod or export it
as JSON or PDF.

---

## License

GNU General Public License v3. See `LICENSE` or
<https://opensource.org/license/gpl-3-0>.

Copyright (C) 2026, Togaware Pty Ltd.
