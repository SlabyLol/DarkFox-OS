# DarkFox OS

**Eigenes, privates, bootfähiges Linux-Betriebssystem** von DarkFox Co.

Vollständige Live-ISO mit **GUI (XFCE)**, gebaut komplett über **GitHub Actions** → USB-bootable.

## Was ist drin?

- **Debian** Basis (aktuell stable/trixie oder bookworm)
- **XFCE Desktop** (leicht, schnell, gut für Dark Theme)
- Dark Theme + DarkFox Branding
- Browser, Dateimanager, Terminal, Network Manager, etc.
- Live-System + optional Installer
- Hybrid-ISO (BIOS + UEFI)

## So baust du die ISO

1. Repo öffnen → **Actions**
2. Workflow **Build DarkFox OS ISO** auswählen
3. **Run workflow** klicken
4. Nach dem Build (ca. 30–70 Min) Artifact `darkfox-os-iso` herunterladen

## USB erstellen

```bash
sudo dd if=darkfox-os-*.iso of=/dev/sdX bs=4M status=progress oflag=sync
```

Windows: **Rufus** oder **balenaEtcher**.

## Testen

```bash
qemu-system-x86_64 -cdrom darkfox-os-*.iso -m 2048 -enable-kvm -vga virtio
```

## Anpassen

Alles liegt unter `config/`:

- `config/package-lists/` → Pakete hinzufügen/entfernen
- `config/includes.chroot/` → eigene Dateien, Themes, Wallpaper
- `config/hooks/` → Scripts beim Build
- `auto/config` → live-build Einstellungen

## Roadmap

- [x] Privates Repo + CI
- [x] Minimaler Kernel+BusyBox Build (Archiv)
- [x] Volles GUI-System mit XFCE
- [ ] Stärkeres DarkFox Branding (Logo, Splash, Grub Theme)
- [ ] Mehr Apps (LibreOffice, VSCodium, Steam optional)
- [ ] Persistenter Modus / Calamares Installer
- [ ] Hyprland Variante (später)

## Lizenz

Privat – nur für DarkFox Co.

---

Made with 🖤 by DarkFox
