{
  pkgs,
  fetchFromGitHub
}:
pkgs.stdenv.mkDerivation{
  pname = "phytool";
  version = "0.0";
  src = fetchFromGitHub {
    owner = "wkz";
    repo = "phytool";
    rev = "bcf23b0261aa9f352ee4b944e30e3482158640a4";
    hash = "sha256-8e2DVjG/2CtJ/+FLzMa1VKajJZfFqjD54XQAMY+0q3U=";
  };
  installPhase = ''
    mkdir -p $out/bin
    mv phytool $out/bin
  '';
}
