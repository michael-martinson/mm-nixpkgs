import { exec } from "node:child_process";

function notify(message: string): void {
  exec(`apprise -b ${message} --tag="pi"`, () => {});
}

export default function (pi: any) {
  pi.on("agent_settled", async () => notify("Pi finished"));
  pi.on("ui_prompt_start", async () => notify("Pi needs your input"));
}
