let
  inherit (builtins) readDir attrNames;
in
{

  # For a given dir, import each subdir into a set whose name is the dir name
  # and whose value is the import of that dir.
  dir2Set = lib: dir: 
    (lib.genAttrs
      (attrNames (readDir dir))
      (name: import (lib.path.append dir name)) 
    );

  # For a given dir, import each subdir into a set whose name is the dir name
  # and whose value is the import of that dir + evaluate the import with the
  # given args.
  dir2Set' = lib: args: dir: 
    (lib.genAttrs
      (attrNames (readDir dir))
      (name: (import (lib.path.append dir name) args)) 
    );

  # TODO For now we are assuming all systems are x86. Dont do that.
  # For a given dir, import each subdir and create an attr set where the key
  # is the dir name and the value is a nixos system. Each sub dir is expected
  # to contain a single (top level) module that defines the system.
  dir2ConfigsSet = lib: inputs: dir:
    (lib.genAttrs
      (attrNames (readDir dir))
      (name: lib.nixosSystem {
	system = "x86_64-linux";
	specialArgs = { inherit inputs; };
	modules = [ 
	  (import (lib.path.append dir name)) 
	];
      })
    );
}
