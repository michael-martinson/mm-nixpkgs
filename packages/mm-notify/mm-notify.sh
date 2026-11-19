#!/usr/bin/env bash
# Notifies that an AI agent is done or needs input, via one or more
# backends. Config is per-invocation flags, not environment variables or
# baked-in values, so two callers (e.g. mm.claude and mm.pi) can each use
# their own settings without fighting over global state.
set -euo pipefail

ntfy_server="https://ntfy.sh"
ntfy_topic=""
pushover_user_key_command=""
pushover_api_token_command=""
extra_command=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --ntfy-server)
      ntfy_server="$2"
      shift 2
      ;;
    --ntfy-topic)
      ntfy_topic="$2"
      shift 2
      ;;
    --pushover-user-key-command)
      pushover_user_key_command="$2"
      shift 2
      ;;
    --pushover-api-token-command)
      pushover_api_token_command="$2"
      shift 2
      ;;
    --command)
      extra_command="$2"
      shift 2
      ;;
    --)
      shift
      break
      ;;
    *)
      break
      ;;
  esac
done

message="$1"

if [[ -n "$ntfy_topic" ]]; then
  curl -fsS -d "$message" "$ntfy_server/$ntfy_topic" >/dev/null 2>&1 || true
fi

if [[ -n "$pushover_user_key_command" && -n "$pushover_api_token_command" ]]; then
  # shellcheck disable=SC2294
  user_key=$(eval "$pushover_user_key_command")
  # shellcheck disable=SC2294
  api_token=$(eval "$pushover_api_token_command")
  curl -fsS \
    --form-string "token=$api_token" \
    --form-string "user=$user_key" \
    --form-string "message=$message" \
    https://api.pushover.net/1/messages.json >/dev/null 2>&1 || true
fi

if [[ -n "$extra_command" ]]; then
  # shellcheck disable=SC2294
  eval "$extra_command \"\$message\"" || true
fi
