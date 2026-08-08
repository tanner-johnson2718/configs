let
  nixpkgs_rev = "871b9fd269ff6246794583ce4ee1031e1da71895";
  nixpkgs_src = builtins.fetchTarball {
    url = "https://github.com/NixOS/nixpkgs/archive/${nixpkgs_rev}.tar.gz";
    sha256 = "sha256:1zn1lsafn62sz6azx6j735fh4vwwghj8cc9x91g5sx2nrg23ap9k";
  };
  pkgs = import nixpkgs_src {
    config = {};
    overlays = [];
  };
in
pkgs
