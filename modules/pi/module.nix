/*
  Pi (pi.dev): the AI coding agent harness. Installs mm.pi.package (our own
  build - see ../../packages/pi for why, not upstream's flake) and, when a
  notification backend is on, drops a real Pi extension into
  ~/.pi/agent/extensions/ (auto-discovered, verified empirically against a
  scratch agent dir), listening for agent_settled ("done") and
  ui_prompt_start ("needs input") - confirmed against the npm package's own
  shipped .d.ts files and its official examples/extensions/notify.ts.

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
  inherit (lib) mkIf mkMerge mkEnableOption mkOption mkPackageOption types;
  inherit (pkgs.myLibrary) notificationOptions mkNotifyScript hasScriptNotify;
  cfg = config.mm.pi;

  scriptNotifyEnabled = hasScriptNotify cfg.notifications;
  notifyScript = mkNotifyScript pkgs cfg.notifications;

  notifyExtension = ''
    import { execFile } from "node:child_process";

    function notify(message) {
      execFile(${builtins.toJSON "${notifyScript}"}, [message], () => {});
    }

    export default function (pi) {
      pi.on("agent_settled", async () => notify("Pi finished"));
      pi.on("ui_prompt_start", async () => notify("Pi needs your input"));
    }
  '';
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

  config = mkIf cfg.enable (mkMerge [
    { environment.systemPackages = [ cfg.package ]; }

    (mkIf scriptNotifyEnabled {
      environment.etc."mm-pi/notify.ts".text = notifyExtension;

      systemd.tmpfiles.rules = [
        "d /home/${cfg.username}/.pi 0755 ${cfg.username} users -"
        "d /home/${cfg.username}/.pi/agent 0755 ${cfg.username} users -"
        "d /home/${cfg.username}/.pi/agent/extensions 0755 ${cfg.username} users -"
        "L+ /home/${cfg.username}/.pi/agent/extensions/mm-pi-notify.ts - - - - /etc/mm-pi/notify.ts"
      ];
    })
  ]);
}
