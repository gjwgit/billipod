# Billi Pod Change Log

Noted here are the high level changes for the app.  Each update
includes a short user-oriented description.

You can run the app in your
[**browser**](https://billipod.solidcommunity.au) or else download and
install locally the latest version from the [Solid Community
AU](https://solidcommunity.au) or directly:

+ **Android** as
[aab](https://solidcommunity.au/installers/billipod.aab) or
[apk](https://solidcommunity.au/installers/billipod.apk);
+ **GNU/Linux** as
[deb](https://solidcommunity.au/installers/billipod_amd64.deb) or
[snap](https://solidcommunity.au/installers/billipod_amd64.snap) or
[zip](https://solidcommunity.au/installers/billipod-linux.zip);
+ **macOS** as
[dmg](https://solidcommunity.au/installers/billipod-macos.dmg) or
[zip](https://solidcommunity.au/installers/billipod-macos.zip);
+ **Windows** as
[exe](https://solidcommunity.au/installers/billipod-windows-inno.exe)
or [zip](https://solidcommunity.au/installers/billipod-windows.zip).

Contributions are welcome. Visit
[github](https://github.com/gjwgit/billipod) to submit an issue or, even
better, fork the repository yourself, update the code, and submit a
Pull Request. Coding documentation is
[available](https://solidcommunity.au/docs/billipod/).

We make this project available for free so if you appreciate the app
then please show some ❤️ and tap on the star at
[GitHub](https://github.com/gjwgit/billipod) to support our work.

This app has been pair programmed by [Graham
Williams](https://togaware.com/Graham.Williams.html) and [Claude
Code](https://claude.com/product/claude-code).

## 1.0 Secure key management

+ Report a failed shared-bill save once, not twice [1.0.17 20260808 gjw]
+ Keep the window open when a save fails on close [1.0.16 20260808 gjw]
+ Stop the save check marking fields as a side effect [1.0.15 20260808 gjw]
+ Report failed bill saves instead of failing silently [1.0.14 20260808 gjw]
+ Wait for in-flight Pod writes before closing [1.0.13 20260808 gjw]
+ Prompt to save unsaved bill on window close [1.0.12 20260808 gjw]
+ Add buttons to listing under BILLS screen [1.0.11 20260724 gjw]
+ Update to latest solidui with cached profile [1.0.10 20260719 gjw]
+ BACKUP -> Export [1.0.9 20260718 gjw]
+ Updated oidc for chrome/web support [1.0.8 20260712 tonypioneer]
+ Update solidui/solidpod dependencies [1.0.7 20260703 gjw]
+ HOME -> BILLS [1.0.6 20260628 gjw]
+ ALL BILLS -> HOME. New ABOUT. BUSY animation [1.0.5 20260622 gjw]
+ Add REFRESH button [1.0.4 20260619 gjw]
+ HOME now using markdown [1.0.3 20260614 gjw]
+ Add a introductory HOME page [1.0.2 20260614 gjw]
+ Improve SAVE behaviour [1.0.1 20260614 gjw]
+ Bump to solid_auth fix for token timeout [1.0.0 20260612 gjw]

## 0.2 Review and Robust

+ Restructure IMPORT/EXPRT as BACKUP [0.2.9 20260612 gjw]
+ Updated solidui menus to bottom [0.2.8 20260607 gjw]
+ Ensure PDF lists all bills including shared [0.2.7 20260528 gjw]
+ For PAST bill include CONFIRMED date [0.2.6 20260528 gjw]
+ Set STATUS when SCHEDULED date provided cleared [0.2.5 20260528 gjw]
+ For EXPECTED sort PDF ascending [0.2.4 20260527 gjw]
+ For SCHEDULE sort PDF ascending [0.2.3 20260527 gjw]
+ Export PDF to file or view PDF through buttons [0.2.2 20260520 gjw]
+ Integrate shared bills into the interface [0.2.1 20260510 gjw]

## 0.1 Basic Functionality and sharing

+ Add SHARING capability [0.2.0 20260510 gjw]
+ Migrate NOTES to EMACS TEXT FIELD [0.1.17 20260505 gjw]
+ Add a bill count and total liability for each page [0.1.16 20260503 gjw]
+ First/last day monthly. CONFIRMED to PAST. Next bill? [0.1.15 20260503 gjw]
+ Add an ALL tab and colour status [0.1.14 20260503 gjw]
+ Updated code. Update to solidui server list [0.1.13 20260501 gjw]
+ Do not duplicate SCHEDULED or CONFIRMED [0.1.12 20260427 gjw]
+ Support TRANSACTION FEE [0.1.11 20260427 gjw]
+ Add PDF to each of SCHEDULED/EXPECTED/PAST [0.1.10 20260420 gjw]
+ Move floating + to per page + button next to SEARCH [0.1.9 20260420 gjw]
+ Add tooltips [0.1.8 20260420 gjw]
+ Add IMPORT/EXPORT [0.1.7 20260420 gjw]
+ Bug fix saving/duplicate auto paid [0.1.6 20260419 gjw]
+ Add AutoPaid [0.1.5 20260419 gjw]
+ Remove the RECCURENCE page, cleanup ass SEARCH [0.1.4 20260418 gjw]
+ Add a star to highlight items [0.1.3 20260416 gjw]
+ Refining the functionality [0.1.2 20260416 gjw]
+ Initial functionality [0.1.1 20260414 gjw]
+ Initial template app [0.1.0 20260414 gjw]
