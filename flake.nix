{
  inputs.nixpkgs.url = "github:nixos/nixpkgs/release-24.11";
  inputs.home-manager.url = "github:nix-community/home-manager/release-24.11";
  inputs.home-manager.inputs.nixpkgs.follows = "nixpkgs";
  inputs.nixpkgs-esp-dev.url = "github:mirrexagon/nixpkgs-esp-dev";

  outputs = {...}@inputs:
  let
    inherit (inputs.self.helpers) 
      dir2Set
      dir2ConfigsSet
      dir2PackageSet;
    inherit (inputs.nixpkgs) lib;
    pkgs = inputs.nixpkgs.legacyPackages;
  in
  {
    # TODO Good way to export esp32 code via flakes?
    homeModules              = dir2Set  lib ./homeModules;
    nixosModules             = dir2Set  lib ./nixosModules;
    nixosConfigurations      = dir2ConfigsSet inputs ./nixosConfigurations;
    packages = {
      "x86_64-linux"  = dir2PackageSet pkgs."x86_64-linux"  ./packages;
      "aarch64-linux" = dir2PackageSet pkgs."aarch64-linux" ./packages;
    };
    helpers                  = import ./helpers.nix;
  };
}

