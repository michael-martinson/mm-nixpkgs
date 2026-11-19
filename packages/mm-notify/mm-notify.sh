#!/usr/bin/env bash
# Sends a message/notification somewhere - Slack, Discord, email, SMS, or
# any of the 100+ services apprise supports (https://github.com/caronc/apprise#popular-notification-services),
# plus an arbitrary extra command. Generic: not specific to AI agents or
# any other caller. Config is per-invocation flags, not environment
# variables or baked-in values, so two callers can each use their own
# settings without fighting over global state.
set -euo pipefail

urls_command=""
extra_command=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --urls-command)
      urls_command="$2"
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

if [[ -n "$urls_command" ]]; then
  # shellcheck disable=SC2294
  mapfile -t urls < <(eval "$urls_command")
  if [[ ${#urls[@]} -gt 0 ]]; then
    apprise -b "$message" "${urls[@]}" || true
  fi
fi

if [[ -n "$extra_command" ]]; then
  # shellcheck disable=SC2294
  eval "$extra_command \"\$message\"" || true
fi
