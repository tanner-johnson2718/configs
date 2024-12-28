{
  inputs.nixpkgs.url = "github:nixos/nixpkgs/release-24.11";
  inputs.home-manager.url = "github:nix-community/home-manager/release-24.11";
  inputs.home-manager.inputs.nixpkgs.follows = "nixpkgs";
  inputs.nixpkgs-esp-dev.url = "github:mirrexagon/nixpkgs-esp-dev";

  outputs = {...}@inputs:
  let
    inherit (inputs.self.helpers.nixHelpers) 
      dir2Set
      dir2Set'
      dir2ConfigsSet;
    inherit (inputs.nixpkgs) lib;
  in
  {
    # TODO Good way to export esp32 code via flakes?
    devShells."x86_64-linux" = dir2Set' lib {inherit inputs;} ./devShells ; 
    homeModules              = dir2Set  lib ./homeModules;
    nixosModules             = dir2Set  lib ./nixosModules;
    nixosConfigurations      = dir2ConfigsSet lib inputs ./nixosConfigurations;
    helpers             =
      { 
	scriptBuilder = import ./helpers/scriptBuilder.nix;
	nixHelpers = import ./helpers/nixHelpers.nix;
      };
  };
}

