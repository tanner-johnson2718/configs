{inputs, lib, pkgs, ...}:
let
  inherit (inputs.self.nixosConfigurations)
    gamebox0
    gitea-server-qemu0;
in
{
  imports = with inputs.self.nixosModules; [
    lockedSystem
    gitea-server
  ];

  config = {
    virtualisation.vmVariant.virtualisation = {
      graphics = false;
      cores = 1;
      diskSize = 1024;
      memorySize = 1024;
      forwardPorts = [
	 { from = "host"; host.port = 2222; guest.port = 22; }
      ];
      qemu.consoles = lib.mkForce [];
    };

    # This is a user defined attribute that defines a derivation to be exposed
    # at the flake level under this configs name. Useful for providing a quick
    # script attached to this config that can be invoked with nix run .#<sys>
    system.build.runTarget = gitea-server-qemu0.config.system.build.vm;

    lockedSystem.enable = true;
    lockedSystem.sshLoginKey = gamebox0.config.commonSystem.sshKey; 
    lockedSystem.hashedPassword = gamebox0.config.commonSystem.hashedPassword;

    gitea-server.enable = true;
    gitea-server.sshPort = 22;
    gitea-server.httpPort = 3000;
    gitea-server.domain = "localhost";

  };
  
}
