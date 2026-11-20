# DarkFox OS

**Eigenes, privates, bootfähiges Linux-Betriebssystem** von DarkFox Co.

Gebaut komplett über **GitHub Actions** → fertige ISO → direkt auf USB schreiben und booten.

## Status

Aktuell: Minimaler, funktionierender Live-OS-Kern (Linux Kernel + BusyBox + Syslinux).
Bootet in QEMU und auf echter Hardware von USB/CD.

Später erweiterbar zu einem vollständigen Desktop-System (Debian-basiert oder custom).

## Features (aktuell)

- Bootfähige Hybrid-ISO (BIOS)
- Statisch gelinktes BusyBox Userspace
- Minimaler Kernel
- Drop-to-Shell nach Boot
- GitHub Actions Workflow baut die ISO automatisch
- Artifact zum Download

## Schnellstart – ISO bauen

1. Gehe zu **Actions** im Repo
2. Workflow **Build DarkFox OS ISO** auswählen
3. **Run workflow** klicken
4. Nach dem Build die ISO als Artifact herunterladen

Oder lokal (Linux):

```bash
./build.sh
```

## USB erstellen

**Linux / macOS:**
```bash
sudo dd if=darkfox-os.iso of=/dev/sdX bs=4M status=progress oflag=sync
```

**Windows:** Rufus oder balenaEtcher verwenden.

**Wichtig:** `/dev/sdX` richtig wählen (`lsblk`), sonst Datenverlust!

## Testen in QEMU

```bash
qemu-system-x86_64 -cdrom darkfox-os.iso -m 512M -enable-kvm
```

## Struktur

```
DarkFox-OS/
├── .github/workflows/build.yml   # GitHub Actions
├── build.sh                      # Build-Skript
├── configs/                      # Kernel & BusyBox Configs (später)
├── rootfs/                       # Zusätzliche Rootfs-Dateien
└── README.md
```

## Roadmap

- [x] Privates Repo + CI
- [x] Minimal bootfähige ISO
- [ ] Netzwerk-Support
- [ ] Persistenter Storage / Installer
- [ ] Dark-Theme Desktop (XFCE oder Hyprland)
- [ ] Eigenes Branding + Splash
- [ ] UEFI Support
- [ ] Package Manager

## Lizenz

Privat – nur für DarkFox Co.

---

Made with 🖤 by DarkFox
