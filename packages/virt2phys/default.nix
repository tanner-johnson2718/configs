{pkgs}:
pkgs.stdenv.mkDerivation rec {
  pname = "virt2phys";
  version = "0.0";
  src = ./.;
  buildPhase = ''
    $CC -o ${pname} ${pname}.c
  '';
  installPhase = ''
    mkdir -p $out/bin
    mv ${pname} $out/bin
  '';
}
