/*
  Notifies that an AI agent is done or needs input: ntfy, Pushover, and/or
  an arbitrary command, selected and configured via flags (see
  mm-notify.sh), not Nix-generated per caller - run `mm-notify --help`-
  style usage is just reading the script. Used by mm.claude and mm.pi
  (library/default.nix's mkNotifyCommand builds the flag string for a
  resolved `notifications` config value).
*/
{
  lib,
  writeShellApplication,
  curl,
}:
writeShellApplication {
  name = "mm-notify";
  runtimeInputs = [ curl ];
  text = builtins.readFile ./mm-notify.sh;
  meta = {
    description = "Notify that an AI agent is done or needs input";
    mainProgram = "mm-notify";
    license = lib.licenses.mit;
  };
}
