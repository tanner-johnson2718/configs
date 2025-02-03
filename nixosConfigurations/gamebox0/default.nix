{pkgs, inputs, ...}:
let
  sysID = "gamebox0";
  publicSshKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJB6woywk5BcJjvvlEvxaUNMaCMgqZlWSwVGOJkLg5Eq gamebox0@gamebox0"; 
  hashedPassword = "$y$j9T$IBmfxiN89ruEnbsSZEdVY/$KfBV6TLSYhuPo6Q/JLEMJZMhi5yjJUPUA/3KTz8rdmD";
in
{
  imports = with inputs.self.nixosModules; [
    asus-gu603
    commonSystem
    gnome
    nvidiaPrime
    yubi
  ];

  config = {
    # This is a user defined attribute that defines a derivation to be exposed
    # at the flake level under this configs name. Useful for providing a quick
    # script attached to this config that can be invoked with nix run .#<sys>
    system.build.runTarget = pkgs.writeScriptBin "gamebox0-run" ''
      sudo nixos-rebuild --flake .#${sysID} switch
    '';

    nixpkgs.hostPlatform = "x86_64-linux";

    programs.steam = {
      enable = true;
      extraCompatPackages = with pkgs; [proton-ge-bin];
    };

    environment.systemPackages = with pkgs; [
      discord
      prusa-slicer
      google-chrome
      yubioath-flutter
      wireshark
      qbittorrent
      drawio
      freecad
    ];
    
    asus-gu603.enable = true;
    commonSystem.enable = true;
    commonSystem.userName = sysID;
    commonSystem.sshKey = publicSshKey;
    commonSystem.hashedPassword = hashedPassword;
    commonSystem.home-manager-enable = true;
    commonSystem.home-manager-config =
      ({inputs, ...}: {
	imports = with inputs.self.homeModules; [
	  bash
	  git
	  nvim
	  tmux
	];
	bash.enable = true;
        git.enable = true;
        git.email = "tanner.johnson2718@gmail.com";
        git.userName = sysID;
        nvim.enable = true;
        tmux.enable = true;
      });
    gnome.enable = true;
    nvidiaPrime.enable = true;
    yubi.enable = true;
    yubi.id = "29490434";
  };
}
