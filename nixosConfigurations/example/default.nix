{inputs, ...}:
{
  imports = with inputs.self.nixosModules; [
    dashboard
  ];

  config = {
    nixpkgs.hostPlatform = "x86_64-linux";
    nixpkgs.system = "x86_64-linux";

    fileSystems."/" = {
      device = "/dev/null";
      fsType = "ext4";
    };
    boot.loader.grub.enable = false;

    dashboard.enable = true;
    dashboard.fileExporter.enable = true;
    dashboard.fileExporter.port = 6969;
    dashboard.fileExporter.files = [
	{
	  metric = "test";
	  type = "counter";
	}
    ];
  };
}
