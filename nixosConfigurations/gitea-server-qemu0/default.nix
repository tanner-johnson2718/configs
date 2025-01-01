{inputs, ...}:
{
  imports = [
    inputs.self.nixosModules.lockedSystem
  ];

  config = {
    virtualisation = {
      graphics = false;
      cores = 1;
      diskSize = 1024;
      memorySize = 1024;
      forwardPorts = [
	 { from = "host"; host.port = 2222; guest.port = 22; }
      ];
    };

    lockedSystem.enable = true;
    lockedSystem.sshKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJB6woywk5BcJjvvlEvxaUNMaCMgqZlWSwVGOJkLg5Eq"; 
  };
  
}
