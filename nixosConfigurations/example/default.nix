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
    dashboard.postExporter.enable = true;
    dashboard.postExporter.port = 6969;
    dashboard.postExporter.metrics = [
	{
	  metric = "test";
	  type = "counter";
	}
    ];
  };
}
