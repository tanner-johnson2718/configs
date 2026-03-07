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
  extra_packages = with pkgs; [
    zip
    unzip
    tree
    jq
    lsof
    tio
    fd
  ];
  nvim_packages = with pkgs; [
    cargo
    clippy
    rust-analyzer
    nil
    ccls
    xclip
    ripgrep
    tree-sitter
    nodejs
    lua-language-server
  ];
  nvim_plugins = with pkgs.vimPlugins; [
    telescope-nvim
    git-blame-nvim
    nvim-treesitter.withAllGrammars
    onedark-nvim
    vim-bbye
    rustaceanvim
    blink-cmp
    nvim-web-devicons
  ];
  nvim_conf = pkgs.writeText "init.lua" (builtins.readFile ./init.lua);
  nvim = pkgs.neovim.override {
    vimAlias = true;
    viAlias = true;
    extraMakeWrapperArgs = builtins.concatStringsSep " "  [
      "--append-flags \"-u ${nvim_conf}\""
      "--append-flags \"-c Layout\""
    ];
    configure.packages.myPlugins.start = nvim_plugins ++ nvim_packages ++ extra_packages;
  };
in
nvim
