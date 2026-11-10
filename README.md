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
| `modules` | Each top-level folder is also its own named output (`nixosModules.aws`, `.secrets`, `.ai`, `.user`, plus the re-exported `.homeManager`), so you can pick only what you want. `nixosModules.default` imports every `module.nix` below this folder, at any depth. A module must do nothing until it is enabled. See below for details on each. |
| `dev-shells` | A `fish` dev shell with `defaultShellPackages` and the shared fish config. |
| `legacy-packages` | `nixpkgs` with `overlays.default` applied, per system. |

### Modules

| Module | Option | Needs |
|---|---|---|
| `aws` | `mm.aws` | nothing extra |
| `secrets` | `mm.secrets` | a thin sops-nix wrapper - also import `sops-nix.nixosModules.default` |
| `ai` | `mm.ai` | nothing extra - writes the shared `./ai/AGENTS.md` to `~/.ai/AGENTS.md` via `systemd.tmpfiles`, no home-manager |
| `user` | `mm.user` | the account, fonts, fish, direnv, editor, nix-ld, and git identity for one user, named by `mm.user.username` |
| `homeManager` | - | re-exports `home-manager.nixosModules.home-manager`, so a consumer does not need its own home-manager input. Only needed if you turn on `mm.user.homeManager.enable`, which gives that user a home-manager profile (`extraConfig` merges into `home-manager.users.<username>`, for a shared home structure/packages/dotfiles) |

Any module that sets `home-manager.*` or `sops.*` (even inside `mkIf`) needs that
namespace declared somewhere in the system, regardless of whether the option
is actually enabled - so `user`/`secrets` need `homeManager`/`sops-nix` imported
too, even with `homeManager.enable`/`mm.secrets.enable` left off.

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
