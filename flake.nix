{
  inputs.nixpkgs.url = "github:nixos/nixpkgs/release-24.11";
  inputs.home-manager.url = "github:nix-community/home-manager/release-24.11";
  inputs.home-manager.inputs.nixpkgs.follows = "nixpkgs";

  outputs = {...}@inputs:
  {
    nixosConfigurations = { 
      homebox = inputs.nixpkgs.lib.nixosSystem {
	specialArgs = { inherit inputs; };
	modules = [ ./homebox.nix ];
      };
    };

    homeConfigurations = import ./home.nix;
  };
}

