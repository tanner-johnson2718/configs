# Env

Monorepo to contain source and build/deploy infra for all my personal projects.


# Directory Structure

| Dir | Explaination |
| --- | ------------ |
| `cLibs`               | General purpose C libraries (usually data structures or misc code projects) |
| `devShells`           | Modular shell envs: `nix develop .#<shell>` |
| `docs`                | MkDocs base base dir |
| `esp32Modules`        | Self contained esp32 modules that can be composed to make systems. |
| `esp32Systems`        | Systems our projects that are flashed to a singular esp32. |
| `helpers`             | Nix helper functions so I don't have to fully learn Nix. |
| `homeModules`         | Home manage modules to imported from a `home.nix`. |
| `nixosConfigurations` | NixOS modules that define a system. |
| `nixosModules`        | Nixos modules to be composed and imported but a NixOS configuration. |
| `packages`            | Packages applications: `nix build .#<pkg>` |
