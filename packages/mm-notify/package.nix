/*
  Sends a message/notification somewhere - Slack, Discord, email, SMS, or
  any of the 100+ services apprise (https://github.com/caronc/apprise)
  supports, plus an optional extra command. Generic: usable for anything
  worth notifying on, not specific to AI agents (mm.claude/mm.pi are just
  its current callers - see library/default.nix's mkNotifyCommand).

  Config (--urls-command, --command) is per-invocation flags, not
  environment variables or baked-in values - see mm-notify.sh.
*/
{
  lib,
  writeShellApplication,
  apprise,
}:
writeShellApplication {
  name = "mm-notify";
  runtimeInputs = [ apprise ];
  text = builtins.readFile ./mm-notify.sh;
  meta = {
    description = "Send a message/notification via apprise (Slack, Discord, email, SMS, ...) and/or a custom command";
    mainProgram = "mm-notify";
    license = lib.licenses.mit;
  };
}
