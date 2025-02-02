{
  inputs.nixpkgs.url = "github:nixos/nixpkgs/release-24.11";
  inputs.home-manager.url = "github:nix-community/home-manager/release-24.11";
  inputs.home-manager.inputs.nixpkgs.follows = "nixpkgs";

  outputs = {...}@inputs:
  let
    inherit (inputs.self.helpers) 
      dir2Set
      dir2ConfigsSet
      dir2PackageSet
      config2RunPackage;
    inherit (inputs.nixpkgs) lib;
    pkgs = inputs.nixpkgs.legacyPackages;
  in
  {
    # TODO Good way to export esp32 code via flakes?
    # TODO Shit is gonna get weird when we throw in aarch64 stuff
    homeModules              = dir2Set  lib ./homeModules;
    nixosModules             = dir2Set  lib ./nixosModules;
    nixosConfigurations      = dir2ConfigsSet inputs ./nixosConfigurations;
    packages = {
      "x86_64-linux"  = (dir2PackageSet pkgs."x86_64-linux"  ./packages)
	// config2RunPackage inputs.self.nixosConfigurations pkgs."x86_64-linux";
      "aarch64-linux" = dir2PackageSet pkgs."aarch64-linux" ./packages;
    };  
    helpers                  = import ./helpers.nix;
  };
}

