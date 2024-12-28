{ inputs }:
let
  pkgs = inputs.nixpkgs.legacyPackages."x86_64-linux";
in
pkgs.mkShell {
  name = "tasmota";

  buildInputs = with pkgs; [
    platformio
  ];

  packages = [
    (pkgs.python3.withPackages (python-pkgs: [
      python-pkgs.pip
    ]))
  ];

  shellHook = ''
    
  '';
}
