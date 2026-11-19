/*
  Claude Code, generically, via home-manager: no gateway, no API key
  wiring. A consumer with its own gateway-specific module (mm.anduril.claude-code
  in mm-nixos-anduril) should use that instead, not this - do not enable
  both, they both set home-manager.users.<username>.programs.claude-code.

  Needs home-manager declared in the system (for example
  inputs.mm-nixpkgs.nixosModules.homeManager) even when mm.claude.enable
  stays off - the same way mm.secrets needs sops-nix declared.

  Standalone: set mm.claude.enable/username/notifications directly. Or let
  mm.ai.claude.enable turn this on for you, using mm.ai.username and
  mm.ai.notifications - see modules/ai.
*/
{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib) mkIf mkOption mkEnableOption types;
  inherit (pkgs.myLibrary) notificationOptions mkNotifyScript hasScriptNotify;
  cfg = config.mm.claude;

  scriptNotifyEnabled = hasScriptNotify cfg.notifications;
  notifyScript = mkNotifyScript pkgs cfg.notifications;
in
{
  options.mm.claude = {
    enable = mkEnableOption "Claude Code, generically, via home-manager (no gateway/API key wiring)";

    username = mkOption {
      description = "The user that gets Claude Code.";
      type = types.nonEmptyStr;
    };

    notifications = notificationOptions { withClaudePush = true; };
  };

  config = mkIf cfg.enable {
    home-manager.users.${cfg.username}.programs.claude-code = {
      enable = true;
      settings = lib.recursiveUpdate (lib.optionalAttrs cfg.notifications.claudePush.enable {
        inputNeededNotifEnabled = true;
      }) (lib.optionalAttrs scriptNotifyEnabled {
        hooks.Notification = [
          { hooks = [ { type = "command"; command = ''${notifyScript} "Claude needs your input" >/dev/null 2>&1 || true''; } ]; }
        ];
        hooks.Stop = [
          { hooks = [ { type = "command"; command = ''${notifyScript} "Claude finished" >/dev/null 2>&1 || true''; } ]; }
        ];
      });
    };
  };
}
