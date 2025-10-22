GPT CLI (Debian/Ubuntu)

A tiny, repo-friendly installer that adds a gpt command to your shell (~/.bashrc) so you can chat with OpenAI straight from the terminal. If OPENAI_API_KEY isn’t set, the installer will prompt for it and persist it to ~/.bashrc.

This repo contains a single script: deploy-gpt-cli.sh.
It’s idempotent and safe to re-run.

Features

Zero-config install on Debian/Ubuntu (apt-get)

Prompts & saves OPENAI_API_KEY if missing

Works with args or piped stdin

Override model via GPT_MODEL (defaults to gpt-4o-mini)

Clear error messages from the API (not just null)

Quickstart
# 1) Clone this repo
git clone https://www.github.com/Sonni4154/gpt-cli.git gpt-cli && cd gpt-cli

# 2) Make the installer executable
chmod +x deploy-gpt-cli.sh

# 3) Run it (will prompt for your API key if not set)
./deploy-gpt-cli.sh

# 4) Load changes (or open a new shell)
source ~/.bashrc


Test it:

gpt "Say hello in one sentence"

Usage
# Simple prompt
gpt "Outline a deployment checklist"

# Pipe long input
cat README.md | gpt "Summarize in 5 bullets"

# Choose a different model for this shell
export GPT_MODEL=gpt-4o
gpt "Give me 3 ideas for improving DX"

What gets installed?

The script appends a gpt() bash function to ~/.bashrc:

Reads the prompt from CLI args or stdin

Constructs a safe JSON payload with jq

Calls https://api.openai.com/v1/chat/completions

Prints assistant output or a readable API error

It also:

Installs curl and jq via apt-get

Prompts for OPENAI_API_KEY (if not set) and persists it to ~/.bashrc

Requirements

Debian/Ubuntu with apt-get

bash, curl, jq

An OpenAI API key

Already have your key? You can pre-set it:

export OPENAI_API_KEY="sk-..."

Troubleshooting

“API error: …”
Key may be invalid or rate-limited. Re-set it:

sed -n '/OPENAI_API_KEY/p' ~/.bashrc   # confirm saved value
export OPENAI_API_KEY="sk-..."         # override in current shell


“Error: jq is required”
Install it:

sudo apt-get update && sudo apt-get install -y jq


Nothing prints / “null”
Reload your profile to pick up the latest function block:

source ~/.bashrc

Security Notes

Your API key is written to ~/.bashrc (user scope). Treat it like a password.

On shared servers, consider storing the key in a separate file with 600 permissions and sourcing it from ~/.bashrc.

Uninstall
# Remove the GPT CLI block from ~/.bashrc
sed -i '/# BEGIN GPT CLI/,/# END GPT CLI/d' ~/.bashrc

# (Optional) Remove any persisted key line
sed -i '/export OPENAI_API_KEY=/d' ~/.bashrc

# Reload
source ~/.bashrc

Contributing

Open an issue or PR with a clear description.

Keep the installer idempotent and Debian/Ubuntu-friendly.

Avoid adding heavyweight dependencies.

License

MIT — see LICENSE.

Contact

Spencer Reiser — spencermreiser@gmail.com
