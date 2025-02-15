{
  inputs.nixpkgs.url = "github:nixos/nixpkgs/release-24.11";
  inputs.home-manager.url = "github:nix-community/home-manager/release-24.11";
  inputs.home-manager.inputs.nixpkgs.follows = "nixpkgs";

  outputs = {...}@inputs:
  let
    inherit (inputs.nixpkgs) lib;
    pkgs = inputs.nixpkgs.legacyPackages;
    genSetOverDir = dir: f: 
      (lib.genAttrs
	(builtins.attrNames (builtins.readDir dir))
	f
      );
  in
  {
    homeModules = genSetOverDir 
      ./homeModules 
      (name: import (lib.path.append ./homeModules name));

    nixosModules = genSetOverDir  
      ./nixosModules
      (name: import (lib.path.append ./nixosModules name));
      
    nixosConfigurations = genSetOverDir 
      ./nixosConfigurations
      (name: inputs.nixpkgs.lib.nixosSystem {
	system = "x86_64-linux";
	specialArgs = { inherit inputs; };
	modules = [ 
	  (import (inputs.nixpkgs.lib.path.append ./nixosConfigurations name)) 
	];
      });

    packages."x86_64-linux" = genSetOverDir
      ./packages
      (name: pkgs.callPackage (import (pkgs.lib.path.append ./packages name)){});
  };
}

