# TODO can for sure abstract x86 out of this
# TODO set up include path for ccls to track esp headers
{ inputs }:
inputs.nixpkgs.legacyPackages."x86_64-linux".mkShell {
  name = "esp-idf";

  buildInputs = [
    inputs.nixpkgs-esp-dev.packages."x86_64-linux".esp-idf-esp32
  ];

  shellHook = ''
   export ESP32_MODULES=/var/git/env/esp32Modules
  '';
}
