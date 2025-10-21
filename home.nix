# home.nix - configs my personal terminal and dev environment

{config, lib, pkgs, ...}:
{
  home.packages = with pkgs; [
    rust-analyzer
    (hiPrio gcc)
    nil
    ccls
    xclip
    ripgrep
    tree-sitter
    nodejs

    # Basic cmd tools
    btop
    zip
    unzip
    tree
    jq
    lsof
    tio
    fd
    git

    # Basic network tools
    wget
    nmap
    iw
    ethtool
    wireshark-cli

    # Peripheral tools
    usbutils
    pciutils
    i2c-tools

    google-chrome
  ];

  home.file = { 
    "${config.home.homeDirectory}/complete_alias" = { source = ./complete_alias;};
    "${config.home.homeDirectory}/.bash_complete" = {
      text = ''
        . ~/complete_alias
      '';
    };
    "${config.home.homeDirectory}/git-prompt.sh" = { source = ./git-prompt.sh;};
    "${config.home.homeDirectory}/.background-image" = { source = ./.background-image; };
  };

  home.sessionVariables = {
    EDITOR = "nvim";
  };

  programs.bash = {
    enable = true;
    enableCompletion = true;
    initExtra = builtins.readFile ./user-init.sh;
  };

  programs.neovim = {
    enable       = true;
    viAlias      = true;
    vimAlias   = true;
    vimdiffAlias = true;

    extraLuaConfig = builtins.readFile ./nvim-conf.lua;

    plugins = with pkgs.vimPlugins; [
      telescope-nvim
      git-blame-nvim
      nvim-treesitter.withAllGrammars
      onedark-nvim
      vim-bbye
    ];
  };

  programs.tmux = {
    enable = true;
    extraConfig = builtins.readFile ./tmux.conf;
  };

  programs.kitty = {
    enable = true;
    extraConfig = builtins.readFile ./kitty.conf;
  };
}
