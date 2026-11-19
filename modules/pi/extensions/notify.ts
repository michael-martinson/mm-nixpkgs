/*
 * Notifies when Pi is done (agent_settled) or waiting on a blocking
 * extension UI prompt (ui_prompt_start). Mirrors Pi's own official
 * examples/extensions/notify.ts, but shells out to mm-notify
 * (packages/mm-notify: ntfy/Pushover/a custom command) instead of a
 * terminal escape sequence.
 *
 * MM_NOTIFY_COMMAND is set system-wide (environment.variables) by
 * ../module.nix whenever mm.pi is enabled - the mm-notify binary plus this
 * user's notification flags, as one string. Run with the shell (not
 * execFile, which expects a single binary path) since it is a full command
 * line. This file stays a plain, static extension either way - no Nix
 * templating needed to add more like it here.
 */
import { exec } from "node:child_process";

function notify(message: string): void {
  const command = process.env.MM_NOTIFY_COMMAND;
  if (!command) return;
  exec(`${command} ${JSON.stringify(message)}`, () => {});
}

export default function (pi: any) {
  pi.on("agent_settled", async () => notify("Pi finished"));
  pi.on("ui_prompt_start", async () => notify("Pi needs your input"));
}
