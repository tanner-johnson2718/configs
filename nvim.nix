let
  pkgs = import ./nixpkgs_pin.nix;
  nvim_plugins = with pkgs.vimPlugins; [
    telescope-nvim
    git-blame-nvim
    nvim-treesitter.withAllGrammars
    onedark-nvim
    vim-bbye
    blink-cmp
    rustaceanvim
    plenary-nvim
    nvim-lspconfig
  ];
  nvim_conf = pkgs.writeText "init.lua" (builtins.readFile ./init.lua);
  nvim = pkgs.neovim.override {
    vimAlias = true;
    viAlias = true;
    extraMakeWrapperArgs = builtins.concatStringsSep " "  [
      "--append-flags \"-u ${nvim_conf}\""
      "--append-flags \"-c Layout\""
    ];
    configure.packages.myPlugins.start = nvim_plugins;
  };
in
nvim
