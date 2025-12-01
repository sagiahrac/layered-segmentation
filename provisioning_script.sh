#!/bin/bash
set -eo pipefail

# --- 1. Install Zsh and Dependencies ---
apt-get update
apt-get install -y zsh git curl nano jq # <-- Added jq here

# --- 2. Install Oh My Zsh ---
sh -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended

# Optional: Set Zsh as default shell (requires re-login)
chsh -s $(which zsh)

# --- 3. Configure VS Code Terminal ---
# Define the target path (ensure it's correct for your user, usually /root)
VSCODE_SETTINGS_PATH="/root/.vscode-server/data/Machine/settings.json"
VSCODE_SETTINGS_DIR=$(dirname "$VSCODE_SETTINGS_PATH")

# Create the directory if it doesn't exist
mkdir -p "$VSCODE_SETTINGS_DIR"

# Ensure the settings file exists (if not, create it with a basic structure)
if [ ! -f "$VSCODE_SETTINGS_PATH" ]; then
    echo "{}" > "$VSCODE_SETTINGS_PATH"
fi

# Define the JSON configuration fragment
# NOTE: The keys must be merged into the existing settings object, not the whole block.
# We are only defining the keys we need to add/update.
VSCODE_CONFIG_FRAGMENT='
{
    "terminal.integrated.profiles.linux": {
        "zsh_new_process": {
            "path": "/bin/zsh", 
            "args": ["-l", "-i"] 
        }
    },
    "terminal.integrated.defaultProfile.linux": "zsh_new_process"
}
'

# Use jq to merge the fragment into the existing settings.json file
# Note: The 'input' here is the existing file content, and the 'update' 
# is the fragment defined above. jq handles the merging cleanly.
echo "$VSCODE_CONFIG_FRAGMENT" | jq -s '.[0] * .[1]' "$VSCODE_SETTINGS_PATH" - > temp.json && mv temp.json "$VSCODE_SETTINGS_PATH"


echo "Zsh and VS Code settings configured successfully!"

# Cleanup packages (optional)
# rm -rf /var/lib/apt/lists/*