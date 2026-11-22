# DarkFox OS - Changelog

Newest changes are on top. Every release shows the top section.
Status: **confirmed** = seen on the device or in the build log, **untested** = built, but not checked yet.

## 2026-11-22 - Storage, design, startup

### Fixed
- **Setup reported "storage could not be created" although it had been created.** The check ran as a normal user and could not see the new partition. The result of the creation step is now what counts, and the check runs with administrator rights. (bug confirmed, fix untested)
- **Box characters in the error window** (progress display of the formatting step) removed. (untested)
- **Selection was not orange.** New own theme "DarkFox" (Arc-Dark with an orange accent). (bug confirmed, fix untested)
- **Taskbar was missing completely.** The custom panel configuration is removed, XFCE uses its default panel again. Colours now come from the theme only. (bug confirmed, fix untested)
- **"Install Debian" on the desktop** is now "Install DarkFox OS" with the fox icon. (bug confirmed, fix untested)
- **Drive icons** ("Ohne Titel", "Dateisystem", "persistence") are hidden on the desktop. (untested)
- **Images** (wallpaper, logo) are created with 8 bit to avoid colour errors. (untested)

### Changed
- **Storage on the stick** keeps only `/home`, `/etc`, `/usr`, `/opt` and `/var/lib` instead of the whole system. This writes less to the slow stick. (untested)
- **Faster startup:** no waiting for the network, store background service off, Docker and time-based services off at boot, languages generated in advance. (untested)
- **Diagnose tool extended:** boot time, slowest services, panel, storage. New: `darkfox-diagnose text` copies the log without a window to a second stick (for a black screen: `Ctrl`+`Alt`+`F2`, login `root` / `live`).

### Still open
- **Black screen on the second start** (after the storage was created). Cause unknown, a diagnose log is needed.
- **Slow startup.** Part of it is the USB 2.0 stick.
- **Custom taskbar in the DarkFox design** is postponed until the default panel is confirmed to appear.

## 2026-11-22 - Build error fixed
- The build stopped because `chmod` ran on `darkfox-store` before the file was created. (confirmed in the build log, fixed)
- Also confirmed in the same log: all packages found, WiFi driver `wl` built for kernel 6.1.0-56, VS Code installed.

## Earlier - Initial setup
- **WiFi for MacBook (Broadcom BCM4331):** `wl` driver via DKMS, `b43` as fallback. (driver confirmed in the build, WiFi on the device untested)
- **`sudo` asked for a password** because the no-password rule was overridden. The rule is now named `zz-darkfox-nopasswd`. (bug confirmed in the log)
- **Login:** user `darkfox` is created during the build, automatic login. (confirmed, desktop appears)
- **Boot menu removed** (BIOS and UEFI), start through the boot splash. (untested)
- **System is called DarkFox OS** instead of Debian (os-release, login text, installer). The kernel still reports itself as Debian.
- **DarkFox OS Store** (GNOME Software with Debian packages and Flathub). (untested)
- **Programs:** development tools (GCC, Python, Node, Git, VS Code ...), Doom (Freedoom), LibreOffice, GIMP and more. Big packages are in the extra list.
- **Design:** fox logo, boot splash, wallpaper, login screen, terminal colours. (wallpaper confirmed)
- **Diagnose tool** with copying to a second USB stick. (confirmed)
