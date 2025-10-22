#!/usr/bin/env bash
# deploy-gpt-cli.sh — Installs curl/jq and adds a robust `gpt` function to ~/.bashrc.
# Prompts for OPENAI_API_KEY if not already set. Safe to re-run.
# Written by Spencer Reiser

set -euo pipefail

# --- Ensure Debian/Ubuntu environment (apt) ---
if ! command -v apt-get >/dev/null 2>&1; then
  echo "This installer expects Debian/Ubuntu (apt-get). Aborting."
  exit 1
fi

# --- Install deps ---
echo "→ Installing dependencies (curl, jq)..."
sudo apt-get update -y >/dev/null
sudo apt-get install -y curl jq >/dev/null

BASHRC="$HOME/.bashrc"
STAMP_BEGIN="# BEGIN GPT CLI"
STAMP_END="# END GPT CLI"

# --- Backup once per run ---
BACKUP="${BASHRC}.bak.$(date +%Y%m%d%H%M%S)"
cp "$BASHRC" "$BACKUP" 2>/dev/null || true

# --- Ensure an API key exists (prompt if not) ---
ensure_api_key() {
  # If not in env, prompt (without echo); write to ~/.bashrc and export for current session.
  if [[ -z "${OPENAI_API_KEY:-}" ]]; then
    # Read from TTY to avoid piping issues
    if [[ -t 0 ]]; then
      read -r -s -p "Enter your OPENAI_API_KEY (input hidden): " KEY_INPUT
      echo
    else
      # Fallback for non-interactive shells: read from /dev/tty
      read -r -s -p "Enter your OPENAI_API_KEY (input hidden): " KEY_INPUT </dev/tty
      echo
    fi

    if [[ -z "${KEY_INPUT}" ]]; then
      echo "Error: No key entered. Aborting."
      exit 1
    fi

    # Export for current session
    export OPENAI_API_KEY="${KEY_INPUT}"
    unset KEY_INPUT

    # Persist if not already present
    if ! grep -q 'export OPENAI_API_KEY=' "$BASHRC"; then
      printf '\n# Persisted by deploy-gpt-cli.sh\nexport OPENAI_API_KEY=%q\n' "$OPENAI_API_KEY" >> "$BASHRC"
      echo "→ Persisted OPENAI_API_KEY in ~/.bashrc"
    else
      echo "→ OPENAI_API_KEY already persisted in ~/.bashrc (leaving as-is)"
    fi
  else
    # Already set in env; persist if not already saved
    if ! grep -q 'export OPENAI_API_KEY=' "$BASHRC"; then
      printf '\n# Persisted by deploy-gpt-cli.sh\nexport OPENAI_API_KEY=%q\n' "$OPENAI_API_KEY" >> "$BASHRC"
      echo "→ Persisted existing OPENAI_API_KEY from environment to ~/.bashrc"
    else
      echo "→ OPENAI_API_KEY present (env & ~/.bashrc)."
    fi
  fi
}

ensure_api_key

# --- Remove any previous block we installed ---
if grep -q "$STAMP_BEGIN" "$BASHRC" 2>/dev/null; then
  sed -i "/$STAMP_BEGIN/,/$STAMP_END/d" "$BASHRC"
fi

# --- Append fresh implementation ---
cat >> "$BASHRC" <<'EOF'
# BEGIN GPT CLI
# Usage:
#   gpt "Your prompt here"
#   echo "long text" | gpt
# Notes:
#   - Requires OPENAI_API_KEY in your environment.
#   - Override model with: export GPT_MODEL=gpt-4o
gpt () {
  # read from args or stdin
  local prompt
  if [ $# -gt 0 ]; then
    prompt="$*"
  else
    prompt="$(cat)"
  fi

  if [ -z "${OPENAI_API_KEY:-}" ]; then
    echo "Error: OPENAI_API_KEY is not set." >&2
    return 1
  fi

  # Allow override via GPT_MODEL; default to gpt-4o-mini
  local model="${GPT_MODEL:-gpt-4o-mini}"

  # Ensure jq exists
  if ! command -v jq >/dev/null 2>&1; then
    echo "Error: jq is required. Install with: sudo apt-get install -y jq" >&2
    return 1
  fi

  # Build JSON safely with jq to avoid quoting issues
  local payload
  payload="$(jq -n --arg model "$model" --arg prompt "$prompt" '{
    model: $model,
    messages: [
      {role:"system", content:"You are a concise CLI assistant."},
      {role:"user",   content:$prompt}
    ]
  }')"

  # Call OpenAI API; print assistant content or a readable error
  curl -sS -X POST "https://api.openai.com/v1/chat/completions" \
    -H "Authorization: Bearer $OPENAI_API_KEY" \
    -H "Content-Type: application/json" \
    -d "$payload" \
  | jq -r 'if .choices then (.choices[0].message.content // "") else ("API error: " + (.error.message // "unknown")) end'
}
# END GPT CLI
EOF

echo "✅ Installed. Open a new shell or run:  source ~/.bashrc"
echo
echo "Quick test:"
echo '  gpt "Say hello in one sentence"'
echo
echo "Tip: set a different model with:"
echo '  export GPT_MODEL=gpt-4o'
