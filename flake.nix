{
  description = "mariobgsp/nix — Omarchy on NixOS (1:1 Hyprland + walker + waybar)";
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
    # optional: latest walker — uncomment when you want git tip
    # walker.url = "github:abenz1267/walker";
  };
  outputs = { self, nixpkgs, home-manager, ... }@inputs: {
    nixosConfigurations.nixos = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [
        ./configuration.nix
        ./omarchy.nix
        home-manager.nixosModules.home-manager
        {
          # ponytail: home-manager needs to know to use global pkgs
          home-manager.useGlobalPkgs = true;
          home-manager.useUserPackages = true;
        }
      ];
    };
    # for installer: nixosConfigurations.installer if you build ISO later
  };
}
