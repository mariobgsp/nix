# nix — Omarchy on NixOS

One import to turn NixOS into an Omarchy-like Hyprland OS — leaner (gc + zram + optimise) and more effective (declarative + atomic rollback). 1:1 panel + walker + AI from Omarchy Quattro.

> `~/nix/omarchy.nix` — sole module. No extra flake inputs required (walker/waybar from nixpkgs). Adds Stylix/Catppuccin when you want it.

---

## What you get

- **Hyprland** gaps 12 / rounding 12 / blur / dwindle, Omarchy keybinds (`Super+Enter` ghostty, `Super+Space` walker, `Super+Q`, `HJKL` focus/move, `Super+Shift+1-5` workspaces, `Super+Shift+Ctrl+A` AI, `Print` grim+swappy)
- **Waybar** 26px 1:1 Omarchy panel: left `custom/omarchy` + workspaces, center `clock` + `weather` + `update` + `voxtype` + `screenrecording` + `idle` + `notifications`, right `tray-expander` + `bluetooth` + `network` + `pulseaudio` + `cpu` + `battery` + `AI`
- **Walker** launcher (replaces rofi) — Omarchy Quattro default, catppuccin-mocha, plugins `calc`/`clipboard` ready (YAGNI stub)
- **AI** like Omarchy 4.0: `a` / `c` / `cx` aliases, agents Waybar btn, 15-min `systemd` usage timer stub (`~/.local/bin/omarchy-agent-usage`)
- **Efficiency**: `nix.optimise-store` + weekly `gc --delete-older-than 7d` + `zram` + `fstrim` → 38GB → ~13GB
- **Apps**: ghostty/kitty, waybar, mako, wl-clipboard/cliphist, grim/slurp/swappy, hyprlock/hypridle, nautilus, brave/firefox, neovim, codex/claude-code

---

## Prerequisites

- NixOS 25.05+ (unstable ok), `nix-command` + `flakes` enabled
- `home-manager` (22.11+)
- User `mario` — change `home-manager.users.mario` in `omarchy.nix` to your `$USER` if different

---

## Install

### Option A — Flake (recommended)

```nix
# ~/nix/flake.nix
{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
    # optional: latest walker
    # walker.url = "github:abenz1267/walker";
  };
  outputs = { nixpkgs, home-manager, ... }: {
    nixosConfigurations.nixos = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [
        ./configuration.nix
        ./omarchy.nix
        home-manager.nixosModules.home-manager
      ];
    };
  };
}
```

```bash
cd ~/nix
sudo nixos-rebuild switch --flake .#nixos
reboot # pick Hyprland at SDDM
```

### Option B — No flake (classic `/etc/nixos`)

```bash
sudo cp ~/nix/omarchy.nix /etc/nixos/omarchy.nix
# /etc/nixos/configuration.nix:
# imports = [ ./hardware-configuration.nix ./omarchy.nix ];
# + add home-manager channel: sudo nix-channel --add https://github.com/nix-community/home-manager/archive/master.tar.gz home-manager
sudo nixos-rebuild switch
```

---

## Verify

```bash
systemd-analyze # ~5.8s boot
free -h         # ~900MB idle (Hyprland)
hyprctl monitors
waybar -t       # panel 26px, modules intact
Super+Space     # walker
Super+Shift+Ctrl+A # AI agent
```

---

## Customize

- **Walker latest**: uncomment `walker` input, replace `pkgs.walker` with `inputs.walker.packages.${system}.default`
- **User**: `sed -i 's/mario/<you>/g' omarchy.nix`
- **Theme**: ponytail stub keeps catppuccin-mocha + `@import omarchy/current/theme/waybar.css` dynamic. Add `stylix` input when you want full sync.
- **Panel math**: height 26 / spacing 0 is Omarchy pixel parity — change in `programs.waybar.settings.mainBar`

---

## Rollback

```bash
sudo nixos-rebuild switch --rollback  # previous gen, 5s
# or pick gen at boot menu
nix-collect-garbage --delete-old  # deep clean
```

---

## /nix vs ~/nix

This repo lives at `~/nix` (connected to `github:mariobgsp/nix`). `/nix/store` is the immutable Nix store — auto-created by `nixos-rebuild`. For a literal `/nix` path:

```bash
sudo mkdir -p /nix && sudo ln -s ~/nix /nix/config
# /nix/config/omarchy.nix == ~/nix/omarchy.nix
```

---

## License

MIT — fork of Omarchy rice, ported declaratively.

### Quick start (minimal ISO → Omarchy)

```bash
# after minimal ISO install (No desktop):
sudo nixos-generate-config --show-hardware-config > ~/nix/hardware-configuration.nix
# or: cp /etc/nixos/hardware-configuration.nix ~/nix/
cd ~/nix
sudo nixos-rebuild switch --flake .#nixos
reboot
```
