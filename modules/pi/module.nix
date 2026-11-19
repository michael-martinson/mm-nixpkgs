/*
  Pi (pi.dev): the AI coding agent harness. Installs mm.pi.package (our own
  build - see ../../packages/pi for why, not upstream's flake) and ships
  every file in ./extensions/ into ~/.pi/agent/extensions/ (auto-discovered,
  verified empirically against a scratch agent dir), so adding another
  extension is just adding another file there - no change needed here.

  ./extensions/notify.ts listens for agent_settled ("done") and
  ui_prompt_start ("needs input") - confirmed against the npm package's own
  shipped .d.ts files and its official examples/extensions/notify.ts - and
  shells out to $MM_NOTIFY_COMMAND (set below): mm-notify (packages/mm-notify)
  plus this user's notification flags, as one string - a safe no-op when no
  notification backend is on.

  Standalone: set mm.pi.enable/username/notifications directly. Or let
  mm.ai.pi.enable turn this on for you, using mm.ai.username and
  mm.ai.notifications - see modules/ai.
*/
{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib) mkIf mkOption mkEnableOption mkPackageOption types;
  inherit (pkgs.myLibrary) notificationOptions mkNotifyCommand;
  cfg = config.mm.pi;

  notifyCommand = mkNotifyCommand pkgs cfg.notifications;

  extensionNames = builtins.attrNames (builtins.readDir ./extensions);
in
{
  options.mm.pi = {
    enable = mkEnableOption "Pi, the AI coding agent harness (pi.dev)";

    username = mkOption {
      description = "The user that gets Pi.";
      type = types.nonEmptyStr;
    };

    package = mkPackageOption pkgs "pi" { };

    notifications = notificationOptions { };
  };

  config = mkIf cfg.enable {
    environment.systemPackages = [ cfg.package ];

    # Read by ./extensions/*.ts. Not a secret (credentials are resolved by
    # mm-notify's own --*-command flags at call time, not baked in here) -
    # safe to set system-wide.
    environment.variables.MM_NOTIFY_COMMAND = notifyCommand;

    environment.etc = lib.listToAttrs (
      map (name: {
        name = "mm-pi/extensions/${name}";
        value.source = ./extensions/${name};
      }) extensionNames
    );

    systemd.tmpfiles.rules =
      [
        "d /home/${cfg.username}/.pi 0755 ${cfg.username} users -"
        "d /home/${cfg.username}/.pi/agent 0755 ${cfg.username} users -"
        "d /home/${cfg.username}/.pi/agent/extensions 0755 ${cfg.username} users -"
      ]
      ++ map (
        name:
        "L+ /home/${cfg.username}/.pi/agent/extensions/mm-${name} - - - - /etc/mm-pi/extensions/${name}"
      ) extensionNames;
  };
}
