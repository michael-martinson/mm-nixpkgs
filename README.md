# mm-nixpkgs

Michael Martinson's common Nix library, overlays, and NixOS modules. Shared
by [mm-nixos-anduril](https://github.com/michael-martinson/mm-nixos-anduril)
and [my-nix](https://github.com/michael-martinson/my-nix). Nothing in here is
specific to either of those - anything machine- or employer-specific lives in
the consuming flake instead.

## Structure

```
flake.nix               inputs: nixpkgs, home-manager. Outputs below.
library/default.nix      defaultSystems, defaultShellPackages, fishShellInit,
                         modulesFromDirectoryRecursive
overlays/
  default.nix            composes every overlay file in this folder, adds
                         pkgs.myLibrary and pkgs.pi (from ../packages/pi)
  neovim.nix             LazyVim setup
packages/
  pi/                    our own pi.dev package - see its own header comment
modules/
  default.nix            exports each top-level folder as nixosModules.<name>,
                         plus nixosModules.default (everything, recursively)
  aws/module.nix         mm.aws
  secrets/module.nix     mm.secrets
  ai/
    module.nix           mm.ai - AGENTS.md distribution, plus turning on mm.claude/mm.pi
    AGENTS.md             the shared agent rules this module ships to every tool
  claude/module.nix      mm.claude - Claude Code, generic, with notifications
  pi/module.nix          mm.pi - Pi (pi.dev), with notifications
  user/module.nix        mm.user
dev-shells/default.nix    the `fish` dev shell
legacy-packages/default.nix   nixpkgs with overlays.default applied, per system
```

## Modules

| Module | Option | Needs |
|---|---|---|
| `aws` | `mm.aws` | nothing extra |
| `secrets` | `mm.secrets` | a thin sops-nix wrapper - also import `sops-nix.nixosModules.default` |
| `ai` | `mm.ai` | `mm.ai.enable` needs nothing extra; `mm.ai.claude.enable`/`mm.ai.pi.enable` need `claude`/`pi` imported too (see below) |
| `claude` | `mm.claude` | a thin, generic `programs.claude-code` wrapper with notifications - needs `homeManager` imported |
| `pi` | `mm.pi` | installs `pkgs.pi` (our own package) with notifications - nothing extra |
| `user` | `mm.user` | the account, fonts, fish, direnv, editor, nix-ld, and git identity for one user, named by `mm.user.username` |
| `homeManager` | - | re-exports `home-manager.nixosModules.home-manager`, so a consumer does not need its own home-manager input. Only needed if you turn on `mm.user.homeManager.enable`, which gives that user a home-manager profile (`extraConfig` merges into `home-manager.users.<username>`, for a shared home structure/packages/dotfiles) |

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

## AI (`mm.ai`, `mm.claude`, `mm.pi`)

Three modules. `mm.claude` and `mm.pi` are independently usable - set their
`enable`/`username`/`notifications` directly, with no dependency on `mm.ai`
at all. `mm.ai` is a convenience layer on top: it owns the shared
`AGENTS.md` distribution, and `mm.ai.claude.enable`/`mm.ai.pi.enable` just
turn on `mm.claude`/`mm.pi` for `mm.ai.username`, with `mm.ai.notifications`
passed down. Use `mm.claude`/`mm.pi` directly instead if you want a
different username or notification settings per tool.

```nix
mm.ai = {
  enable = true;        # ships ./ai/AGENTS.md to ~/.ai/AGENTS.md, then symlinks it into every
                         # agent tool's own global-instructions spot (systemd.tmpfiles, no
                         # home-manager): ~/.claude/CLAUDE.md, ~/.codex/AGENTS.md,
                         # ~/.config/opencode/AGENTS.md, ~/.pi/agent/AGENTS.md. Independent of
                         # claude.enable/pi.enable below - applies regardless of how (or whether,
                         # via this module) a given tool is actually installed.
  username = "mmartinson";

  claude.enable = true; # turns on mm.claude (below) for mm.ai.username
  pi.enable = true;      # turns on mm.pi (below) for mm.ai.username

  notifications = {      # passed down to mm.claude/mm.pi when claude.enable/pi.enable is set
    claudePush.enable = true;  # Claude's own mobile push (Claude only, needs the mobile app linked)
    ntfy = { enable = true; topic = "..."; };          # any backend(s) can combine
    pushover = { enable = true; userKeyCommand = [ "..." ]; apiTokenCommand = [ "..." ]; };
    command = "...";                                    # arbitrary shell command, run with the message as $1
  };
};
```

Because `mm.ai.claude.enable`/`mm.ai.pi.enable` set `mm.claude`/`mm.pi` as
plain config, `claude`/`pi` need to be imported alongside `ai` even if you
only ever flip `mm.ai.pi.enable` and never `mm.ai.claude.enable` (or vice
versa) - the same "the namespace must exist regardless of whether it is
enabled" rule noted above, just between this repo's own modules this time.
`nixosModules.default` already covers this; cherry-picking individual
modules does not.

The four symlink targets `mm.ai.enable` manages were confirmed by reading each
tool's own source or docs - OpenCode's `instruction-discovery.ts`/
`config/discovery.ts`, Pi's `configuration.md` - except Codex, inferred from
a confirmed string in its binary (`"Failed to read global AGENTS.md
instructions from \`"`) plus its documented `CODEX_HOME` default, not
directly observed: tracing an actual run far enough to see the exact path
it probed led to a real, unintended request to the OpenAI API, so that was
stopped short rather than pushed further for one path. OpenCode also
already checks `~/.claude/CLAUDE.md` itself, so the two can end up loading
the same short file twice - harmless.

### `mm.claude`

A plain, generic `programs.claude-code.enable = true` - no Anduril gateway,
no API key helper. A consumer with its own gateway-specific module
(`mm.anduril.claude-code` in mm-nixos-anduril) should use that instead, not
this: they both set `home-manager.users.<username>.programs.claude-code`,
and NixOS does not know how to merge two different settings definitions
that happen to collide on a key. Needs `homeManager` imported, same caveat
as above.

### `mm.pi`

Installs `pkgs.pi` - our own package (`packages/pi`), built from the npm
registry instead of upstream's flake. Upstream's flake build fetches a
model catalog from pi.dev as a fixed-output derivation; that is blocked on
at least one network this runs on (TLS reset on connect, confirmed with
plain `curl` too, not a Nix sandboxing artifact). The npm-published
package ships a prebuilt `dist/bundle/cli.js` - no network, no build step,
needed at all, and `npm install --ignore-scripts` plus the resulting binary
were both verified to actually work.

For notifications, Pi really does have a documented extension/event
system - reading its docs site, not just its README, turned up
`packages/coding-agent/docs/extensions.md` in its repo, with real event
names (`agent_settled`, `ui_prompt_start`) confirmed against the npm
package's own shipped `.d.ts` files and its official
`examples/extensions/notify.ts`. When a script backend is on, this drops a
small extension into `~/.pi/agent/extensions/`, where Pi auto-discovers
it - listening for `agent_settled` ("done") and `ui_prompt_start` ("needs
input"). Verified end to end against the real built package: the
extension loads without error (fails only at the expected "no API key"
step, since no credentials are configured in that test).

### Notifications (shared by `mm.claude`, `mm.pi`, and `mm.ai`)

The `notifications` option shape (`ntfy`/`pushover`/`command`, plus
`claudePush` on `mm.claude`/`mm.ai`) and the shell script that dispatches
them live once in `library/default.nix` (`notificationOptions`,
`mkNotifyScript`, `hasScriptNotify`), not duplicated per module. Every
backend can be turned on independently - enabling more than one fires all
of them. `pushover.userKeyCommand`/`apiTokenCommand` are commands, not
plain option values, so the credentials never land in the Nix store (the
same reasoning as [secrets](#secrets-mmsecrets) below, and the same
pattern as `mm.anduril.ai.bearerCommand` in mm-nixos-anduril). `ntfy.topic`
is plain text by design - ntfy's own security model treats an unguessable
topic name as the secret, not something to wrap in a command.

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

## Why not Determinate Nix

[Determinate Nix](https://github.com/DeterminateSystems/determinate) was
briefly re-exported here the same way as `homeManager`, then removed. The
module itself (replacing the `nix` package with `determinate-nixd`) is
generic enough, but it is not separable from Determinate's own curated,
weekly-tested nixpkgs pin, which is what most of its value actually is -
[mm-nixos-anduril](https://github.com/michael-martinson/mm-nixos-anduril#why-determinate-nix)
rides on exactly that pin, via `nixpkgs.follows = "determinate/nixpkgs"` on
its own `determinate` input. Re-exporting just the module here, on this
repo's own plain `nixpkgs`, strips that pin away; a consumer using the
re-export would get Determinate's daemon on a nixpkgs revision Determinate
never tested it against. Switching mm-nixos-anduril over to the re-export
to deduplicate the input proved this isn't theoretical: it broke a real
package build (`teleport`, a Go unicode-table version mismatch) that
plain, floating `nixos-unstable` HEAD has today and Determinate's pin does
not. If a consumer wants Determinate, it should keep its own `determinate`
input, for the nixpkgs pin as much as the module.

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
