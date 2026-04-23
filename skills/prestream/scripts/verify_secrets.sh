#!/bin/bash
# Verify secrets are ready for streaming.
# Two concerns:
#   (1) Host-shell env vars listed in references/expected_env_vars.txt
#       (for workflows where you load secrets into your shell manually)
#   (2) 1Password refs listed in references/op_refs.txt
#       (for workflows that inject secrets via `op run --env-file=…`)
#
# Either list may be empty. Both empty = "nothing configured yet; phase is N/A."

set -u

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
ENV_FILE="${SCRIPT_DIR}/../references/expected_env_vars.txt"
OP_REFS_FILE="${SCRIPT_DIR}/../references/op_refs.txt"

# Strip comments and blank lines from a file. Returns "" if file missing/empty.
strip() {
  [ -f "$1" ] || return 0
  grep -v '^[[:space:]]*#' "$1" | grep -v '^[[:space:]]*$' || true
}

env_vars=$(strip "$ENV_FILE")
op_refs=$(strip "$OP_REFS_FILE")

# Nothing configured anywhere = phase N/A
if [ -z "$env_vars" ] && [ -z "$op_refs" ]; then
  echo "SECRETS: N/A — neither expected_env_vars.txt nor op_refs.txt is populated."
  echo "  When you start using API-key providers, add names to expected_env_vars.txt"
  echo "  or 1Password refs to op_refs.txt."
  exit 0
fi

echo "SECRETS:"

# ─── (1) Host env-var check ─────────────────────────────────────
if [ -n "$env_vars" ]; then
  echo "  Host env vars (from expected_env_vars.txt):"
  while IFS= read -r var; do
    [ -z "$var" ] && continue
    val=$(printenv "$var" 2>/dev/null)
    if [ -n "$val" ]; then
      echo "    ✓ $var is set"
    else
      echo "    ✗ $var is NOT set or empty"
    fi
  done <<< "$env_vars"
fi

# ─── (2) 1Password ref resolvability check ───────────────────────
if [ -n "$op_refs" ]; then
  echo "  1Password refs (from op_refs.txt):"
  if ! command -v op >/dev/null 2>&1; then
    echo "    ⚠ 'op' CLI not installed — cannot verify refs"
    echo "      install: brew install --cask 1password-cli"
  else
    while IFS= read -r ref; do
      [ -z "$ref" ] && continue
      if op read "$ref" >/dev/null 2>&1; then
        echo "    ✓ $ref"
      else
        echo "    ✗ $ref (cannot resolve — check vault, signin, or ref path)"
      fi
    done <<< "$op_refs"
  fi
fi
