# nix — Omarchy on NixOS

One import to turn NixOS into an Omarchy-like Hyprland OS — leaner (gc + zram + optimise) and more effective (declarative + atomic rollback). 1:1 panel + walker + AI from Omarchy Quattro.

## Repo layout

```
~/nix/
├── flake.nix                 # nixosConfigurations.nixos — nixpkgs + home-manager, imports configuration.nix + omarchy.nix
├── configuration.nix         # minimal host (boot, networking, user mario) — omarchy.nix does the rice
├── hardware-configuration.nix# placeholder on Arch, overwritten by nixos-generate-config on NixOS
├── omarchy.nix               # sole Omarchy module — Hyprland + Waybar 26px + Walker + AI + efficiency
└── README.md                 # this file
```

> `omarchy.nix` alone needs no extra flake inputs (walker/waybar from nixpkgs). Add Stylix/Catppuccin when you want full theme sync.

---

## What you get

- **Hyprland** gaps 12 / rounding 12 / blur / dwindle, Omarchy keybinds (`Super+Enter` ghostty, `Super+Space` walker, `Super+Q`, `HJKL` focus/move, `Super+Shift+1-5` workspaces, `Super+Shift+Ctrl+A` AI, `Print` grim+swappy)
- **Waybar** 26px 1:1 Omarchy panel: left `custom/omarchy` + workspaces, center `clock` + `weather` + `update` + `voxtype` + `screenrecording` + `idle` + `notifications`, right `tray-expander` + `bluetooth` + `network` + `pulseaudio` + `cpu` + `battery` + `AI`
- **Walker** launcher (Omarchy Quattro default, catppuccin-mocha)
- **AI** like Omarchy 4.0: `a` / `c` / `cx` aliases, agents Waybar btn, 15-min `systemd` usage timer
- **Efficiency**: `nix.optimise-store` + weekly `gc --delete-older-than 7d` + `zram` + `fstrim` → 38GB → ~13GB
- **Apps**: ghostty/kitty, waybar, mako, wl-clipboard/cliphist, grim/slurp/swappy, hyprlock/hypridle, nautilus, brave/firefox, neovim, codex/claude-code

---

## Prerequisites

- NixOS 25.05+ (unstable ok), `nix-command` + `flakes` enabled
- `home-manager`
- User `mario` — change `home-manager.users.mario` in `omarchy.nix` if different

---

## Install

### Minimal ISO → Omarchy (recommended)

Start from **NixOS minimal ISO** (No desktop). GNOME/KDE ISOs work but leave bloat to clean.

```bash
# 1. After first boot on NixOS:
sudo nixos-generate-config --show-hardware-config > ~/nix/hardware-configuration.nix
# or: cp /etc/nixos/hardware-configuration.nix ~/nix/hardware-configuration.nix

# 2. Build
cd ~/nix
sudo nixos-rebuild switch --flake .#nixos
reboot # pick Hyprland at SDDM
```

`flake.nix` already wires `configuration.nix + omarchy.nix + home-manager` — no `/etc/nixos` edit needed.

### Classic `/etc/nixos` (no flake)

```bash
sudo cp ~/nix/omarchy.nix /etc/nixos/omarchy.nix
# /etc/nixos/configuration.nix: imports = [ ./hardware-configuration.nix ./omarchy.nix ];
sudo nixos-rebuild switch
```

---

## Verify

```bash
systemd-analyze # ~5.8s boot
free -h         # ~900MB idle
hyprctl monitors
Super+Space     # walker
Super+Shift+Ctrl+A # AI agent
```

---

## Customize

- **Walker latest git**: uncomment `walker` in `flake.nix`, replace `pkgs.walker` with `inputs.walker.packages.${system}.default`
- **User**: `sed -i 's/mario/<you>/g' omarchy.nix configuration.nix`
- **Theme**: uses catppuccin-mocha + `@import omarchy/current/theme/waybar.css` dynamic. Add `stylix` when you want full sync.

---

## Rollback

```bash
sudo nixos-rebuild switch --rollback
nix-collect-garbage --delete-old
```

---

## /nix vs ~/nix

Repo lives at `~/nix` (`github:mariobgsp/nix`). `/nix/store` is immutable Nix store auto-created by rebuild. For literal `/nix` path:

```bash
sudo mkdir -p /nix && sudo ln -s ~/nix /nix/config
```

---

## License

MIT — Omarchy rice ported declaratively.
