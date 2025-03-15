{
  inputs.nixpkgs.url = "github:nixos/nixpkgs/release-24.11";
  inputs.home-manager.url = "github:nix-community/home-manager/release-24.11";
  inputs.home-manager.inputs.nixpkgs.follows = "nixpkgs";

  outputs = {...}@inputs:
  let
    inherit (inputs.nixpkgs) lib;
    inherit (lib.path) append;
    pkgs = inputs.nixpkgs.legacyPackages;
    genSetOverDir = dir: f: 
      (lib.genAttrs
	(builtins.attrNames (builtins.readDir dir))
	f
      );
    importOverDir = dir: genSetOverDir dir (name: import (append dir name));
  in
  {
    homeModules = importOverDir ./homeModules; 
    nixosModules = importOverDir ./nixosModules;
    nixosConfigurations = genSetOverDir 
      ./nixosConfigurations
      (name: lib.nixosSystem {
	specialArgs = { inherit inputs; };
	modules = [ (import (append ./nixosConfigurations name)) ];
      });

    packages."x86_64-linux" = genSetOverDir
      ./packages
      (name: pkgs."x86_64-linux".callPackage (import (append ./packages name)){});
  };
}

