{inputs, lib, ...}:
{
  imports = [
    inputs.self.nixosModules.lockedSystem
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
      # qemu.consoles = lib.mkForce [];
    };

    lockedSystem.enable = true;
    lockedSystem.sshLoginKey = inputs.self.nixosConfigurations.gamebox0.config.commonSystem.sshKey; 
  };
  
}
