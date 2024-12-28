{inputs}:
let
  pkgs = inputs.nixpkgs.legacyPackages."x86_64-linux";
in
pkgs.mkShell {
  name = "pythonShell";
  buildInputs = [
    pkgs.python3
    pkgs.python3.pkgs.mkdocs
    pkgs.python3.pkgs.python-markdown-math
    pkgs.python3.pkgs.mkdocs-drawio-exporter
    pkgs.python3.pkgs.mkdocs-linkcheck
    pkgs.python3.pkgs.mkdocs-mermaid2-plugin
  ];
}
