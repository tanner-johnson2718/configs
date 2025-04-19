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
    dashboard
    gnome
    nvidiaPrime
    yubi
  ];

  config = {
    programs.steam = {
      enable = true;
      extraCompatPackages = with pkgs; [proton-ge-bin];
    };

    environment.systemPackages = with pkgs; [
      google-chrome
      yubioath-flutter
      qbittorrent
      freecad
      vlc
      atlauncher
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
    dashboard = {
      enable = true;
      node.enable = true;
      prometheusServer.enable = true;
      pushgateway.enable = true;
    };
    gnome.enable = true;
    nvidiaPrime.enable = true;
    yubi.enable = true;
    yubi.id = "29490434";
  };
}
