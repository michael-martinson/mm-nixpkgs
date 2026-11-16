# mm-nixpkgs

Michael Martinson's common Nix library, overlays, and NixOS modules. Shared
by [mm-nixos-anduril](https://github.com/michael-martinson/mm-nixos-anduril)
and [my-nix](https://github.com/michael-martinson/my-nix). Nothing in here is
specific to either of those - anything machine- or employer-specific lives in
the consuming flake instead.

## Structure

```
flake.nix               inputs: nixpkgs, home-manager, determinate. Outputs below.
library/default.nix      defaultSystems, defaultShellPackages, fishShellInit,
                         modulesFromDirectoryRecursive
overlays/
  default.nix            composes every overlay file in this folder, adds pkgs.myLibrary
  neovim.nix             LazyVim setup
modules/
  default.nix            exports each top-level folder as nixosModules.<name>,
                         plus nixosModules.default (everything, recursively)
  aws/module.nix         mm.aws
  secrets/module.nix     mm.secrets
  ai/
    module.nix           mm.ai
    AGENTS.md             the shared agent rules this module ships to ~/.ai/AGENTS.md
  user/module.nix        mm.user
dev-shells/default.nix    the `fish` dev shell
legacy-packages/default.nix   nixpkgs with overlays.default applied, per system
```

## Modules

| Module | Option | Needs |
|---|---|---|
| `aws` | `mm.aws` | nothing extra |
| `secrets` | `mm.secrets` | a thin sops-nix wrapper - also import `sops-nix.nixosModules.default` |
| `ai` | `mm.ai` | nothing extra - writes `./ai/AGENTS.md` to `~/.ai/AGENTS.md` via `systemd.tmpfiles`, no home-manager |
| `user` | `mm.user` | the account, fonts, fish, direnv, editor, nix-ld, and git identity for one user, named by `mm.user.username` |
| `homeManager` | - | re-exports `home-manager.nixosModules.home-manager`, so a consumer does not need its own home-manager input. Only needed if you turn on `mm.user.homeManager.enable`, which gives that user a home-manager profile (`extraConfig` merges into `home-manager.users.<username>`, for a shared home structure/packages/dotfiles) |
| `determinate` | - | re-exports `determinate.nixosModules.default` ([DeterminateSystems/determinate](https://github.com/DeterminateSystems/determinate)), so a consumer does not need its own input. Nothing here turns it on - import it and set `determinate.enable = true` (the module's own default) if you want it |

Any module that sets `home-manager.*` or `sops.*` (even inside `mkIf`) needs that
namespace declared somewhere in the system, regardless of whether the option
is actually enabled - so `user`/`secrets` need `homeManager`/`sops-nix` imported
too, even with `homeManager.enable`/`mm.secrets.enable` left off.

## Secrets (`mm.secrets`)

This module holds no secrets of its own - it is a generic sops-nix wrapper
that any consumer points at its own encrypted file:

```nix
mm.secrets = {
  enable = true;
  sops-file = ../secrets/secrets.yaml;  # the consumer's own encrypted file
};
```

It sets `sops.defaultSopsFile` to that file and `sops.age.sshKeyPaths` to the
machine's own SSH host key (`/etc/ssh/ssh_host_ed25519_key`), which is how
sops-nix decrypts at boot. Other modules in the consumer's own repo then
declare `sops.secrets.<name> = {}` (or `sops.templates.<name> = {...}`) and
sops-nix fills them in from that file.

Needs `services.openssh.enable = true` (for the host key to exist) and
`sops-nix.nixosModules.default` imported into the system. See
[mm-nixos-anduril's README](https://github.com/michael-martinson/mm-nixos-anduril#secrets)
for a full worked example: encrypting a file, adding a machine's age key,
and turning on a token.

## home-manager (`homeManager`)

[home-manager](https://github.com/nix-community/home-manager) manages the
files in one user's home directory - dotfiles, `~/.config/*`, a per-user
package set - declaratively, the same way NixOS manages `/etc` and
`/nix/var`. NixOS options are for the whole machine; some things are
inherently per-user instead (an AI tool's settings file, your shell config,
packages you want but do not want to pollute `environment.systemPackages`
with). home-manager is the standard way to manage those from the same Nix
language and toolchain, with its own generations and rollback.

`mm.user.homeManager` is this module's own use of it: enable it on a `mm.user`
entry and that user gets a home-manager profile (`extraConfig` merges into
`home-manager.users.<username>`) alongside their system account, instead of
you wiring home-manager up yourself. If you do not need per-user files or
packages beyond what `mm.user` already gives you (the system account, fonts,
fish, git identity), you do not need this at all.

## Determinate Nix (`determinate`)

[Determinate Nix](https://github.com/DeterminateSystems/determinate) is
DeterminateSystems' Nix distribution: it replaces the `nix` package with
their build (run through `determinate-nixd`), and gives NixOS a module that
manages `/etc/nix/nix.custom.conf` for you. The appeal is a more polished,
actively maintained install than some of the rough edges in the stock
multi-user Nix installer and daemon, plus their FlakeHub-backed extras
(pinned nixpkgs releases, a flake registry). The cost is a vendored daemon
and installer you are trusting instead of upstream Nix - plain Nix works
fine, and some people prefer not to add that dependency.

Some organizations standardize on it and require it for working with their
infrastructure - that is a machine- or employer-specific reason to turn it
on, which is why it lives here only as an available-but-unused re-export, not
something any `mm.*` module turns on for you. See
[mm-nixos-anduril's README](https://github.com/michael-martinson/mm-nixos-anduril#why-determinate-nix)
for a concrete case of why a consumer might require it.

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
