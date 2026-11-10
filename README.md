# mm-nixpkgs

Michael Martinson's common Nix library, overlays, and NixOS modules. Shared
by [mm-nixos-anduril](https://github.com/michael-martinson/mm-nixos-anduril)
and [my-nix](https://github.com/michael-martinson/my-nix). Nothing in here is
specific to either of those - anything machine- or employer-specific lives in
the consuming flake instead.

## What's here

| Path | What it is |
|---|---|
| `library` | `defaultSystems`, `defaultShellPackages`, `fishShellInit`, and `modulesFromDirectoryRecursive`. |
| `overlays` | `overlays.default` composes every overlay file in this folder (currently just `neovim.nix`, a LazyVim setup) and adds `pkgs.myLibrary`. |
| `modules` | Each top-level folder is also its own named output (`nixosModules.aws`, `.secrets`, `.ai`), so you can pick only what you want. `nixosModules.default` imports every `module.nix` below this folder, at any depth. Currently `aws` (`mm.aws`), `secrets` (`mm.secrets`, a thin sops-nix wrapper - needs `sops-nix.nixosModules.default` imported too), and `ai` (`mm.ai`, writes the shared `AGENTS.md` here to `~/.ai/AGENTS.md`). A module must do nothing until it is enabled. |
| `dev-shells` | A `fish` dev shell with `defaultShellPackages` and the shared fish config. |
| `legacy-packages` | `nixpkgs` with `overlays.default` applied, per system. |

## Using it from another flake

```nix
mm-nixpkgs.url = "github:michael-martinson/mm-nixpkgs";
mm-nixpkgs.inputs.nixpkgs.follows = "nixpkgs";
```

Then reuse what's common and layer your own local overlays/modules on top:

```nix
nixosModules = [ inputs.mm-nixpkgs.nixosModules.default inputs.self.nixosModules.default ];
overlays = [ inputs.mm-nixpkgs.overlays.default inputs.self.overlays.default ];
devShells = inputs.mm-nixpkgs.devShells;
library = inputs.mm-nixpkgs.library;
```
