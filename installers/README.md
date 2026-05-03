<!-- markdownlint-disable MD013 -->

# Billi Pod Installers

Flutter supports multiple platform targets. Flutter based apps can run
native on Android, iOS, Linux, MacOS, and Windows, as well as directly
in a browser from the web. Flutter functionality is essentially
identical across all platforms so the experience across different
platforms will be very similar.

Visit the
[CHANGELOG](https://github.com/gjwgit/billipod/blob/dev/CHANGELOG.md)
for the latest updates.

Run the app online: [**web**](https://billipod.solidcommunity.au).

Download the latest version:

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

## Prerequisite

There are no specific prerequisites for installing and running the
app.

## Android

You can side load the latest version of the app by downloading the
[installer](https://solidcommunity.au/installers/billipod.apk)
through your Android device's browser. This will download the app to
your Android device. Then visit the Downloads folder (choosing the
menu option in the browser) where you can click on the
`billipod.apk` file. Your browser will ask if you would like to
installing the app locally.

## Linux

### Deb Install for Debian/Ubuntu

Download
[billipod_amd64.deb](https://solidcommunity.au/installers/billipod_amd64.deb)
and install:

```bash
wget https://solidcommunity.au/installers/billipod_amd64.deb -O billipod_amd64.deb
sudo dpkg --install billipod_amd64.deb
```

### Linux Snap Install

Download
[billipod_amd64.snap](https://solidcommunity.au/installers/billipod_amd64.snap)
and install:

```bash
wget https://solidcommunity.au/installers/billipod_amd64.snap -O billipod_amd64.snap
sudo snap install --dangerous billipod_amd64.snap
```

### Linux Zip Install

Download
[billipod-linux.zip](https://solidcommunity.au/installers/billipod-linux.zip)

To try it out:

```bash
wget https://solidcommunity.au/installers/billipod-linux.zip -O billipod-linux.zip
unzip billipod-linux.zip -d billipod
./billipod/billipod
```

To install for the local user and to make it known to GNOME and KDE
with a desktop icon for their desktop (which is automatically done
using the deb or snap installations), begin by downloading the **zip**
and installing that into a local folder:

```bash
unzip billipod-linux.zip -d ${HOME}/.local/share/billipod
```

Then set up your local installation (only required once):

```bash
ln -s ${HOME}/.local/share/billipod/billipod ${HOME}/.local/bin/
wget https://raw.githubusercontent.com/gjwgit/billipod/dev/installers/app.desktop -O ${HOME}/.local/share/applications/billipod.desktop
sed -i "s/USER/$(whoami)/g" ${HOME}/.local/share/applications/billipod.desktop
mkdir -p ${HOME}/.local/share/icons/hicolor/256x256/apps/
wget https://github.com/gjwgit/billipod/raw/dev/installers/app.png -O ${HOME}/.local/share/icons/hicolor/256x256/apps/billipod.png
```

To install for any user on the computer:

```bash
sudo unzip billipod-linux.zip -d /opt/billipod
sudo ln -s /opt/billipod/billipod /usr/local/bin/
wget https://raw.githubusercontent.com/gjwgit/billipod/dev/installers/app.desktop -O ${HOME}/usr/local/share/applications/billipod.desktop
wget https://github.com/gjwgit/billipod/raw/dev/installers/app.png -O ${HOME}/use/local/share/icons/billipod.png
```

Once installed you can run the app from the GNOME desktop through
Alt-F2 and type `billipod` then Enter.

## macOS

### macOS Zip Install

Download
[billipod-macos.zip](https://solidcommunity.au/installers/billipod-macos.zip).

Open the downloaded file on your Mac. Then, holding the Control key
click on the app icon to display a menu. Choose `Open`. Then accept
the warning (or give permission to install the app) to then run the
app. The app should run without the warning next time.

## Web -- No Installation Required

No installer is required for a browser based experience of
Billipod. Simply visit
[https://billipod.solidcommunity.au](https://billipod.solidcommunity.au).

Also, your Web browser will provide an option in its menus to install
the app locally, which can add an icon to your home screen to start
the web-based app directly.

## Windows

### Windows Self Extracting Archive

Download and run the self extracting archive
[billipod-windows-inno.exe](https://solidcommunity.au/installers/billipod-windows-inno.exe)
to self install the app on Windows.
