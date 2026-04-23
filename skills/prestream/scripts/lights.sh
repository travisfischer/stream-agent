#!/bin/bash
# Controls Elgato Key Lights via their local REST API (port 9123).
# Lights are discovered via mDNS/Bonjour — no cloud, no Control Center required.
#
# Usage:
#   lights.sh on [brightness] [temp_kelvin]    # override global; falls back to per-light config
#   lights.sh off
#   lights.sh status                            # query current state of each light
#   lights.sh discover                          # mDNS scan; helps populate lights.conf
#
# Env var defaults (used when a light has no per-light value):
#   LIGHTS_BRIGHTNESS  default brightness
#   LIGHTS_TEMP_K      default color temp in Kelvin
#
# Config: ../references/lights.conf
#   Format per line: <hostname> [brightness] [temp_k]
#   Per-light brightness/temp are optional — missing values fall back to env defaults.
#   Lines starting with # are comments. Blank lines ignored.
#
# Precedence for `on` values: CLI args > per-light config > env var > built-in default.

set -u

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
CONF_FILE="${SCRIPT_DIR}/../references/lights.conf"

DEFAULT_BRIGHTNESS="${LIGHTS_BRIGHTNESS:-50}"
DEFAULT_TEMP_K="${LIGHTS_TEMP_K:-5000}"

# ─── Helpers ─────────────────────────────────────────────────────

# Elgato API uses mired (= 1,000,000 / Kelvin). Valid range: 143–344.
k_to_mired() {
  local k="$1"
  local m=$((1000000 / k))
  if [ "$m" -lt 143 ]; then m=143; fi
  if [ "$m" -gt 344 ]; then m=344; fi
  echo "$m"
}

# Emit non-comment, non-blank lines from the config.
read_lines() {
  [ -f "$CONF_FILE" ] || return 1
  grep -v '^[[:space:]]*#' "$CONF_FILE" | grep -v '^[[:space:]]*$'
}

# Just the hostnames (first token on each non-comment line).
read_hosts() {
  read_lines | awk '{print $1}'
}

api_put() {
  local host="$1" json="$2"
  curl -sS --max-time 3 -X PUT \
    -H "Content-Type: application/json" \
    -d "$json" \
    "http://${host}:9123/elgato/lights" >/dev/null 2>&1
}

api_get() {
  local host="$1"
  curl -sS --max-time 3 "http://${host}:9123/elgato/lights" 2>/dev/null
}

# ─── Commands ────────────────────────────────────────────────────

cmd_on() {
  local global_brightness="${1:-}"
  local global_temp_k="${2:-}"

  local lines; lines=$(read_lines) || true
  if [ -z "${lines:-}" ]; then
    echo "  ⚠ No lights configured. Run: bash $(basename "$0") discover"
    return 0
  fi

  echo "Key Lights: turning on..."
  while IFS= read -r line; do
    [ -z "$line" ] && continue
    # Parse: hostname [brightness] [temp_k]
    local host cfg_b cfg_t
    read -r host cfg_b cfg_t <<< "$line"

    # Precedence: CLI arg > per-light config > env default
    local brightness="${global_brightness:-${cfg_b:-$DEFAULT_BRIGHTNESS}}"
    local temp_k="${global_temp_k:-${cfg_t:-$DEFAULT_TEMP_K}}"
    local temp_m; temp_m=$(k_to_mired "$temp_k")

    local json="{\"numberOfLights\":1,\"lights\":[{\"on\":1,\"brightness\":${brightness},\"temperature\":${temp_m}}]}"
    if api_put "$host" "$json"; then
      echo "  ✓ $host (${brightness}%, ${temp_k}K)"
    else
      echo "  ⚠ $host (unreachable)"
    fi
  done <<< "$lines"
}

cmd_off() {
  local hosts; hosts=$(read_hosts) || true
  if [ -z "${hosts:-}" ]; then
    echo "  ⚠ No lights configured."
    return 0
  fi
  echo "Key Lights: turning off..."
  local json='{"numberOfLights":1,"lights":[{"on":0}]}'
  while IFS= read -r host; do
    [ -z "$host" ] && continue
    if api_put "$host" "$json"; then
      echo "  ✓ $host"
    else
      echo "  ⚠ $host (unreachable)"
    fi
  done <<< "$hosts"
}

cmd_status() {
  local hosts; hosts=$(read_hosts) || true
  if [ -z "${hosts:-}" ]; then
    echo "  ⚠ No lights configured. Run: bash $(basename "$0") discover"
    return 0
  fi
  while IFS= read -r host; do
    [ -z "$host" ] && continue
    local resp; resp=$(api_get "$host")
    if [ -z "$resp" ]; then
      echo "  ⚠ $host (unreachable)"
    else
      echo "  · $host  $resp"
    fi
  done <<< "$hosts"
}

cmd_discover() {
  if ! command -v dns-sd >/dev/null 2>&1; then
    echo "dns-sd not available (macOS required)"
    return 1
  fi
  echo "Scanning for Elgato devices via mDNS (4s)..."
  local hosts
  hosts=$(timeout 4 dns-sd -Z _elg._tcp local. 2>/dev/null \
    | awk '/SRV/ {gsub(/\.$/, "", $6); print $6}' \
    | sort -u)
  if [ -z "$hosts" ]; then
    echo "No lights found. Make sure they're powered on and on the same network."
    return 1
  fi
  echo ""
  echo "Discovered:"
  while IFS= read -r host; do
    [ -z "$host" ] && continue
    echo "  • $host"
  done <<< "$hosts"
  echo ""
  echo "To use these, add the hostnames (one per line) to:"
  echo "  $CONF_FILE"
  echo ""
  echo "Per-light brightness/temp can follow the hostname, e.g.:"
  echo "  $host 65 5000"
}

# ─── Main ────────────────────────────────────────────────────────

case "${1:-help}" in
  on)       shift; cmd_on "$@" ;;
  off)      cmd_off ;;
  status)   cmd_status ;;
  discover) cmd_discover ;;
  help|--help|-h|*)
    cat <<EOF
Elgato Key Light control (local REST API, no cloud).

Usage:
  $(basename "$0") on [brightness] [temp_kelvin]   Turn on
                                                   CLI args override per-light config
  $(basename "$0") off                              Turn off all configured lights
  $(basename "$0") status                           Query current state of each
  $(basename "$0") discover                         mDNS scan; suggest hostnames

Config: $CONF_FILE
  Format per line:  <hostname> [brightness] [temp_kelvin]
  Per-light values optional; missing ones fall back to:
    LIGHTS_BRIGHTNESS (current: ${DEFAULT_BRIGHTNESS})
    LIGHTS_TEMP_K     (current: ${DEFAULT_TEMP_K})
EOF
    ;;
esac
