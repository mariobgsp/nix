# omarchy.nix — one import to make NixOS an Omarchy-like Hyprland OS
# More efficient than Omarchy (gc + optimise + zram) and more effective (declarative + rollback)
#
# Usage in flake.nix:
#   inputs.home-manager.url = "github:nix-community/home-manager";
#   outputs = { nixpkgs, home-manager, ... }: {
#     nixosConfigurations.nixos = nixpkgs.lib.nixosSystem {
#       modules = [ ./configuration.nix ./omarchy.nix home-manager.nixosModules.home-manager ];
#     };
#   }
# Or without flake: imports = [ ./omarchy.nix ]; in /etc/nixos/configuration.nix (needs home-manager)
#
# ponytail: single module, no extra flake inputs (stylix/catppuccin optional). Add when you want full theme sync.

{ config, pkgs, lib, ... }:

{
  # --- Efficiency (beats Omarchy disk/CPU) ---
  nix.settings.auto-optimise-store = true;
  nix.gc = { automatic = true; dates = "weekly"; options = "--delete-older-than 7d"; };
  nix.settings.experimental-features = [ "nix-command" "flakes" ];
  services.fstrim.enable = true;
  zramSwap.enable = true; # ponytail: zram ~ better than swap partition, disable if RAM >64GB and you care about raw perf
  services.thermald.enable = true;
  services.power-profiles-daemon.enable = true;

  # --- Core OS (Omarchy base) ---
  services.displayManager.sddm.enable = true;
  services.displayManager.sddm.wayland.enable = true;
  services.displayManager.autoLogin.enable = false;
  programs.hyprland = {
    enable = true;
    xwayland.enable = true;
  };
  xdg.portal.enable = true;
  xdg.portal.extraPortals = [ pkgs.xdg-desktop-portal-hyprland pkgs.xdg-desktop-portal-gtk ];
  security.polkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    pulse.enable = true;
    jack.enable = true;
  };
  hardware.bluetooth.enable = true;
  services.blueman.enable = true;
  fonts.packages = with pkgs; [ jetbrains-mono nerd-fonts.jetbrains-mono inter geist-font ];

  environment.systemPackages = with pkgs; [
    ghostty kitty # ghostty primary like Omarchy, kitty fallback
    waybar
    walker # synced — omarchy walker (was rofi)
    mako libnotify
    wl-clipboard cliphist grim slurp swappy hyprpicker hypridle hyprlock
    brightnessctl pamixer pavucontrol
    nautilus # file manager like Omarchy
    brave firefox
    neovim git curl wget
    # AI agents — same as Omarchy 4.0
    codex claude-code
  ];

  # --- Home-manager Omarchy rice (Hyprland + Waybar + binds + AI) ---
  home-manager.users.mario = { pkgs, ... }: {
    home.stateVersion = "25.05";
    programs.home-manager.enable = true;

    # Hyprland — gaps/rounding/blur/animations like Omarchy
    wayland.windowManager.hyprland = {
      enable = true;
      settings = {
        "$mod" = "SUPER";
        "$term" = "ghostty";
        "$menu" = "walker";
        exec-once = [ "waybar" "mako" "wl-paste --watch cliphist watch" "hypridle" ];
        monitor = [ ",preferred,auto,1" ];
        general = {
          gaps_in = 6;
          gaps_out = 12;
          border_size = 2;
          "col.active_border" = "rgba(cba6f7ff) rgba(89b4faff) 45deg";
          "col.inactive_border" = "rgba(595959aa)";
          layout = "dwindle";
        };
        decoration = {
          rounding = 12;
          active_opacity = 1.0;
          inactive_opacity = 0.97;
          blur = { enabled = true; size = 6; passes = 3; new_optimizations = true; };
          shadow.enabled = false;
        };
        animations = {
          enabled = true;
          bezier = "myBezier, 0.05, 0.9, 0.1, 1.05";
          animation = [
            "windows, 1, 4, myBezier"
            "windowsOut, 1, 4, default, popin 80%"
            "border, 1, 8, default"
            "fade, 1, 4, default"
            "workspaces, 1, 4, myBezier, slide"
          ];
        };
        dwindle = { pseudotile = true; preserve_split = true; };
        input = {
          kb_layout = "us";
          follow_mouse = 1;
          touchpad.natural_scroll = true;
        };
        # Omarchy binds
        bind = [
          "$mod, Return, exec, $term"
          "$mod, Q, killactive,"
          "$mod, Space, exec, $menu"
          "$mod SHIFT, Q, exit,"
          "$mod, F, fullscreen,"
          "$mod, V, togglefloating,"
          "$mod, H, movefocus, l"
          "$mod, L, movefocus, r"
          "$mod, K, movefocus, u"
          "$mod, J, movefocus, d"
          "$mod SHIFT, H, movewindow, l"
          "$mod SHIFT, L, movewindow, r"
          "$mod SHIFT, K, movewindow, u"
          "$mod SHIFT, J, movewindow, d"
          "$mod, 1, workspace, 1"
          "$mod, 2, workspace, 2"
          "$mod, 3, workspace, 3"
          "$mod, 4, workspace, 4"
          "$mod, 5, workspace, 5"
          "$mod SHIFT, 1, movetoworkspace, 1"
          "$mod SHIFT, 2, movetoworkspace, 2"
          "$mod SHIFT, 3, movetoworkspace, 3"
          "$mod SHIFT, 4, movetoworkspace, 4"
          "$mod SHIFT, 5, movetoworkspace, 5"
          # Omarchy AI
          "SUPER SHIFT CTRL, A, exec, ghostty -e bash -c 'a; exec zsh'"
          ", Print, exec, grim -g \"$(slurp)\" - | swappy -f -"
        ];
        bindm = [ "$mod, mouse:272, movewindow" "$mod, mouse:273, resizewindow" ];
        windowrulev2 = [ "float, class:^(walker)$" "opacity 0.95 0.95, class:^(ghostty)$" ];
      };
    };

    programs.waybar = {
      enable = true;
      # 1:1 Omarchy panel — 26px, full modules, exact style
      settings.mainBar = {
        reload_style_on_change = true;
        layer = "top"; position = "top"; spacing = 0; height = 26;
        modules-left = [ "custom/omarchy" "hyprland/workspaces" ];
        modules-center = [ "clock" "custom/weather" "custom/update" "custom/voxtype" "custom/screenrecording-indicator" "custom/idle-indicator" "custom/notification-silencing-indicator" ];
        modules-right = [ "group/tray-expander" "bluetooth" "network" "pulseaudio" "cpu" "battery" "custom/agents" ];
        "hyprland/workspaces" = {
          on-click = "activate";
          format = "{icon}";
          format-icons = { default = "\ue9b1"; "1" = "1"; "2" = "2"; "3" = "3"; "4" = "4"; "5" = "5"; active = "\uf133b"; };
          persistent-workspaces = { "1" = []; "2" = []; "3" = []; "4" = []; "5" = []; };
        };
        "custom/omarchy" = {
          format = "<span font='omarchy'>\ue900</span>";
          on-click = "omarchy-menu";
          on-click-right = "xdg-terminal-exec";
        };
        clock = { format = "{:L%A %H:%M}"; tooltip = false; };
        "custom/weather" = {
          exec = "$HOME/.local/share/omarchy/default/waybar/weather.sh";
          return-type = "json"; interval = 60; tooltip = false;
        };
        "custom/update" = {
          format = "\uf021"; exec = "omarchy-update-available";
          on-click = "omarchy-launch-floating-terminal-with-presentation omarchy-update";
          signal = 7; interval = 21600;
        };
        "group/tray-expander" = { orientation = "horizontal"; modules = [ "custom/expand-icon" "tray" ]; };
        "custom/expand-icon" = { format = "\uf053"; tooltip = false; };
        "custom/voxtype" = { format = "\uf130"; };
        "custom/screenrecording-indicator" = { exec = "$HOME/.local/share/omarchy/default/waybar/indicators/screen-recording.sh"; signal = 8; return-type = "json"; };
        "custom/idle-indicator" = { exec = "$HOME/.local/share/omarchy/default/waybar/indicators/idle.sh"; signal = 9; return-type = "json"; };
        "custom/notification-silencing-indicator" = { exec = "$HOME/.local/share/omarchy/default/waybar/indicators/notifications.sh"; signal = 10; return-type = "json"; };
        network = {
          format-icons = ["\uf06af" "\uf091f" "\uf0922" "\uf0925" "\uf0928"]; format = "{icon}"; format-wifi = "{icon}"; format-ethernet = "\uf0802"; format-disconnected = "\uf092e";
          interval = 3; spacing = 1; on-click = "omarchy-launch-wifi";
        };
        bluetooth = { format = "\uf0a94"; format-off = "\uf08b2"; on-click = "omarchy-launch-bluetooth"; };
        pulseaudio = {
          format = "{icon}"; on-click = "omarchy-launch-audio"; on-click-right = "pamixer -t";
          format-muted = "\ueba8"; format-icons = { headphone = "\uf025"; default = ["\uf026" "\uf027" "\uF028"]; };
        };
        cpu = { interval = 5; format = "\uf02db"; on-click = "omarchy-launch-or-focus-tui btop"; };
        battery = {
          format = "{capacity}% {icon}";
          format-icons = { default = ["\uf078a" "\uf078b" "\uf078c"]; };
          interval = 5; states = { warning = 20; critical = 10; };
        };
        "custom/agents" = { format = " AI"; tooltip = false; on-click = "ghostty -e a"; };
      };
      style = '''
        @import "../omarchy/current/theme/waybar.css";
        * { background-color: @background; color: @foreground; border: none; border-radius: 0; min-height: 0; font-family: 'JetBrainsMono Nerd Font'; font-size: 12px; }
        .modules-left { margin-left: 8px; }
        .modules-right { margin-right: 8px; }
        #workspaces button { all: initial; padding: 0 6px; margin: 0 1.5px; min-width: 9px; }
        #workspaces button.empty { opacity: 0.5; }
        #cpu, #battery, #pulseaudio, #custom-omarchy, #custom-update { min-width: 12px; margin: 0 7.5px; }
        #tray { margin-right: 16px; }
        #bluetooth { margin-right: 17px; }
        #network { margin-right: 13px; }
        #custom-expand-icon { margin-right: 18px; }
        #clock { margin-left: 8.75px; }
        #custom-weather { margin: 0 7.5px; }
        .hidden { opacity: 0; }
        #custom-screenrecording-indicator,#custom-idle-indicator,#custom-notification-silencing-indicator { min-width: 12px; margin: 0 5px 0 0; font-size: 10px; }
        #custom-screenrecording-indicator.active,#custom-idle-indicator.active { color: #a55555; }
        #custom-voxtype { min-width: 12px; margin-left: 7.5px; }
      ''';
    };

    services.mako = {
      enable = true;
      settings = {
        background-color = "#1e1e2e";
        text-color = "#cdd6f4";
        border-color = "#cba6f7";
        border-radius = 12;
      };
    };

    programs.ghostty = {
      enable = true;
      settings = {
        theme = "catppuccin-mocha";
        font-family = "JetBrainsMono Nerd Font";
        font-size = 12;
        background-opacity = 0.92;
        window-decoration = false;
      };
    };

    programs.neovim = { enable = true; viAlias = true; vimAlias = true; withNodeJs = true; };

    // walker — omarchy launcher (replaces rofi)
    // ponytail: walker from nixpkgs keeps single import; for latest git add inputs.walker.url="github:abenz1267/walker" + inputs.walker.packages.${system}.default
    home.packages = with pkgs; [ walker ];
    xdg.configFile."walker/config.toml".text = ''
      theme = "catppuccin-mocha"
      # add plugins = ["calc","clipboard"] when needed — YAGNI for now
    '';

    # --- AI integration like Omarchy 4.0 ---
    programs.zsh = {
      enable = true;
      shellAliases = {
        a = "codex --auto-approve 2>/dev/null || claude --dangerously-skip-permissions 2>/dev/null || echo 'install codex/claude'";
        c = "claude --dangerously-skip-permissions";
        cx = "codex --auto-approve";
      };
      initContent = ''
        # omarchy-like: theme sync hook (ghostty follows catppuccin)
        export EDITOR=nvim
      '';
    };
    # usage panel helper — cron every 15min like omarchy agent usage-update
    home.file.".local/bin/omarchy-agent-usage".text = ''
      #!/bin/sh
      # ponytail: stub — replace with real token tally (claude usage / codex usage)
      echo "AI usage: stub — wire to 'claude usage' / 'codex usage' when you pick provider" > /tmp/ai-usage
    '';
    systemd.user.timers.omarchy-agent-usage = {
      Unit.Description = "update AI usage every 15min (omarchy-like)";
      Timer.OnCalendar = "*:0/15"; Timer.Persistent = true; Install.WantedBy = [ "timers.target" ];
    };
    systemd.user.services.omarchy-agent-usage = {
      Unit.Description = "omarchy agent usage-update";
      Service.ExecStart = "${pkgs.bash}/bin/bash %h/.local/bin/omarchy-agent-usage";
    };
  };
}
