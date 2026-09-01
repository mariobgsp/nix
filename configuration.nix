# configuration.nix — minimal host, omarchy.nix does the rice
# After minimal ISO install, copy hardware-configuration.nix here: cp /etc/nixos/hardware-configuration.nix ~/nix/
{ config, pkgs, ... }:
{
  imports = [ ./hardware-configuration.nix ];
  # ponytail: keep host minimal — omarchy.nix enables hyprland/waybar/walker/AI/efficiency
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  networking.hostName = "nixos";
  networking.networkmanager.enable = true;
  time.timeZone = "Asia/Jakarta";
  i18n.defaultLocale = "en_US.UTF-8";
  users.users.mario = {
    isNormalUser = true;
    extraGroups = [ "wheel" "networkmanager" "video" "audio" ];
    shell = pkgs.zsh;
  };
  programs.zsh.enable = true;
  # hardware-configuration.nix not in repo on Arch — placeholder prevents eval fail until copied
  # on NixOS installer it will be overwritten by real one
  system.stateVersion = "25.05";
}
